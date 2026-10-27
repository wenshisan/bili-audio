import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/logging/app_logger.dart';
import '../../data/player/bili_audio_handler.dart';
import 'app_quit.dart';
import 'desktop_controls.dart';
import 'windows_taskbar_host.dart';

const desktopShellChannel = MethodChannel('bili_audio/desktop_shell');

BiliAudioHandler? _handler;
var _listening = false;
var _chromeKey = '';
var _progressAt = DateTime.fromMillisecondsSinceEpoch(0);
var _lastProgressMs = -1;
var _tail = Future<void>.value();
final _subscriptions = <StreamSubscription<Object?>>[];

/// 托盘、关闭收进托盘，以及还没有曲目时的空菜单。
Future<void> initDesktopShell() async {
  desktopShellChannel.setMethodCallHandler(_onShellCall);
  try {
    await windowManager.setPreventClose(true);
    windowManager.addListener(_HideOnClose());
  } catch (error, stack) {
    AppLogger.e(
      'prevent close failed',
      tag: 'boot',
      error: error,
      stackTrace: stack,
    );
  }
  try {
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );
    await trayManager.setToolTip(DesktopControlLabels.zh.appName);
    trayManager.addListener(_TrayPointer());
    await _enqueue(
      () => _applyAll(const DesktopTrackSnapshot(), forceProgress: true),
    );
  } catch (error, stack) {
    AppLogger.e(
      'system tray init failed',
      tag: 'boot',
      error: error,
      stackTrace: stack,
    );
  }
}

/// 播放状态变化时刷新托盘、窗口标题、Windows 任务栏和 macOS 程序坞。
Future<void> attachDesktopPlayback(BiliAudioHandler handler) async {
  if (_listening) return;
  _listening = true;
  _handler = handler;
  _subscriptions.add(
    handler.mediaItem.listen((_) {
      unawaited(_enqueue(() => _applyAll(_snapshot(), forceProgress: true)));
    }),
  );
  _subscriptions.add(
    handler.playbackState.listen((_) {
      unawaited(_enqueue(() => _applyAll(_snapshot(), forceProgress: false)));
    }),
  );
  if (Platform.isWindows) {
    _subscriptions.add(
      handler.engine.positionStream.listen((_) {
        unawaited(_enqueue(() => _applyProgress(_snapshot(), force: false)));
      }),
    );
  }
}

Future<void> showDesktopWindow() async {
  final minimized = await windowManager.isMinimized();
  await windowManager.show();
  if (minimized) await windowManager.restore();
  await windowManager.focus();
}

Future<void> toggleDesktopWindow() async {
  final visible = await windowManager.isVisible();
  final minimized = await windowManager.isMinimized();
  if (visible && !minimized) {
    await windowManager.hide();
    return;
  }
  await showDesktopWindow();
}

Future<void> _onShellCall(MethodCall call) async {
  switch (call.method) {
    case 'showWindow':
      await showDesktopWindow();
    case 'onCommand':
      final id = call.arguments;
      if (id is! String) return;
      final command = commandById(id);
      if (command != null) await _run(command);
    default:
  }
}

Future<void> _run(DesktopCommand command) async {
  switch (command) {
    case DesktopCommand.togglePlay:
    case DesktopCommand.previous:
    case DesktopCommand.next:
      final handler = _handler;
      if (handler != null) applyPlaybackCommand(handler, command);
    case DesktopCommand.showWindow:
      await showDesktopWindow();
    case DesktopCommand.hideWindow:
      await windowManager.hide();
    case DesktopCommand.quit:
      await quitDesktopApp();
  }
}

DesktopTrackSnapshot _snapshot() {
  final handler = _handler;
  if (handler == null) return const DesktopTrackSnapshot();
  final items = handler.mediaItem;
  final item = items.hasValue ? items.value : null;
  final state = handler.playbackState;
  final playing = state.hasValue && state.value.playing;
  return DesktopTrackSnapshot(
    title: item?.title,
    artist: item?.artist,
    playing: playing,
    position: handler.engine.position,
    duration: item?.duration ?? handler.engine.duration ?? Duration.zero,
  );
}

Future<void> _enqueue(Future<void> Function() job) {
  _tail = _tail.then((_) async {
    try {
      await job();
    } catch (error, stack) {
      AppLogger.e(
        'desktop shell update failed',
        tag: 'window',
        error: error,
        stackTrace: stack,
      );
    }
  });
  return _tail;
}

Future<void> _applyAll(
  DesktopTrackSnapshot snap, {
  required bool forceProgress,
}) async {
  final key = playbackChromeKey(snap);
  final changed = key != _chromeKey;
  if (changed) {
    _chromeKey = key;
    await _applyChrome(snap);
  }
  await _applyProgress(snap, force: forceProgress || changed);
}

Future<void> _applyChrome(DesktopTrackSnapshot snap) async {
  final labels = DesktopControlLabels.zh;
  await trayManager.setContextMenu(
    Menu(
      items: [
        for (final entry in trayMenuEntries(snap, labels))
          if (entry.separator)
            MenuItem.separator()
          else
            MenuItem(
              key: entry.command?.id ?? 'now-playing',
              label: entry.label,
              disabled: !entry.enabled,
              onClick: entry.command == null
                  ? null
                  : (_) => unawaited(_run(entry.command!)),
            ),
      ],
    ),
  );
  await trayManager.setToolTip(playbackTooltip(snap, labels.appName));
  await windowManager.setTitle(playbackWindowTitle(snap, labels.appName));
  if (Platform.isMacOS) {
    await trayManager.setTitle(menuBarTitle(snap));
    await desktopShellChannel.invokeMethod<void>(
      'setDockMenu',
      dockMenuPayload(snap, labels),
    );
  }
  if (Platform.isWindows && await windowManager.isVisible()) {
    await syncWindowsTaskbarChrome(snap, labels, (command) {
      unawaited(_run(command));
    });
  }
}

Future<void> _applyProgress(
  DesktopTrackSnapshot snap, {
  required bool force,
}) async {
  if (!Platform.isWindows) return;
  final progress = taskbarProgress(snap);
  final completed = progress?.completed ?? -1;
  final now = DateTime.now();
  final jumped = (completed - _lastProgressMs).abs() > 2000;
  if (!force &&
      !jumped &&
      now.difference(_progressAt) < const Duration(seconds: 1)) {
    return;
  }
  _progressAt = now;
  _lastProgressMs = completed;
  if (!await windowManager.isVisible()) return;
  await syncWindowsTaskbarProgress(snap);
}

class _HideOnClose with WindowListener {
  @override
  void onWindowClose() {
    unawaited(windowManager.hide());
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName != 'show') return;
    unawaited(_enqueue(() => _applyAll(_snapshot(), forceProgress: true)));
  }
}

class _TrayPointer with TrayListener {
  var _openingMenu = false;

  @override
  void onTrayIconMouseDown() {
    if (Platform.isMacOS) {
      _popMenu();
      return;
    }
    unawaited(toggleDesktopWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    _popMenu();
  }

  void _popMenu() {
    if (_openingMenu) return;
    _openingMenu = true;
    unawaited(
      trayManager.popUpContextMenu().whenComplete(() => _openingMenu = false),
    );
  }
}
