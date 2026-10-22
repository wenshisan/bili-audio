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
import '../player/widgets/player_transport.dart';

/// 播放队列 (M6.3)
///
/// 顺序模式可拖拽排序; 随机模式禁用拖拽。可移除任意单项，含正在播放的。
class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(queueItemsProvider);
    ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);
    final ordered = handler.playbackQueue.orderedTracks;

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
      body: const QueueList(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              TextButton.icon(
                icon: Icon(playModeIcon(handler.playbackQueue.mode)),
                label: Text(playModeLabel(context, handler.playbackQueue.mode)),
                onPressed: () {
                  const modes = PlayMode.values;
                  final mode = handler.playbackQueue.mode;
                  handler.setPlayMode(modes[(modes.indexOf(mode) + 1) % modes.length]);
                },
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.playlist_add),
                label: Text(l10n.queueSaveAsPlaylist),
                onPressed: ordered.isEmpty
                    ? null
                    : () => _saveAsPlaylist(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAsPlaylist(BuildContext context, WidgetRef ref) async {
    final name = await showPlaylistNameDialog(
      context,
      title: context.l10n.queueSaveAsPlaylist,
    );
    if (name == null) return;
    final db = ref.read(databaseProvider);
    final id = await db.playlistsDao.createPlaylist(
      PlaylistsCompanion.insert(name: name, source: const Value('local')),
    );
    await ref.read(playerActionsProvider).addToPlaylist(
          id,
          ref.read(audioHandlerProvider).playbackQueue.orderedTracks,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.addedToPlaylist(name))),
      );
    }
  }
}

/// 队列列表。大宽度播放栏内嵌时不带页面脚手架。
///
/// [upcomingOnly] 为车机布局：只显示接下来最多 [maxItems] 首，不能拖拽。
class QueueList extends ConsumerWidget {
  const QueueList({
    this.embedded = false,
    this.upcomingOnly = false,
    this.maxItems,
    super.key,
  });

  final bool embedded;
  final bool upcomingOnly;
  final int? maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.watch(queueItemsProvider);
    ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);
    final q = handler.playbackQueue;
    final shuffle = q.mode == PlayMode.shuffle || q.mode == PlayMode.smartShuffle;
    final allowReorder = !upcomingOnly && !shuffle;
    var tracks = q.orderedTracks;
    var indexBase = 0;
    if (upcomingOnly) {
      final start = q.cursor + 1;
      tracks = start >= tracks.length ? const [] : tracks.sublist(start);
      indexBase = start;
    }
    if (maxItems != null && tracks.length > maxItems!) {
      tracks = tracks.sublist(0, maxItems!);
    }
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: embedded ? 8 : 0),
          child: Text(l10n.queueEmpty),
        ),
      );
    }

    Widget tileAt(int localIndex) {
      final absolute = indexBase + localIndex;
      final t = tracks[localIndex];
      final current = absolute == q.cursor;
      final tile = ListTile(
        selected: current,
        leading: CoverImage(t.cover, size: 44),
        title: Text(t.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(t.displayArtist, maxLines: 1),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (current) const Icon(Icons.equalizer),
            if (!upcomingOnly)
              IconButton(
                tooltip: l10n.queueRemove,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: () => handler.removeOrderedAt(absolute),
              ),
            if (allowReorder && !current)
              ReorderableDragStartListener(
                index: localIndex,
                child: const Icon(Icons.drag_handle),
              ),
          ],
        ),
        onTap: upcomingOnly ? null : () => handler.skipToQueueItem(absolute),
      );
      if (upcomingOnly) return tile;
      return Dismissible(
        key: ValueKey('${t.bvid}_${t.cid}_$absolute'),
        direction: DismissDirection.endToStart,
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
        onDismissed: (_) => handler.removeOrderedAt(absolute),
        child: tile,
      );
    }

    if (!allowReorder) {
      return ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (_, i) => tileAt(i),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: tracks.length,
      onReorderItem: (from, to) {
        if (!handler.reorder(indexBase + from, indexBase + to)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.queueReorderDisabled)),
          );
        }
      },
      itemBuilder: (_, i) => tileAt(i),
    );
  }
}
