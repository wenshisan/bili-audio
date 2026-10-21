import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/player/sleep_timer.dart';
import '../../domain/queue/playback_queue.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../common/cover_image.dart';

final sleepStateProvider = StreamProvider<SleepState>((ref) {
  final timer = ref.watch(audioHandlerProvider).sleepTimer;
  return Stream.value(timer.state).asyncExpand((s) async* {
    yield s;
    yield* timer.stream;
  });
});

/// 播放页 (M6.2)
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final item = ref.watch(mediaItemProvider).value;
    final handler = ref.read(audioHandlerProvider);
    final track = handler.currentTrack;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (track != null) _MoreMenu(),
        ],
      ),
      body: item == null || track == null
          ? Center(child: Text(l10n.nothingPlaying))
          : SafeArea(
              child: LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth > 720;
                final cover = _CoverSection(item: item);
                const lyrics = _LyricsPlaceholder();
                return Column(
                  children: [
                    Expanded(
                      child: wide
                          ? Row(children: [
                              Expanded(child: cover),
                              const Expanded(child: lyrics),
                            ])
                          : Column(children: [
                              Expanded(flex: 3, child: cover),
                              const Expanded(flex: 2, child: lyrics),
                            ]),
                    ),
                    const _ProgressBar(),
                    const _Controls(),
                    const _SleepIndicator(),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ),
    );
  }
}

