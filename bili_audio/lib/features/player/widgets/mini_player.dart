import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/motion/motion.dart';
import '../../../app/providers.dart';
import '../../../app/widgets/region_surface.dart';
import '../../../l10n/l10n.dart';
import '../../common/cover_image.dart';
import '../player_actions.dart';

/// 底部常驻迷你播放栏 (M0.4 / M6.2); 无播放内容时隐藏
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(audioHandlerProvider).downgradedForGuest.listen((
      downgraded,
    ) {
      if (mounted) promptLoginIfDowngraded(context, ref, downgraded);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(mediaItemProvider).value;
    final state = ref.watch(playbackStateProvider).value;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final handler = ref.read(audioHandlerProvider);
    final playing = state?.playing ?? false;
    final total = item?.duration ?? Duration.zero;
    final l10n = context.l10n;

    final Widget bar;
    if (item == null) {
      bar = const SizedBox(width: double.infinity, height: 0);
    } else {
      bar = RegionSurface(
        tone: RegionTone.high,
        shadow: RegionShadow.top,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/player'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: total.inMilliseconds == 0
                      ? 0
                      : (position.inMilliseconds / total.inMilliseconds).clamp(
                          0.0,
                          1.0,
                        ),
                  minHeight: 2,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: MotionSwap(
                          swapKey: item.id,
                          child: Row(
                            key: ValueKey(item.id),
                            children: [
                              CoverImage(item.artUri?.toString(), size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      item.artist ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '上一首',
                        icon: const Icon(Icons.skip_previous),
                        onPressed: handler.skipToPrevious,
                      ),
                      IconButton(
                        tooltip: playing ? 'Pause' : 'Play',
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: playing ? handler.pause : handler.play,
                      ),
                      IconButton(
                        tooltip: '下一首',
                        icon: const Icon(Icons.skip_next),
                        onPressed: handler.skipToNext,
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
        ),
      );
    }
    return AnimatedSize(
      duration: Motion.reduced(context) ? Duration.zero : Motion.swap,
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      child: bar,
    );
  }
}
