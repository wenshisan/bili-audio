import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../data/db/daos/playlists_dao.dart';
import '../../domain/entities/audio_track.dart' as domain;
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../common/cover_image.dart';
import '../player/player_actions.dart';

final playlistProvider = StreamProvider.family<Playlist?, int>(
  (ref, id) => ref.watch(databaseProvider).playlistsDao.watchPlaylist(id),
);

final playlistTracksProvider = StreamProvider.family<List<domain.Track>, int>(
  (ref, id) => ref
      .watch(databaseProvider)
      .playlistsDao
      .watchPlaylistTracks(id)
      .map((rows) => rows.map(trackFromRow).toList()),
);

/// 歌单详情 (M6.4): 播放全部 / 随机, 拖拽排序, 滑动删除
class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({
    super.key,
    required this.id,
    this.embedded = false,
    this.onDeleted,
  });

  final int id;
  final bool embedded;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playlist = ref.watch(playlistProvider(id)).value;
    final tracksAsync = ref.watch(playlistTracksProvider(id));
    final dao = ref.read(databaseProvider).playlistsDao;
    final actions = ref.read(playerActionsProvider);
    final readonly = playlist?.isReadonly ?? false;

    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : null,
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        backgroundColor: embedded ? Colors.transparent : null,
        surfaceTintColor: embedded ? Colors.transparent : null,
        scrolledUnderElevation: embedded ? 0 : null,
        elevation: embedded ? 0 : null,
        title: MotionSwap(
          swapKey: playlist?.name ?? '',
          child: Text(playlist?.name ?? ''),
        ),
        actions: [
          if (playlist != null && !readonly)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'rename') {
                  final name = await showPlaylistNameDialog(
                    context,
                    initial: playlist.name,
                    title: l10n.libraryRename,
                  );
                  if (name != null) {
                    await dao.updatePlaylist(
                      id,
                      PlaylistsCompanion(name: Value(name)),
                    );
                  }
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      content: Text(l10n.libraryDeleteConfirm(playlist.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await dao.deletePlaylist(id);
                    if (!context.mounted) return;
                    if (embedded) {
                      onDeleted?.call();
                    } else {
                      context.pop();
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: Text(l10n.libraryRename)),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
            ),
        ],
      ),
      body: MotionSwap(
        swapKey: tracksAsync.when(
          loading: () => 'loading',
          error: (_, _) => 'error',
          data: (list) => list.isEmpty ? 'empty' : 'ready',
        ),
        child: tracksAsync.when(
          loading: () => const SkeletonList(leading: 44),
          error: (e, _) => Center(child: Text(errorText(l10n, e))),
          data: (loaded) => loaded.isEmpty
              ? Center(child: Text(l10n.playlistEmpty))
              : _TrackList(
                  id: id,
                  tracks: loaded,
                  readonly: readonly,
                  actions: actions,
                  dao: dao,
                ),
        ),
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({
    required this.id,
    required this.tracks,
    required this.readonly,
    required this.actions,
    required this.dao,
  });

  final int id;
  final List<domain.Track> tracks;
  final bool readonly;
  final PlayerActions actions;
  final PlaylistsDao dao;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.playlistPlayAll),
                onPressed: () => actions.playList(tracks),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.shuffle),
                label: Text(l10n.playlistShuffle),
                onPressed: () => actions.playList(tracks, shuffle: true),
              ),
              const Spacer(),
              Text(l10n.playlistTrackCount(tracks.length)),
            ],
          ),
        ),
        Expanded(
          child: ListEntranceScope(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: tracks.length,
              onReorderItem: readonly
                  ? (_, _) {}
                  : (from, to) {
                      final order = [...tracks];
                      order.insert(to, order.removeAt(from));
                      dao.reorderTracks(
                        playlistId: id,
                        newOrder: [
                          for (final t in order) (bvid: t.bvid, cid: t.cid),
                        ],
                      );
                    },
              itemBuilder: (context, i) {
                final t = tracks[i];
                return Dismissible(
                  key: ValueKey('${t.bvid}_${t.cid}'),
                  direction: readonly
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
                  background: ColoredBox(
                    color: Theme.of(context).colorScheme.errorContainer,
                  ),
                  onDismissed: (_) => dao.removeTrackFromPlaylist(
                    playlistId: id,
                    bvid: t.bvid,
                    cid: t.cid,
                  ),
                  child: ListEntrance(
                    index: i,
                    child: ListTile(
                      leading: CoverImage(t.cover, size: 44),
                      title: Text(
                        t.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(t.displayArtist, maxLines: 1),
                      trailing: readonly
                          ? null
                          : ReorderableDragStartListener(
                              index: i,
                              child: const Icon(Icons.drag_handle),
                            ),
                      onTap: () => actions.playList(tracks, index: i),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
