import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';
import '../../common/cover_image.dart';

/// 底部常驻迷你播放栏 (M0.4 / M6.2); 无播放内容时隐藏
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).value;
    if (item == null) return const SizedBox.shrink();
    final state = ref.watch(playbackStateProvider).value;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final handler = ref.read(audioHandlerProvider);
    final playing = state?.playing ?? false;
    final total = item.duration ?? Duration.zero;
    final l10n = context.l10n;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () => context.push('/player'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: total.inMilliseconds == 0
                  ? 0
                  : (position.inMilliseconds / total.inMilliseconds)
                      .clamp(0.0, 1.0),
              minHeight: 2,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CoverImage(item.artUri?.toString(), size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          item.artist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: playing ? 'Pause' : 'Play',
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    onPressed: playing ? handler.pause : handler.play,
                  ),
                  IconButton(
                    tooltip: l10n.queueTitle,
                    icon: const Icon(Icons.queue_music),
                    onPressed: () => context.push('/queue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
