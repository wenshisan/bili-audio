import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:windows_taskbar/windows_taskbar.dart';

import '../../core/logging/app_logger.dart';
import 'desktop_controls.dart';

bool _missingIconsLogged = false;
bool _progressFailed = false;

bool _taskbarIconsReady() {
  final file = File(
    path.join(
      path.dirname(Platform.resolvedExecutable),
      'data',
      'flutter_assets',
      'assets',
      'taskbar',
      'play.ico',
    ),
  );
  if (file.existsSync()) return true;
  if (!_missingIconsLogged) {
    _missingIconsLogged = true;
    AppLogger.w('taskbar icons missing ${file.path}', tag: 'window');
  }
  return false;
}

/// 悬停任务栏图标时的上一首 / 播放 / 下一首，以及预览提示。
Future<void> syncWindowsTaskbarChrome(
  DesktopTrackSnapshot snap,
  DesktopControlLabels labels,
  void Function(DesktopCommand command) onCommand,
) async {
  if (!Platform.isWindows) return;
  try {
    await WindowsTaskbar.setThumbnailTooltip(
      playbackTooltip(snap, labels.appName),
    );
  } catch (error, stack) {
    AppLogger.e(
      'taskbar tooltip failed',
      tag: 'window',
      error: error,
      stackTrace: stack,
    );
  }
  if (!_taskbarIconsReady()) return;
  // 不带 noBackground，系统才会画悬停和按下。图标本身透明，按钮底色由系统画。
  final mode = snap.hasTrack ? 0 : ThumbnailToolbarButtonMode.disabled;
  final playIcon = snap.playing
      ? 'assets/taskbar/pause.ico'
      : 'assets/taskbar/play.ico';
  try {
    await WindowsTaskbar.setThumbnailToolbar([
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/taskbar/previous.ico'),
        labels.previous,
        () => onCommand(DesktopCommand.previous),
        mode: mode,
      ),
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon(playIcon),
        labels.playingLabel(snap.playing),
        () => onCommand(DesktopCommand.togglePlay),
        mode: mode,
      ),
      ThumbnailToolbarButton(
        ThumbnailToolbarAssetIcon('assets/taskbar/next.ico'),
        labels.next,
        () => onCommand(DesktopCommand.next),
        mode: mode,
      ),
    ]);
  } catch (error, stack) {
    AppLogger.e(
      'taskbar buttons failed',
      tag: 'window',
      error: error,
      stackTrace: stack,
    );
  }
}

/// 任务栏图标上的播放进度。暂停时用暂停色，没有曲目时清掉。
Future<void> syncWindowsTaskbarProgress(DesktopTrackSnapshot snap) async {
  if (!Platform.isWindows) return;
  try {
    final mode = switch (taskbarPhase(snap)) {
      DesktopTaskbarPhase.hidden => TaskbarProgressMode.noProgress,
      DesktopTaskbarPhase.playing => TaskbarProgressMode.normal,
      DesktopTaskbarPhase.paused => TaskbarProgressMode.paused,
    };
    await WindowsTaskbar.setProgressMode(mode);
    final progress = taskbarProgress(snap);
    if (progress != null) {
      await WindowsTaskbar.setProgress(progress.completed, progress.total);
    }
    _progressFailed = false;
  } catch (error, stack) {
    if (_progressFailed) return;
    _progressFailed = true;
    AppLogger.e(
      'taskbar progress failed',
      tag: 'window',
      error: error,
      stackTrace: stack,
    );
  }
}
