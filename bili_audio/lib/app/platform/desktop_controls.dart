import '../../data/player/bili_audio_handler.dart';
import '../../domain/update/distribution.dart';

/// 托盘、任务栏和程序坞共用的播放快照。
class DesktopTrackSnapshot {
  const DesktopTrackSnapshot({
    this.title,
    this.artist,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final String? title;
  final String? artist;
  final bool playing;
  final Duration position;
  final Duration duration;

  bool get hasTrack {
    final name = title?.trim();
    return name != null && name.isNotEmpty;
  }

  String get trackTitle => title!.trim();
}

/// 任务栏图标上的进度样式。
enum DesktopTaskbarPhase { hidden, playing, paused }

enum DesktopCommand {
  togglePlay('togglePlay'),
  previous('previous'),
  next('next'),
  showWindow('show'),
  hideWindow('hide'),
  quit('quit');

  const DesktopCommand(this.id);

  final String id;
}

class DesktopControlLabels {
  const DesktopControlLabels({
    required this.appName,
    required this.play,
    required this.pause,
    required this.previous,
    required this.next,
    required this.nothingPlaying,
    required this.showWindow,
    required this.hideWindow,
    required this.quit,
  });

  static DesktopControlLabels get zh => DesktopControlLabels(
    appName: productTitle(),
    play: '播放',
    pause: '暂停',
    previous: '上一首',
    next: '下一首',
    nothingPlaying: '暂无播放',
    showWindow: '显示主窗口',
    hideWindow: '隐藏到托盘',
    quit: '退出',
  );

  final String appName;
  final String play;
  final String pause;
  final String previous;
  final String next;
  final String nothingPlaying;
  final String showWindow;
  final String hideWindow;
  final String quit;

  String playingLabel(bool playing) => playing ? pause : play;
}

class DesktopMenuEntry {
  const DesktopMenuEntry({
    required this.label,
    this.command,
    this.enabled = true,
  }) : separator = false;

  const DesktopMenuEntry.separator()
    : label = '',
      command = null,
      enabled = false,
      separator = true;

  final String label;
  final DesktopCommand? command;
  final bool enabled;
  final bool separator;
}

DesktopCommand? commandById(String id) {
  for (final command in DesktopCommand.values) {
    if (command.id == id) return command;
  }
  return null;
}

/// 菜单和窗口标题变了才需要重建。进度不放进来。
String playbackChromeKey(DesktopTrackSnapshot snap) =>
    '${snap.playing}|${snap.hasTrack}|${snap.title}|${snap.artist}|'
    '${snap.duration.inMilliseconds}';

String playbackLine(DesktopTrackSnapshot snap) {
  if (!snap.hasTrack) return '';
  final artist = snap.artist?.trim() ?? '';
  if (artist.isEmpty) return snap.trackTitle;
  return '${snap.trackTitle} — $artist';
}

String playbackTooltip(DesktopTrackSnapshot snap, String appName) {
  final line = playbackLine(snap);
  return line.isEmpty ? appName : line;
}

String playbackWindowTitle(DesktopTrackSnapshot snap, String appName) {
  final line = playbackLine(snap);
  if (line.isEmpty) return appName;
  return '$line — $appName';
}

/// macOS 菜单栏图标旁边的短标题。没有曲目时清空。
String menuBarTitle(DesktopTrackSnapshot snap) {
  if (!snap.hasTrack) return '';
  const limit = 14;
  final text = snap.trackTitle;
  final shown = text.length <= limit ? text : '${text.substring(0, limit)}…';
  return ' $shown';
}

DesktopTaskbarPhase taskbarPhase(DesktopTrackSnapshot snap) {
  if (!snap.hasTrack || snap.duration <= Duration.zero) {
    return DesktopTaskbarPhase.hidden;
  }
  return snap.playing
      ? DesktopTaskbarPhase.playing
      : DesktopTaskbarPhase.paused;
}

({int completed, int total})? taskbarProgress(DesktopTrackSnapshot snap) {
  if (taskbarPhase(snap) == DesktopTaskbarPhase.hidden) return null;
  final total = snap.duration.inMilliseconds;
  final raw = snap.position.inMilliseconds;
  final completed = raw < 0 ? 0 : (raw > total ? total : raw);
  return (completed: completed, total: total);
}

List<DesktopMenuEntry> trayMenuEntries(
  DesktopTrackSnapshot snap,
  DesktopControlLabels labels,
) {
  final line = playbackLine(snap);
  final transport = snap.hasTrack;
  return [
    DesktopMenuEntry(
      label: line.isEmpty ? labels.nothingPlaying : line,
      enabled: false,
    ),
    DesktopMenuEntry(
      label: labels.playingLabel(snap.playing),
      command: DesktopCommand.togglePlay,
      enabled: transport,
    ),
    DesktopMenuEntry(
      label: labels.previous,
      command: DesktopCommand.previous,
      enabled: transport,
    ),
    DesktopMenuEntry(
      label: labels.next,
      command: DesktopCommand.next,
      enabled: transport,
    ),
    const DesktopMenuEntry.separator(),
    DesktopMenuEntry(
      label: labels.showWindow,
      command: DesktopCommand.showWindow,
    ),
    DesktopMenuEntry(
      label: labels.hideWindow,
      command: DesktopCommand.hideWindow,
    ),
    const DesktopMenuEntry.separator(),
    DesktopMenuEntry(label: labels.quit, command: DesktopCommand.quit),
  ];
}

List<DesktopMenuEntry> compactMenu(List<DesktopMenuEntry> entries) {
  final out = <DesktopMenuEntry>[];
  for (final entry in entries) {
    if (entry.separator && (out.isEmpty || out.last.separator)) continue;
    out.add(entry);
  }
  if (out.isNotEmpty && out.last.separator) out.removeLast();
  return out;
}

/// 程序坞菜单不含隐藏和退出。退出留在系统菜单里。
List<DesktopMenuEntry> dockMenuEntries(
  DesktopTrackSnapshot snap,
  DesktopControlLabels labels,
) {
  return compactMenu([
    for (final entry in trayMenuEntries(snap, labels))
      if (entry.command != DesktopCommand.hideWindow &&
          entry.command != DesktopCommand.quit)
        entry,
  ]);
}

List<Map<String, Object>> dockMenuPayload(
  DesktopTrackSnapshot snap,
  DesktopControlLabels labels,
) {
  return [
    for (final entry in dockMenuEntries(snap, labels))
      if (entry.separator)
        <String, Object>{'separator': true}
      else
        <String, Object>{
          'label': entry.label,
          'enabled': entry.enabled,
          if (entry.command != null) 'id': entry.command!.id,
        },
  ];
}

void applyPlaybackCommand(BiliAudioHandler handler, DesktopCommand command) {
  switch (command) {
    case DesktopCommand.togglePlay:
      if (handler.engine.playing) {
        handler.pause();
      } else {
        handler.play();
      }
    case DesktopCommand.previous:
      handler.skipToPrevious();
    case DesktopCommand.next:
      handler.skipToNext();
    case DesktopCommand.showWindow:
    case DesktopCommand.hideWindow:
    case DesktopCommand.quit:
      break;
  }
}
