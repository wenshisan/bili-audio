import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../data/db/app_database.dart' hide Track;
import '../../domain/entities/audio_track.dart';
import '../../domain/queue/playback_queue.dart';
import '../../domain/queue/queue_search.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../common/cover_image.dart';
import '../player/player_actions.dart';
import '../player/widgets/player_transport.dart';

/// 播放队列 (M6.3)
///
/// 顺序模式可拖拽排序; 随机模式禁用拖拽。可移除任意单项，含正在播放的。
/// 可按歌名、歌手或 UP 主在队列内搜索，点结果从那一首开始播放。
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
                  handler.setPlayMode(
                    modes[(modes.indexOf(mode) + 1) % modes.length],
                  );
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
    await ref
        .read(playerActionsProvider)
        .addToPlaylist(
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
/// 非 [upcomingOnly] 时顶部可搜索。搜索时不能拖拽，点选仍按原队列位置跳转。
/// [upcomingOnly] 为车机布局：只显示接下来最多 [maxItems] 首，不能拖拽、不能搜索。
class QueueList extends ConsumerStatefulWidget {
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
  ConsumerState<QueueList> createState() => _QueueListState();
}

class _QueueListState extends ConsumerState<QueueList> {
  final _search = TextEditingController();
  List<Track>? _indexedTracks;
  QueueSearchIndex? _index;
  var _indexGeneration = 0;

  @override
  void dispose() {
    _indexGeneration++;
    _search.dispose();
    super.dispose();
  }

  /// 曲目没变就复用索引。长队列的拼音在后台算，输入时只做字符串比较。
  void _ensureIndex(List<Track> ordered) {
    final previous = _indexedTracks;
    if (previous != null && _index != null && _sameTracks(previous, ordered)) {
      return;
    }
    _indexedTracks = ordered;
    final generation = ++_indexGeneration;
    if (ordered.length <= queueSearchSyncLimit) {
      _index = QueueSearchIndex.sync(ordered);
      return;
    }
    _index = QueueSearchIndex.literal(ordered);
    final fields = QueueSearchIndex.capture(ordered);
    unawaited(_loadPinyin(generation, fields));
  }

  Future<void> _loadPinyin(int generation, List<List<String>> fields) async {
    List<QueueSearchHaystack> haystacks;
    try {
      haystacks = await compute(buildQueueSearchHaystacks, fields);
    } catch (_) {
      haystacks = buildQueueSearchHaystacks(fields);
    }
    if (!mounted || generation != _indexGeneration) return;
    setState(() => _index = QueueSearchIndex.ready(haystacks));
  }

  bool _sameTracks(List<Track> previous, List<Track> next) {
    if (previous.length != next.length) return false;
    for (var i = 0; i < previous.length; i++) {
      if (!identical(previous[i], next[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.watch(queueItemsProvider);
    ref.watch(playbackStateProvider);
    final handler = ref.read(audioHandlerProvider);
    final q = handler.playbackQueue;
    final ordered = q.orderedTracks;

    if (widget.upcomingOnly) {
      return ListEntranceScope(
        child: _upcoming(
          context,
          l10n,
          q,
          ordered,
          onOpen: handler.skipToQueueItem,
          onRemove: handler.removeOrderedAt,
        ),
      );
    }
    if (ordered.isEmpty) {
      return Center(child: Text(l10n.queueEmpty));
    }

    _ensureIndex(ordered);
    final index = _index!;
    final query = _search.text;
    final queryActive = queueSearchHasQuery(query);
    final pending = index.pending(query);
    final indices = index.match(query);
    final shuffle =
        q.mode == PlayMode.shuffle || q.mode == PlayMode.smartShuffle;
    final allowReorder = !shuffle && !queryActive;

    Widget tileAt(int localIndex) {
      final absolute = indices[localIndex];
      return _queueTile(
        context: context,
        removeTooltip: l10n.queueRemove,
        track: ordered[absolute],
        absolute: absolute,
        current: absolute == q.cursor,
        upcomingOnly: false,
        allowReorder: allowReorder,
        localIndex: localIndex,
        onOpen: handler.skipToQueueItem,
        onRemove: handler.removeOrderedAt,
      );
    }

    final Widget list;
    if (indices.isEmpty && pending) {
      list = const Center(child: CircularProgressIndicator());
    } else if (indices.isEmpty) {
      list = Center(child: Text(l10n.queueSearchNoResult));
    } else if (allowReorder) {
      list = ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: indices.length,
        onReorderItem: (from, to) {
          if (!handler.reorder(indices[from], indices[to])) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.queueReorderDisabled)));
          }
        },
        itemBuilder: (_, i) => tileAt(i),
      );
    } else {
      list = ListView.builder(
        itemCount: indices.length,
        itemBuilder: (_, i) => tileAt(i),
      );
    }

    return ListEntranceScope(
      child: Column(
        children: [
          _searchBar(l10n),
          Expanded(child: list),
        ],
      ),
    );
  }

  Widget _searchBar(AppLocalizations l10n) {
    final embedded = widget.embedded;
    final height = embedded ? 48.0 : 56.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        embedded ? 12 : 16,
        embedded ? 4 : 8,
        embedded ? 12 : 16,
        4,
      ),
      child: SearchBar(
        key: const Key('queue-search'),
        controller: _search,
        hintText: l10n.queueSearchHint,
        constraints: BoxConstraints(
          minWidth: 0,
          minHeight: height,
          maxHeight: height,
        ),
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.search),
        ),
        trailing: [
          if (_index?.pending(_search.text) ?? false)
            const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_search.text.isNotEmpty)
            IconButton(
              tooltip: l10n.cancel,
              icon: const Icon(Icons.clear),
              onPressed: () {
                _search.clear();
                setState(() {});
              },
            ),
        ],
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _upcoming(
    BuildContext context,
    AppLocalizations l10n,
    PlaybackQueue q,
    List<Track> ordered, {
    required Future<void> Function(int index) onOpen,
    required Future<void> Function(int index) onRemove,
  }) {
    final start = q.cursor + 1;
    var tracks = start >= ordered.length
        ? const <Track>[]
        : ordered.sublist(start);
    final indexBase = start;
    final maxItems = widget.maxItems;
    if (maxItems != null && tracks.length > maxItems) {
      tracks = tracks.sublist(0, maxItems);
    }
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: widget.embedded ? 8 : 0),
          child: Text(l10n.queueEmpty),
        ),
      );
    }
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (_, localIndex) {
        final absolute = indexBase + localIndex;
        return _queueTile(
          context: context,
          removeTooltip: l10n.queueRemove,
          track: tracks[localIndex],
          absolute: absolute,
          current: false,
          upcomingOnly: true,
          allowReorder: false,
          localIndex: localIndex,
          onOpen: onOpen,
          onRemove: onRemove,
        );
      },
    );
  }
}

Widget _queueTile({
  required BuildContext context,
  required String removeTooltip,
  required Track track,
  required int absolute,
  required bool current,
  required bool upcomingOnly,
  required bool allowReorder,
  required int localIndex,
  required Future<void> Function(int index) onOpen,
  required Future<void> Function(int index) onRemove,
}) {
  final tile = ListEntrance(
    index: localIndex,
    child: ListTile(
      selected: current,
      leading: CoverImage(track.cover, size: 44),
      title: Text(
        track.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(track.displayArtist, maxLines: 1),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (current) const Icon(Icons.equalizer),
          if (!upcomingOnly)
            IconButton(
              tooltip: removeTooltip,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              onPressed: () => onRemove(absolute),
            ),
          if (allowReorder && !current)
            ReorderableDragStartListener(
              index: localIndex,
              child: const Icon(Icons.drag_handle),
            ),
        ],
      ),
      onTap: upcomingOnly ? null : () => onOpen(absolute),
    ),
  );
  if (upcomingOnly) return tile;
  return Dismissible(
    key: ValueKey('${track.bvid}_${track.cid}_$absolute'),
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
    onDismissed: (_) => onRemove(absolute),
    child: tile,
  );
}
