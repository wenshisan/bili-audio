import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:smtc_windows/smtc_windows.dart';

import '../../core/logging/app_logger.dart';
import '../../data/player/bili_audio_handler.dart';

/// SMTC 是否已成功初始化; 失败时 [WindowsMediaBridge] 不应创建。
bool smtcAvailable = false;

/// 桌面平台初始化 (M4.2/M4.3)
///
/// Windows: media_kit + SMTC 媒体控制
/// Linux: media_kit, MPRIS 延后 (dbus 版本冲突)
Future<void> initDesktopPlatform() async {
  if (Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(windows: true);
    // SMTC 依赖 native DLL; 初始化失败时降级, 不阻断启动
    try {
      await SMTCWindows.initialize();
      smtcAvailable = true;
    } catch (e, st) {
      AppLogger.e(
        'SMTCWindows.initialize failed',
        tag: 'boot',
        error: e,
        stackTrace: st,
      );
    }
  } else if (Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(linux: true);
  }
}

/// Windows SMTC 桥接 (M4.3)
///
/// 监听 [BiliAudioHandler] 状态并同步到 Windows 任务栏/媒体键控制。
class WindowsMediaBridge {
  WindowsMediaBridge(this.handler) {
    _smtc = SMTCWindows(
      config: const SMTCConfig(
        playEnabled: true,
        pauseEnabled: true,
        nextEnabled: true,
        prevEnabled: true,
        stopEnabled: false,
        fastForwardEnabled: false,
        rewindEnabled: false,
      ),
    );
    _subs.add(handler.playbackState.listen(_syncPlayback));
    _subs.add(handler.mediaItem.listen(_syncMetadata));
    _subs.add(_smtc.buttonPressStream.listen(_onButton));
  }

  final BiliAudioHandler handler;
  late final SMTCWindows _smtc;
  final _subs = <StreamSubscription<Object?>>[];

  void _syncPlayback(PlaybackState state) {
    final status = state.playing
        ? PlaybackStatus.playing
        : PlaybackStatus.paused;
    unawaited(_smtc.setPlaybackStatus(status));
    final dur = handler.engine.duration;
    if (dur != null && dur > Duration.zero) {
      unawaited(
        _smtc.updateTimeline(
          PlaybackTimeline(
            startTimeMs: 0,
            endTimeMs: dur.inMilliseconds,
            positionMs: state.position.inMilliseconds,
          ),
        ),
      );
    }
  }

  void _syncMetadata(MediaItem? item) {
    if (item == null) return;
    unawaited(_updateMetadata(item));
  }

  Future<void> _updateMetadata(MediaItem item) async {
    final art = item.artUri;
    final thumbnail = art != null && art.hasScheme && art.host.isNotEmpty
        ? art.toString()
        : null;
    try {
      await _smtc.updateMetadata(
        MusicMetadata(
          title: item.title,
          artist: item.artist ?? '',
          album: item.album,
          thumbnail: thumbnail,
        ),
      );
    } catch (e, st) {
      AppLogger.e(
        'SMTC metadata update failed',
        tag: 'player',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _onButton(PressedButton button) {
    switch (button) {
      case PressedButton.play:
        unawaited(handler.play());
      case PressedButton.pause:
        unawaited(handler.pause());
      case PressedButton.next:
        unawaited(handler.skipToNext());
      case PressedButton.previous:
        unawaited(handler.skipToPrevious());
      default:
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _smtc.dispose();
  }
}
