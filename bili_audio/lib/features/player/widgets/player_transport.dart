import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/lyrics/lyrics_manager.dart';
import '../../../data/player/sleep_timer.dart';
import '../../../domain/lyrics/lrc_parser.dart';
import '../../../domain/queue/playback_queue.dart';
import '../../../l10n/l10n.dart';
import '../../common/cover_image.dart';
import '../../lyrics/lyrics_controller.dart';

final sleepStateProvider = StreamProvider<SleepState>((ref) {
  final timer = ref.watch(audioHandlerProvider).sleepTimer;
  return Stream.value(timer.state).asyncExpand((s) async* {
    yield s;
    yield* timer.stream;
  });
});

/// 播放页和右侧播放栏共用的封面与标题。
class PlayerCoverSection extends ConsumerWidget {
  const PlayerCoverSection({required this.item, this.padding = 24, super.key});

  final MediaItem item;
  final double padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.read(audioHandlerProvider).currentTrack!;
    final theme = Theme.of(context).textTheme;
    final pages = t.totalPages ?? 1;
    return Padding(
      padding: EdgeInsets.all(padding),
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
          const SizedBox(height: 12),
          Text(
            item.title,
            style: theme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.artist ?? '',
            style: theme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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

/// 当前歌词一行。没有歌词时不占内容。
class CurrentLyricLine extends ConsumerWidget {
  const CurrentLyricLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = ref.watch(lyricsControllerProvider).value;
    if (found is! LyricsFound || found.lyrics.lines.isEmpty) {
      return const SizedBox(height: 20);
    }
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final index = LyricsTimeline(found.lyrics).indexAt(position);
    if (index < 0) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        found.lyrics.lines[index].text,
        key: const Key('current-lyric-line'),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class PlayerProgressBar extends ConsumerStatefulWidget {
  const PlayerProgressBar({super.key});

  @override
  ConsumerState<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends ConsumerState<PlayerProgressBar> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final total = ref.watch(mediaItemProvider).value?.duration ?? Duration.zero;
    final maxMs = total.inMilliseconds.toDouble();
    final value = (_dragging ?? position.inMilliseconds.toDouble()).clamp(0.0, maxMs);
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
              ref.read(audioHandlerProvider).seek(Duration(milliseconds: v.round()));
              setState(() => _dragging = null);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(Duration(milliseconds: value.round())), style: style),
                Text(formatDuration(total), style: style),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlayerControls extends ConsumerWidget {
  const PlayerControls({
    this.mainExtent = 72,
    this.iconExtent = 48,
    this.showQueue = true,
    this.showMode = true,
    super.key,
  });

  /// 主按钮边长。车机布局传 76 以上。
  final double mainExtent;
  final double iconExtent;
  final bool showQueue;
  final bool showMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackStateProvider).value;
    final handler = ref.read(audioHandlerProvider);
    final playing = state?.playing ?? false;
    final buffering = state?.processingState == AudioProcessingState.loading ||
        state?.processingState == AudioProcessingState.buffering;
    final mode = handler.playbackQueue.mode;
    final l10n = context.l10n;

    Widget target({
      required double extent,
      required Widget child,
    }) {
      return SizedBox(width: extent, height: extent, child: child);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showMode)
          target(
            extent: iconExtent,
            child: IconButton(
              tooltip: playModeLabel(context, mode),
              icon: Icon(playModeIcon(mode)),
              onPressed: () {
                const modes = PlayMode.values;
                handler.setPlayMode(modes[(modes.indexOf(mode) + 1) % modes.length]);
              },
            ),
          ),
        target(
          extent: iconExtent,
          child: IconButton(
            key: const Key('transport-prev'),
            iconSize: iconExtent * 0.6,
            tooltip: 'Previous',
            icon: const Icon(Icons.skip_previous),
            onPressed: handler.skipToPrevious,
          ),
        ),
        target(
          extent: mainExtent,
          child: buffering
              ? Padding(
                  padding: EdgeInsets.all(mainExtent * 0.25),
                  child: const CircularProgressIndicator(),
                )
              : IconButton.filled(
                  key: const Key('transport-play'),
                  iconSize: mainExtent * 0.5,
                  tooltip: playing ? 'Pause' : 'Play',
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: playing ? handler.pause : handler.play,
                ),
        ),
        target(
          extent: iconExtent,
          child: IconButton(
            key: const Key('transport-next'),
            iconSize: iconExtent * 0.6,
            tooltip: 'Next',
            icon: const Icon(Icons.skip_next),
            onPressed: handler.skipToNext,
          ),
        ),
        if (showQueue)
          target(
            extent: iconExtent,
            child: IconButton(
              tooltip: l10n.queueTitle,
              icon: const Icon(Icons.queue_music),
              onPressed: () => context.push('/queue'),
            ),
          ),
      ],
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

class PlayerSleepIndicator extends ConsumerWidget {
  const PlayerSleepIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = switch (ref.watch(sleepStateProvider).value) {
      SleepCountdown(:final remaining) => l10n.sleepRemaining(formatDuration(remaining)),
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
