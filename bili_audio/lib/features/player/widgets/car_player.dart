import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/adaptive/layout_settings.dart';
import '../../../app/providers.dart';
import '../../../app/widgets/region_surface.dart';
import '../../../l10n/l10n.dart';
import '../../lyrics/lyrics_view.dart';
import '../../queue/queue_page.dart';
import 'player_transport.dart';

/// 车机播放界面。
///
/// 顶部放大当前歌词。左侧是完整歌词或播放列表，右侧是封面和介绍。
/// 播放控制在最底部，歌词和播放列表的切换在控制区上方。
class CarPlayer extends ConsumerStatefulWidget {
  const CarPlayer({super.key});

  @override
  ConsumerState<CarPlayer> createState() => _CarPlayerState();
}

class _CarPlayerState extends ConsumerState<CarPlayer> {
  var _showQueue = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      key: const Key('car-layout'),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            key: const Key('car-current-lyric'),
            height: 80,
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(child: CurrentLyricLine(prominent: true)),
                IconButton(
                  key: const Key('car-exit'),
                  tooltip: l10n.carLayoutOff,
                  iconSize: 32,
                  onPressed: () => ref
                      .read(layoutSettingsProvider.notifier)
                      .setCarMode(CarLayoutMode.off),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: KeyedSubtree(
                    key: const Key('car-main-pane'),
                    child: _showQueue
                        ? const QueueList(upcomingOnly: true)
                        : const LyricsView(),
                  ),
                ),
                const Expanded(
                  child: RegionSurface(
                    edge: RegionEdge.leading,
                    child: KeyedSubtree(
                      key: Key('car-side-pane'),
                      child: _CarCover(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          RegionSurface(
            edge: RegionEdge.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SegmentedButton<bool>(
                    key: const Key('car-panel-toggle'),
                    style: ButtonStyle(
                      textStyle: WidgetStatePropertyAll(
                        theme.textTheme.titleMedium,
                      ),
                      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                    ),
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.carShowLyrics),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.carShowQueue),
                      ),
                    ],
                    selected: {_showQueue},
                    onSelectionChanged: (value) =>
                        setState(() => _showQueue = value.first),
                  ),
                ),
                const PlayerProgressBar(),
                const PlayerControls(
                  mainExtent: 76,
                  iconExtent: 76,
                  showQueue: false,
                  showMode: false,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarCover extends ConsumerWidget {
  const _CarCover();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).value;
    final l10n = context.l10n;
    if (item == null || ref.read(audioHandlerProvider).currentTrack == null) {
      return Center(child: Text(l10n.nothingPlaying));
    }
    return PlayerCoverSection(item: item, padding: 12, shrinkToFit: true);
  }
}
