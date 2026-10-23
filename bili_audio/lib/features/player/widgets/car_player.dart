import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/adaptive/layout_settings.dart';
import '../../../app/providers.dart';
import '../../../app/widgets/region_surface.dart';
import '../../../l10n/l10n.dart';
import '../../queue/queue_page.dart';
import 'player_transport.dart';

/// 车机播放界面：大按钮，右侧只留队列或一行歌词。
class CarPlayer extends ConsumerStatefulWidget {
  const CarPlayer({super.key});

  @override
  ConsumerState<CarPlayer> createState() => _CarPlayerState();
}

class _CarPlayerState extends ConsumerState<CarPlayer> {
  var _showQueue = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      key: const Key('car-layout'),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: const Key('car-exit'),
                    tooltip: l10n.carLayoutOff,
                    iconSize: 32,
                    onPressed: () => ref
                        .read(layoutSettingsProvider.notifier)
                        .setCarMode(CarLayoutMode.off),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Expanded(child: _CarCover()),
                const PlayerControls(
                  mainExtent: 76,
                  iconExtent: 76,
                  showQueue: false,
                  showMode: false,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: RegionSurface(
              edge: RegionEdge.leading,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.carShowQueue),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.carShowLyrics),
                        ),
                      ],
                      selected: {_showQueue},
                      onSelectionChanged: (value) =>
                          setState(() => _showQueue = value.first),
                    ),
                  ),
                  Expanded(
                    child: _showQueue
                        ? const QueueList(upcomingOnly: true, maxItems: 5)
                        : const Center(child: CurrentLyricLine()),
                  ),
                ],
              ),
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
    return PlayerCoverSection(item: item, padding: 16);
  }
}
