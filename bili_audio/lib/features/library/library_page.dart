import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/adaptive/window_metrics.dart';
import '../../app/motion/motion.dart';
import '../../app/widgets/region_surface.dart';
import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../history/history_view.dart';
import 'playlist_detail_page.dart';

/// 歌单库 (M6.4): 本地歌单 / 播放历史
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final master =
        WindowMetricsScope.maybeOf(context)?.usesMasterDetail ?? false;
    final list = DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            dividerHeight: 0,
            tabs: [
              Tab(text: l10n.navLibrary),
              Tab(text: l10n.historyTitle),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PlaylistGrid(
                  onOpen: master
                      ? (id) => setState(() => _selected = id)
                      : null,
                ),
                const HistoryView(),
              ],
            ),
          ),
        ],
      ),
    );
    if (!master) return list;
    return Row(
      children: [
        Expanded(child: list),
        Expanded(
          child: RegionSurface(
            shadow: RegionShadow.leading,
            child: MotionSwap(
              swapKey: _selected ?? 'none',
              child: _selected == null
                  ? Center(child: Text(l10n.libraryEmpty))
                  : PlaylistDetailPage(
                      id: _selected!,
                      embedded: true,
                      onDeleted: () => setState(() => _selected = null),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaylistGrid extends ConsumerStatefulWidget {
  const _PlaylistGrid({this.onOpen});

  final ValueChanged<int>? onOpen;

  @override
  ConsumerState<_PlaylistGrid> createState() => _PlaylistGridState();
}

class _PlaylistGridState extends ConsumerState<_PlaylistGrid> {
  bool? gridOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final playlists = ref.watch(playlistsWithCountProvider);
    final width = WindowMetricsScope.maybeOf(context)?.width;
    final grid =
        gridOverride ?? (width != null && width != WindowWidth.compact);

    Future<void> create() async {
      final name = await showPlaylistNameDialog(context);
      if (name == null) return;
      await ref
          .read(databaseProvider)
          .playlistsDao
          .createPlaylist(
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
      body: MotionSwap(
        swapKey: playlists.when(
          loading: () => 'loading',
          error: (_, _) => 'error',
          data: (list) => list.isEmpty ? 'empty' : 'ready',
        ),
        child: playlists.when(
          loading: () => const SkeletonList(leading: 44),
          error: (e, _) => Center(child: Text(errorText(l10n, e))),
          data: (list) {
            if (list.isEmpty) return Center(child: Text(l10n.libraryEmpty));
            final header = Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: grid ? 'List' : 'Grid',
                icon: Icon(grid ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => gridOverride = !grid),
              ),
            );
            final cards = [
              for (var i = 0; i < list.length; i++)
                ListEntrance(
                  index: i,
                  child: _PlaylistCard(
                    playlist: list[i].playlist,
                    count: list[i].count,
                    grid: grid,
                    onOpen: widget.onOpen,
                  ),
                ),
            ];
            final view = grid
                ? GridView.extent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.8,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: cards,
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    children: cards,
                  );
            return ListEntranceScope(
              child: Column(
                children: [
                  header,
                  Expanded(
                    child: MotionSwap(
                      swapKey: grid ? 'grid' : 'list',
                      child: view,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.count,
    required this.grid,
    this.onOpen,
  });

  final Playlist playlist;
  final int count;
  final bool grid;
  final ValueChanged<int>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    void open() {
      final select = onOpen;
      if (select != null) {
        select(playlist.id);
        return;
      }
      context.push('/playlist/${playlist.id}');
    }

    final icon = Icon(Icons.queue_music, color: scheme.onPrimaryContainer);

    if (!grid) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: icon,
        ),
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
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l10n.playlistTrackCount(count),
                    style: Theme.of(context).textTheme.bodySmall,
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