class _CoverSection extends ConsumerWidget {
  const _CoverSection({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.read(audioHandlerProvider).currentTrack!;
    final theme = Theme.of(context).textTheme;
    final pages = t.totalPages ?? 1;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (_, c) => CoverImage(
                  item.artUri?.toString(),
                  size: c.maxWidth,
                  radius: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(item.title,
              style: theme.titleLarge,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(item.artist ?? '', style: theme.bodyMedium),
          if (pages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.pageInfo(t.pageIndex ?? 1, pages, t.title),
                style: theme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// 歌词区占位: 歌词接入见 M5
class _LyricsPlaceholder extends StatelessWidget {
  const _LyricsPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          context.l10n.playerLyricsPlaceholder,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
}

class _ProgressBar extends ConsumerStatefulWidget {
  const _ProgressBar();

  @override
  ConsumerState<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<_ProgressBar> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final total = ref.watch(mediaItemProvider).value?.duration ?? Duration.zero;
    final maxMs = total.inMilliseconds.toDouble();
    final value =
        (_dragging ?? position.inMilliseconds.toDouble()).clamp(0.0, maxMs);
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Slider(
            value: maxMs == 0 ? 0 : value,
            max: maxMs == 0 ? 1 : maxMs,
            onChanged: maxMs == 0 ? null : (v) => setState(() => _dragging = v),
            onChangeEnd: (v) {
              ref
                  .read(audioHandlerProvider)
                  .seek(Duration(milliseconds: v.round()));
              setState(() => _dragging = null);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(Duration(milliseconds: value.round())),
                    style: style),
                Text(formatDuration(total), style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String playModeLabel(BuildContext context, PlayMode mode) {
  final l10n = context.l10n;
  return switch (mode) {
    PlayMode.sequential => l10n.modeSequential,
    PlayMode.listLoop => l10n.modeListLoop,
    PlayMode.singleLoop => l10n.modeSingleLoop,
    PlayMode.shuffle => l10n.modeShuffle,
    PlayMode.smartShuffle => l10n.modeSmartShuffle,
  };
}

IconData playModeIcon(PlayMode mode) => switch (mode) {
      PlayMode.sequential => Icons.trending_flat,
      PlayMode.listLoop => Icons.repeat,
      PlayMode.singleLoop => Icons.repeat_one,
      PlayMode.shuffle => Icons.shuffle,
      PlayMode.smartShuffle => Icons.auto_awesome,
    };

class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackStateProvider).value;
    final handler = ref.read(audioHandlerProvider);
    final playing = state?.playing ?? false;
    final buffering = state?.processingState == AudioProcessingState.loading ||
        state?.processingState == AudioProcessingState.buffering;
    final mode = handler.playbackQueue.mode;
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: playModeLabel(context, mode),
          icon: Icon(playModeIcon(mode)),
          onPressed: () {
            const modes = PlayMode.values;
            handler.setPlayMode(modes[(modes.indexOf(mode) + 1) % modes.length]);
          },
        ),
        IconButton(
          iconSize: 36,
          tooltip: 'Previous',
          icon: const Icon(Icons.skip_previous),
          onPressed: handler.skipToPrevious,
        ),
        SizedBox.square(
          dimension: 72,
          child: buffering
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(),
                )
              : IconButton.filled(
                  iconSize: 40,
                  tooltip: playing ? 'Pause' : 'Play',
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: playing ? handler.pause : handler.play,
                ),
        ),
        IconButton(
          iconSize: 36,
          tooltip: 'Next',
          icon: const Icon(Icons.skip_next),
          onPressed: handler.skipToNext,
        ),
        IconButton(
          tooltip: l10n.queueTitle,
          icon: const Icon(Icons.queue_music),
          onPressed: () => context.push('/queue'),
        ),
      ],
    );
  }
}

class _SleepIndicator extends ConsumerWidget {
  const _SleepIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = switch (ref.watch(sleepStateProvider).value) {
      SleepCountdown(:final remaining) =>
        l10n.sleepRemaining(formatDuration(remaining)),
      SleepAfterTracks(tracksLeft: 1) => l10n.sleepAfterCurrent,
      SleepAfterTracks() => l10n.sleepAfterNext,
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Chip(
        avatar: const Icon(Icons.bedtime_outlined, size: 18),
        label: Text(text),
        onDeleted: ref.read(audioHandlerProvider).sleepTimer.cancel,
      ),
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final handler = ref.read(audioHandlerProvider);
    return PopupMenuButton<String>(
      onSelected: (v) async {
        final track = handler.currentTrack;
        if (track == null) return;
        switch (v) {
          case 'speed':
            await _pickSpeed(context, ref);
          case 'sleep':
            await _pickSleep(context, ref);
          case 'playlist':
            await showAddToPlaylistSheet(context, ref, () async => [track]);
          case 'original':
            await showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(l10n.originalTitle),
                content: SelectableText('${track.title}\n${track.bvid}'),
              ),
            );
          case 'edit':
            await _editTitle(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'speed', child: Text(l10n.playerSpeed)),
        PopupMenuItem(value: 'sleep', child: Text(l10n.playerSleepTimer)),
        PopupMenuItem(value: 'playlist', child: Text(l10n.actionAddToPlaylist)),
        PopupMenuItem(value: 'original', child: Text(l10n.playerViewOriginalTitle)),
        PopupMenuItem(value: 'edit', child: Text(l10n.playerEditTitle)),
      ],
    );
  }

  Future<void> _pickSpeed(BuildContext context, WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final speed = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final s in const [0.75, 1.0, 1.25, 1.5, 2.0])
              ChoiceChip(
                label: Text('${s}x'),
                selected: handler.engine.speed == s,
                onSelected: (_) => Navigator.pop(c, s),
              ),
          ],
        ),
      ),
    );
    if (speed != null) await handler.setSpeed(speed);
  }

  Future<void> _pickSleep(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final timer = ref.read(audioHandlerProvider).sleepTimer;
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.sleepOff), onTap: () => Navigator.pop(c, 0)),
            for (final m in const [15, 30, 60])
              ListTile(
                title: Text(l10n.sleepMinutes(m)),
                onTap: () => Navigator.pop(c, m),
              ),
            ListTile(
              title: Text(l10n.sleepAfterCurrent),
              onTap: () => Navigator.pop(c, -1),
            ),
            ListTile(
              title: Text(l10n.sleepAfterNext),
              onTap: () => Navigator.pop(c, -2),
            ),
          ],
        ),
      ),
    );
    switch (choice) {
      case null:
        return;
      case 0:
        timer.cancel();
      case < 0:
        timer.startAfterTracks(-choice);
      default:
        timer.start(Duration(minutes: choice));
    }
  }

  /// 编辑歌名/歌手: 写 user_edited=true, 重启保持 (M6.2)
  Future<void> _editTitle(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final handler = ref.read(audioHandlerProvider);
    final track = handler.currentTrack!;
    final name = TextEditingController(text: track.displayTitle);
    final artist = TextEditingController(text: track.artist ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.playerEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: l10n.fieldSongName),
            ),
            TextField(
              controller: artist,
              decoration: InputDecoration(labelText: l10n.fieldArtist),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(c, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok != true) return;
    final newName = name.text.trim().isEmpty ? null : name.text.trim();
    final newArtist = artist.text.trim().isEmpty ? null : artist.text.trim();
    await ref.read(databaseProvider).tracksDao.updateTrackByUser(
          bvid: track.bvid,
          cid: track.cid,
          cleanedName: newName,
          artist: newArtist,
        );
    handler.updateCurrentTrack(
      track.copyWith(cleanedName: newName, artist: newArtist),
    );
  }
}
