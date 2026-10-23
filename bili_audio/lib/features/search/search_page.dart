import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/adaptive/max_width_box.dart';
import '../../app/adaptive/player_shortcuts.dart';
import '../../app/adaptive/window_metrics.dart';
import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../core/utils/result.dart';
import '../../data/repositories/repositories.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../common/cover_image.dart';
import '../lyrics/lyrics_view.dart';
import '../player/player_actions.dart';
import 'search_controller.dart';

/// 搜索页 (M6.1)
///
/// 点击结果或播放按钮会用当前列表直接开播，不再等待整部视频详情。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _text.text = ref.read(searchControllerProvider).keyword;
    _scroll.addListener(() {
      final current = ref.read(searchControllerProvider);
      if (current.items.isEmpty) return;
      if (_scroll.position.extentAfter < 300) {
        ref.read(searchControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _searchFor(String keyword) {
    _text.text = keyword;
    ref.read(searchControllerProvider.notifier).search(keyword);
  }

  /// 从第一条能直接播放的结果开始，已加载列表作为队列。
  Future<void> _playAll(List<SearchHit> items) async {
    if (items.isEmpty) return;
    final start = items.indexWhere((hit) => trackFromSearchHit(hit) != null);
    final result = await ref
        .read(playerActionsProvider)
        .playSearchResults(items, start < 0 ? 0 : start);
    if (!mounted || result.isSuccess) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorText(context.l10n, result.errorOrNull))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final items = [
      for (final hit in state.items)
        if (hit.result.filtered != true && hit.result.duration <= 900) hit,
    ];

    final metrics = WindowMetricsScope.maybeOf(context);
    final master = metrics?.usesMasterDetail ?? false;
    final limitWidth =
        metrics != null && !master && metrics.width != WindowWidth.compact;

    Widget page = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SearchBar(
            focusNode: ref.watch(searchFocusNodeProvider),
            controller: _text,
            hintText: l10n.searchHint,
            // 栏高 56、图标 24、默认左内边距 8，图标中心落在 20，圆角端圆心在 28。
            leading: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.search),
            ),
            trailing: [
              if (_text.text.isNotEmpty)
                IconButton(
                  tooltip: l10n.cancel,
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchFor(''),
                ),
            ],
            onChanged: (v) {
              setState(() {});
              controller.onChanged(v);
            },
            onSubmitted: controller.search,
          ),
        ),
        Expanded(
          child: MotionSwap(
            swapKey: _searchBodyKey(state, items),
            child: switch (state) {
              SearchState(keyword: '') => _History(onTap: _searchFor),
              SearchState(items: [], loading: true) => const SkeletonList(),
              SearchState(items: [], error: final e?) => _ErrorView(
                error: e,
                onRetry: controller.retry,
              ),
              _
                  when items.isEmpty &&
                      !state.loading &&
                      state.error == null &&
                      !state.hasMore =>
                Center(child: Text(l10n.searchNoResult)),
              _ => Column(
                children: [
                  if (items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Row(
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l10n.playlistPlayAll),
                            onPressed: () => _playAll(items),
                          ),
                          const Spacer(),
                          Text(l10n.playlistTrackCount(items.length)),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListEntranceScope(
                      key: ValueKey(state.keyword),
                      child: ListView.builder(
                        controller: _scroll,
                        itemCount: items.length + 1,
                        itemBuilder: (context, i) => i < items.length
                            ? ListEntrance(
                                index: i,
                                child: _ResultTile(
                                  hit: items[i],
                                  index: i,
                                  hits: items,
                                ),
                              )
                            : _Footer(
                                state: state,
                                onRetry: controller.retry,
                                onLoadMore: items.isEmpty
                                    ? controller.loadMore
                                    : null,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ],
    );
    if (limitWidth) {
      page = MaxWidthBox(maxWidth: 840, child: page);
    }
    if (!master) return page;
    return Row(
      children: [
        Expanded(child: page),
        const VerticalDivider(width: 1),
        const Expanded(child: LyricsView(key: Key('lyrics-column'))),
      ],
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({
    required this.hit,
    required this.index,
    required this.hits,
  });

  final SearchHit hit;
  final int index;
  final List<SearchHit> hits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final r = hit.result;
    final artist = hit.cleaned.artist ?? r.author;
    final pageLabel = (r.totalPages ?? 1) > 1 && r.pageIndex != null
        ? 'P${r.pageIndex}/${r.totalPages}'
        : null;
    final actions = ref.read(playerActionsProvider);
    final playing = ref.watch(
      playbackStateProvider.select((state) => state.value?.playing ?? false),
    );
    final mediaId = ref.watch(
      mediaItemProvider.select((state) => state.value?.id),
    );
    final current = r.cid != null && mediaId == '${r.bvid}_${r.cid}';

    Future<void> run(
      Future<Result<void>> Function() action, {
      String? success,
    }) async {
      final result = await action();
      if (!context.mounted) return;
      final message = result.isFailure
          ? errorText(l10n, result.errorOrNull)
          : success;
      if (message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }

    Future<void> play() async {
      if (current) {
        final handler = ref.read(audioHandlerProvider);
        if (playing) {
          await handler.pause();
        } else {
          await handler.play();
        }
        return;
      }
      await run(() => actions.playSearchResults(hits, index));
    }

    final subtitle = [?pageLabel, r.author, l10n.playCount(r.play)].join(' · ');

    return ListTile(
      leading: Stack(
        children: [
          CoverImage(r.cover, size: 56),
          Positioned(
            right: 2,
            bottom: 2,
            child: _Badge(formatDuration(Duration(seconds: r.duration))),
          ),
        ],
      ),
      title: Text(
        '${hit.cleaned.name} - $artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: current
            ? TextStyle(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: play,
      onLongPress: () => _showMenu(context, ref, run),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: current && playing ? l10n.actionPause : l10n.actionPlay,
            icon: Icon(current && playing ? Icons.pause : Icons.play_arrow),
            color: current ? Theme.of(context).colorScheme.primary : null,
            onPressed: play,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onPressed: () => _showMenu(context, ref, run),
          ),
        ],
      ),
    );
  }

  void _showMenu(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(Future<Result<void>> Function(), {String? success})
    run,
  ) {
    final l10n = context.l10n;
    final actions = ref.read(playerActionsProvider);
    final pageLabel =
        (hit.result.totalPages ?? 1) > 1 && hit.result.pageIndex != null
        ? 'P${hit.result.pageIndex}/${hit.result.totalPages}'
        : null;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(l10n.actionPlayNext),
              onTap: () {
                Navigator.pop(sheet);
                run(
                  () => actions.enqueueSearchHit(hit, next: true),
                  success: l10n.addedToQueue,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(l10n.actionAddToQueue),
              onTap: () {
                Navigator.pop(sheet);
                run(
                  () => actions.enqueueSearchHit(hit, next: false),
                  success: l10n.addedToQueue,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(l10n.actionAddToPlaylist),
              onTap: () {
                Navigator.pop(sheet);
                showAddToPlaylistSheet(context, ref, () async {
                  final result = await actions.tracksForSearchHit(hit);
                  if (result.isFailure && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorText(l10n, result.errorOrNull)),
                      ),
                    );
                  }
                  return result.valueOrNull;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.originalTitle),
              subtitle: Text(
                [hit.result.cleanTitle, ?pageLabel, hit.result.bvid].join('\n'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    ),
  );
}

class _History extends ConsumerWidget {
  const _History({required this.onTap});

  final void Function(String) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(searchHistoryProvider).value ?? const [];
    final body = history.isEmpty
        ? Center(child: Text(l10n.searchEmpty))
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Row(
                children: [
                  Text(
                    l10n.searchHistory,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: ref.read(searchHistoryProvider.notifier).clear,
                    child: Text(l10n.searchClearHistory),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final k in history)
                    InputChip(
                      label: Text(k),
                      onPressed: () => onTap(k),
                      onDeleted: () =>
                          ref.read(searchHistoryProvider.notifier).remove(k),
                    ),
                ],
              ),
            ],
          );
    return MotionSwap(
      swapKey: history.isEmpty ? 'empty' : 'chips',
      child: body,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(errorText(l10n, error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry, this.onLoadMore});

  final SearchState state;
  final VoidCallback onRetry;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    final Object key;
    if (state.loading) {
      key = 'loading';
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.error != null) {
      key = 'error';
      body = TextButton(
        onPressed: onRetry,
        child: Text(errorText(context.l10n, state.error)),
      );
    } else if (onLoadMore != null && state.hasMore) {
      key = 'more';
      body = TextButton(
        onPressed: onLoadMore,
        child: Text(context.l10n.searchLoadMore),
      );
    } else {
      key = 'end';
      body = const SizedBox(height: 16);
    }
    return MotionSwap(swapKey: key, child: body);
  }
}

Object _searchBodyKey(SearchState state, List<SearchHit> items) {
  if (state.keyword.isEmpty) return 'history';
  if (state.items.isEmpty && state.loading) return 'loading';
  if (state.items.isEmpty && state.error != null) return 'error';
  if (items.isEmpty &&
      !state.loading &&
      state.error == null &&
      !state.hasMore) {
    return 'empty:${state.keyword}';
  }
  return 'results:${state.keyword}';
}
