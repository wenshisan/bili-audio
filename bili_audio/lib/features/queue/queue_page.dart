import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/queue/playback_queue.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../common/cover_image.dart';
import '../player/player_actions.dart';
import '../player/player_page.dart' show playModeIcon, playModeLabel;

/// 播放队列 (M6.3)
///
/// 顺序模式可拖拽排序; 随机模式禁用拖拽。滑动删除单项。
class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // 队列或模式变化都会推送 playbackState / queue
    ref.watch(queueItemsProvider);
    ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);
    final q = handler.playbackQueue;
    final ordered = q.orderedTracks;
    final shuffle = q.mode == PlayMode.shuffle || q.mode == PlayMode.smartShuffle;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.queueTitle),
        actions: [
          IconButton(
            tooltip: l10n.queueClear,
            icon: const Icon(Icons.clear_all),
            onPressed: ordered.length > 1 ? handler.clearExceptCurrent : null,
          ),
        ],
      ),
      body: ordered.isEmpty
          ? Center(child: Text(l10n.queueEmpty))
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: ordered.length,
              onReorderItem: (from, to) {
                if (!handler.reorder(from, to)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.queueReorderDisabled)),
                  );
                }
              },
              itemBuilder: (context, i) {
                final t = ordered[i];
                final current = i == q.cursor;
                final key = ValueKey('${t.bvid}_${t.cid}_$i');
                final tile = ListTile(
                  selected: current,
                  leading: CoverImage(t.cover, size: 44),
                  title: Text(t.displayTitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(t.displayArtist, maxLines: 1),
                  trailing: current
                      ? const Icon(Icons.equalizer)
                      : shuffle
                          ? null
                          : ReorderableDragStartListener(
                              index: i,
                              child: const Icon(Icons.drag_handle),
                            ),
                  onTap: () => handler.skipToQueueItem(i),
                );
                return Dismissible(
                  key: key,
                  direction:
                      current ? DismissDirection.none : DismissDirection.endToStart,
                  background: ColoredBox(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 24),
                        child: Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                  onDismissed: (_) => handler.removeAt(q.tracks.indexOf(t)),
                  child: tile,
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              TextButton.icon(
                icon: Icon(playModeIcon(q.mode)),
                label: Text(playModeLabel(context, q.mode)),
                onPressed: () {
                  const modes = PlayMode.values;
                  handler.setPlayMode(
                      modes[(modes.indexOf(q.mode) + 1) % modes.length]);
                },
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.playlist_add),
                label: Text(l10n.queueSaveAsPlaylist),
                onPressed: ordered.isEmpty
                    ? null
                    : () => _saveAsPlaylist(context, ref, ordered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAsPlaylist(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> tracks,
  ) async {
    final name = await showPlaylistNameDialog(context,
        title: context.l10n.queueSaveAsPlaylist);
    if (name == null) return;
    final db = ref.read(databaseProvider);
    final id = await db.playlistsDao.createPlaylist(
      PlaylistsCompanion.insert(name: name, source: const Value('local')),
    );
    await ref
        .read(playerActionsProvider)
        .addToPlaylist(id, ref.read(audioHandlerProvider).playbackQueue.orderedTracks);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addedToPlaylist(name))),
      );
    }
  }
}
