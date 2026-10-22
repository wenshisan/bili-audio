import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';
import '../../queue/queue_page.dart';
import 'player_transport.dart';

/// 大宽度常驻播放栏，和全屏播放页共用同一套控件与播放器。
class NowPlayingPane extends ConsumerWidget {
  const NowPlayingPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final item = ref.watch(mediaItemProvider).value;
    final track = ref.read(audioHandlerProvider).currentTrack;
    if (item == null || track == null) {
      return SizedBox.expand(
        key: const Key('now-playing-pane'),
        child: Center(child: Text(l10n.nothingPlaying)),
      );
    }
    return const SizedBox.expand(
      key: Key('now-playing-pane'),
      child: Column(
        children: [
          Expanded(flex: 3, child: _Cover()),
          CurrentLyricLine(),
          PlayerProgressBar(),
          PlayerControls(showQueue: false),
          PlayerSleepIndicator(),
          Expanded(flex: 2, child: QueueList(embedded: true)),
        ],
      ),
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).value;
    if (item == null) return const SizedBox.shrink();
    return PlayerCoverSection(item: item, padding: 16);
  }
}
