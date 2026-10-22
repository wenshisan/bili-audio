import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/adaptive/max_width_box.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';

final cacheStatsProvider = FutureProvider.autoDispose<(int, int)>(
  (ref) => ref.watch(audioHandlerProvider).downloads.store.stats(),
);

/// 缓存管理占位 (M6.7, 完整界面见 v0.2.3)
class CachePage extends StatelessWidget {
  const CachePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cacheTitle)),
      body: const MaxWidthBox(
        maxWidth: 640,
        child: _CacheBody(),
      ),
    );
  }
}

class _CacheBody extends ConsumerWidget {
  const _CacheBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(cacheStatsProvider);

    Future<void> clear() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(l10n.cacheClearConfirm),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l10n.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(l10n.confirm)),
          ],
        ),
      );
      if (ok != true) return;
      final downloads = ref.read(audioHandlerProvider).downloads;
      final n = await downloads.store
          .clearUnpinned(protectedKeys: downloads.activeKeys);
      ref.invalidate(cacheStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.cacheCleared(n))));
      }
    }

    return Center(
        child: stats.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text(errorText(l10n, e)),
          data: (s) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.cacheSummary(s.$1, formatBytes(s.$2)),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: s.$1 == 0 && s.$2 == 0 ? null : clear,
                child: Text(l10n.cacheClearAll),
              ),
            ],
          ),
        ),
    );
  }
}
