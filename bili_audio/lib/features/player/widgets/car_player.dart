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
/// 播放控制在最底部。歌词和队列的切换半透明，浮在左侧区域左上角。
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
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: KeyedSubtree(
                          key: const Key('car-main-pane'),
                          child: _showQueue
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 68),
                                  child: QueueList(upcomingOnly: true),
                                )
                              : const LyricsView(),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _panelToggle(l10n, theme),
                      ),
                    ],
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
          const RegionSurface(
            edge: RegionEdge.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerProgressBar(),
                PlayerControls(
                  mainExtent: 76,
                  iconExtent: 76,
                  showQueue: false,
                  showMode: false,
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelToggle(AppLocalizations l10n, ThemeData theme) {
    final scheme = theme.colorScheme;
    final style = theme.textTheme.titleMedium;
    return Material(
      key: const Key('car-panel-toggle'),
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleSegment(
            label: l10n.carShowLyrics,
            selected: !_showQueue,
            style: style,
            onTap: () => setState(() => _showQueue = false),
          ),
          _toggleSegment(
            label: l10n.carShowQueue,
            selected: _showQueue,
            style: style,
            onTap: () => setState(() => _showQueue = true),
          ),
        ],
      ),
    );
  }

  Widget _toggleSegment({
    required String label,
    required bool selected,
    required TextStyle? style,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Ink(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: selected
            ? scheme.secondaryContainer.withValues(alpha: 0.72)
            : scheme.surface.withValues(alpha: 0.55),
        child: Center(
          child: Text(
            label,
            style: style?.copyWith(
              color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
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
