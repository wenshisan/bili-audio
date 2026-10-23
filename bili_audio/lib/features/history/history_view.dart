import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../data/db/daos/history_dao.dart';
import '../../l10n/l10n.dart';
import '../common/cover_image.dart';
import '../player/player_actions.dart';

final historyProvider = StreamProvider<List<HistoryEntry>>(
  (ref) => ref.watch(databaseProvider).historyDao.watchRecent(),
);

/// 历史分组: 今天 / 昨天 / 本周 / 更早
enum HistoryGroup { today, yesterday, thisWeek, earlier }

HistoryGroup historyGroupOf(DateTime playedAt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(playedAt.year, playedAt.month, playedAt.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return HistoryGroup.today;
  if (diff == 1) return HistoryGroup.yesterday;
  // 本周: 周一为一周第一天
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  if (!day.isBefore(weekStart)) return HistoryGroup.thisWeek;
  return HistoryGroup.earlier;
}

/// 播放历史 (M6.5)
class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(historyProvider);
    final dao = ref.read(databaseProvider).historyDao;

    return MotionSwap(
      swapKey: history.when(
        loading: () => 'loading',
        error: (_, _) => 'error',
        data: (entries) => entries.isEmpty ? 'empty' : 'ready',
      ),
      child: history.when(
        loading: () => const SkeletonList(leading: 44),
        error: (e, _) => Center(child: Text(errorText(l10n, e))),
        data: (entries) {
          if (entries.isEmpty) return Center(child: Text(l10n.historyEmpty));
          final now = DateTime.now();
          final children = <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.historyClear),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      content: Text(l10n.historyClear),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(l10n.confirm),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await dao.clear();
                },
              ),
            ),
          ];
          HistoryGroup? last;
          for (final e in entries) {
            final group = historyGroupOf(e.history.playedAt, now);
            if (group != last) {
              last = group;
              children.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(switch (group) {
                    HistoryGroup.today => l10n.historyToday,
                    HistoryGroup.yesterday => l10n.historyYesterday,
                    HistoryGroup.thisWeek => l10n.historyThisWeek,
                    HistoryGroup.earlier => l10n.historyEarlier,
                  }, style: Theme.of(context).textTheme.titleSmall),
                ),
              );
            }
            children.add(
              ListEntrance(
                index: children.length,
                child: _HistoryTile(entry: e),
              ),
            );
          }
          return ListEntranceScope(child: ListView(children: children));
        },
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = trackFromRow(entry.track);
    final h = entry.history;
    final time = TimeOfDay.fromDateTime(h.playedAt).format(context);
    return Dismissible(
      key: ValueKey(h.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      onDismissed: (_) => ref.read(databaseProvider).historyDao.remove(h.id),
      child: ListTile(
        leading: CoverImage(track.cover, size: 44),
        title: Text(
          track.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${track.displayArtist} · $time', maxLines: 1),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: h.completion, minHeight: 2),
          ],
        ),
        onTap: () async {
          // 恢复播放位置: 已完整听完则从头开始
          final handler = ref.read(audioHandlerProvider);
          await handler.setTracks([track]);
          if (h.completion < 0.98 && h.positionMs > 0) {
            await handler.seek(Duration(milliseconds: h.positionMs));
          }
        },
      ),
    );
  }
}
