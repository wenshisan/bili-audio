import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../history/history_view.dart';

/// 歌单库 (M6.4): 本地歌单 / 播放历史
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [
            Tab(text: l10n.navLibrary),
            Tab(text: l10n.historyTitle),
          ]),
          const Expanded(
            child: TabBarView(children: [_PlaylistGrid(), HistoryView()]),
          ),
        ],
      ),
    );
  }
}

class _PlaylistGrid extends ConsumerStatefulWidget {
  const _PlaylistGrid();

  @override
  ConsumerState<_PlaylistGrid> createState() => _PlaylistGridState();
}

class _PlaylistGridState extends ConsumerState<_PlaylistGrid> {
  var grid = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final playlists = ref.watch(playlistsWithCountProvider);

    Future<void> create() async {
      final name = await showPlaylistNameDialog(context);
      if (name == null) return;
      await ref.read(databaseProvider).playlistsDao.createPlaylist(
            PlaylistsCompanion.insert(name: name, source: const Value('local')),
          );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_playlist',
        icon: const Icon(Icons.add),
        label: Text(l10n.libraryCreate),
        onPressed: create,
      ),
      body: playlists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorText(l10n, e))),
        data: (list) {
          if (list.isEmpty) return Center(child: Text(l10n.libraryEmpty));
          final header = Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: grid ? 'List' : 'Grid',
              icon: Icon(grid ? Icons.view_list : Icons.grid_view),
              onPressed: () => setState(() => grid = !grid),
            ),
          );
          final cards = [
            for (final p in list)
              _PlaylistCard(playlist: p.playlist, count: p.count, grid: grid),
          ];
          return grid
              ? CustomScrollView(slivers: [
                  SliverToBoxAdapter(child: header),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    sliver: SliverGrid.extent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: cards,
                    ),
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [header, ...cards],
                );
        },
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.count,
    required this.grid,
  });

  final Playlist playlist;
  final int count;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    void open() => context.push('/playlist/${playlist.id}');
    final icon = Icon(Icons.queue_music, color: scheme.onPrimaryContainer);

    if (!grid) {
      return ListTile(
        leading: CircleAvatar(backgroundColor: scheme.primaryContainer, child: icon),
        title: Text(playlist.name),
        subtitle: Text(l10n.playlistTrackCount(count)),
        onTap: open,
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ColoredBox(
                color: scheme.primaryContainer,
                child: Center(child: icon),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(l10n.playlistTrackCount(count),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
