import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/adaptive/max_width_box.dart';
import '../../app/adaptive/player_shortcuts.dart';
import '../../app/adaptive/window_metrics.dart';
import '../../app/widgets/region_surface.dart';
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

/// 发现页 (M6.1)
///
/// 还没搜索时展示音乐区推荐，可在排行榜分区和年代之间切换。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  String? _autoLoadKey;

  @override
  void initState() {
    super.initState();
    _text.text = ref.read(searchControllerProvider).keyword;
    // 等这一帧建完再改 provider，避免在 initState 里通知监听者。
    Future(() {
      if (!mounted) return;
      unawaited(ref.read(searchControllerProvider.notifier).loadDaily());
    });
    _scroll.addListener(_maybeLoadMore);
  }

  /// 列表已经靠近底部时继续请求下一页。短列表铺不满一屏时也会补一页。
  ///
  /// 同一位置、同一批结果只请求一次，避免滤空的一页把接口打满。
  void _maybeLoadMore() {
    if (!mounted || !_scroll.hasClients) return;
    final current = ref.read(searchControllerProvider);
    if (current.loading || !current.hasMore || current.items.isEmpty) return;
    final position = _scroll.position;
    if (position.extentAfter >= 300) {
      _autoLoadKey = null;
      return;
    }
    final key =
        '${current.keyword}|${current.chart.name}|${current.items.length}|${position.pixels.toStringAsFixed(0)}';
    if (_autoLoadKey == key) return;
    _autoLoadKey = key;
    ref.read(searchControllerProvider.notifier).loadMore();
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

  void _selectChart(DiscoverTab tab) {
    if (ref.read(searchControllerProvider).chart == tab) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    unawaited(ref.read(searchControllerProvider.notifier).selectChart(tab));
  }

  void _selectGroup(DiscoverGroup group) {
    final current = ref.read(searchControllerProvider).chart;
    if (current.group == group) return;
    _selectChart(ref.read(searchControllerProvider.notifier).preferred(group));
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
    if (state.hasMore && !state.loading && state.items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeLoadMore();
      });
    }

    final metrics = WindowMetricsScope.maybeOf(context);
    final master = metrics?.usesMasterDetail ?? false;
    final limitWidth =
        metrics != null && !master && metrics.width != WindowWidth.compact;

    Widget page = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  // 默认最大宽度 800，宽于内容区时会比列表窄一截。
                  constraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 56,
                    maxHeight: 56,
                  ),
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
              if (state.keyword.isNotEmpty && items.isNotEmpty) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.playlistPlayAll),
                    onPressed: () => _playAll(items),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              if (state.keyword.isEmpty) _HistoryStrip(onTap: _searchFor),
              if (state.keyword.isEmpty)
                _ChartTabs(
                  selected: state.chart,
                  showPlay: items.isNotEmpty,
                  count: items.length,
                  onSelected: _selectChart,
                  onSelectGroup: _selectGroup,
                  onPlayAll: () => _playAll(items),
                ),
              Expanded(
                child: MotionSwap(
                  swapKey: _searchBodyKey(state, items),
                  child: switch (state) {
                    SearchState(items: [], loading: true) =>
                      const SkeletonList(),
                    SearchState(items: [], error: final e?) => _ErrorView(
                      error: e,
                      onRetry: controller.retry,
                    ),
                    _
                        when items.isEmpty &&
                            !state.loading &&
                            state.error == null &&
                            !state.hasMore =>
                      Center(
                        child: Text(
                          state.keyword.isEmpty
                              ? l10n.discoverDailyEmpty
                              : l10n.searchNoResult,
                        ),
                      ),
                    _ => Column(
                      children: [
                        if (items.isNotEmpty && state.keyword.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Row(
                              children: [
                                const Spacer(),
                                Text(l10n.playlistTrackCount(items.length)),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListEntranceScope(
                            key: ValueKey(
                              '${state.keyword}:${state.chart.name}',
                            ),
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
        const Expanded(
          child: RegionSurface(
            edge: RegionEdge.leading,
            child: LyricsView(key: Key('lyrics-column')),
          ),
        ),
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

class _HistoryStrip extends ConsumerWidget {
  const _HistoryStrip({required this.onTap});

  final void Function(String) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(searchHistoryProvider).value ?? const [];
    if (history.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
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
  if (state.items.isEmpty && state.loading) return 'loading';
  if (state.items.isEmpty && state.error != null) return 'error';
  if (items.isEmpty &&
      !state.loading &&
      state.error == null &&
      !state.hasMore) {
    return state.keyword.isEmpty ? 'daily-empty' : 'empty:${state.keyword}';
  }
  return state.keyword.isEmpty
      ? 'daily:${state.chart.name}'
      : 'results:${state.keyword}';
}

String _discoverGroupLabel(AppLocalizations l10n, DiscoverGroup group) =>
    switch (group) {
      DiscoverGroup.ranking => l10n.discoverGroupRanking,
      DiscoverGroup.era => l10n.discoverGroupEra,
    };

String _discoverTabLabel(AppLocalizations l10n, DiscoverTab tab) =>
    switch (tab) {
      DiscoverTab.heat => l10n.discoverTabHeat,
      DiscoverTab.rating => l10n.discoverTabRating,
      DiscoverTab.original => l10n.discoverTabOriginal,
      DiscoverTab.cover => l10n.discoverTabCover,
      DiscoverTab.mv => l10n.discoverTabMv,
      DiscoverTab.live => l10n.discoverTabLive,
      DiscoverTab.perform => l10n.discoverTabPerform,
      DiscoverTab.vocaloid => l10n.discoverTabVocaloid,
      DiscoverTab.ai => l10n.discoverTabAi,
      DiscoverTab.y2020 => l10n.discoverTabY2020,
      DiscoverTab.y2010 => l10n.discoverTabY2010,
      DiscoverTab.y2000 => l10n.discoverTabY2000,
      DiscoverTab.y1990 => l10n.discoverTabY1990,
      DiscoverTab.y1980 => l10n.discoverTabY1980,
      DiscoverTab.y1970 => l10n.discoverTabY1970,
    };

class _ChartTabs extends StatelessWidget {
  const _ChartTabs({
    required this.selected,
    required this.showPlay,
    required this.count,
    required this.onSelected,
    required this.onSelectGroup,
    required this.onPlayAll,
  });

  final DiscoverTab selected;
  final bool showPlay;
  final int count;
  final ValueChanged<DiscoverTab> onSelected;
  final ValueChanged<DiscoverGroup> onSelectGroup;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = selected.group == DiscoverGroup.ranking
        ? DiscoverTab.ranking
        : DiscoverTab.eras;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final group in DiscoverGroup.values) ...[
                ChoiceChip(
                  label: Text(_discoverGroupLabel(l10n, group)),
                  selected: group == selected.group,
                  onSelected: (_) => onSelectGroup(group),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 4),
          _FoldableChips(
            key: ValueKey(selected.group),
            selectedIndex: tabs.indexOf(selected),
            children: [
              for (final tab in tabs)
                ChoiceChip(
                  label: Text(_discoverTabLabel(l10n, tab)),
                  selected: tab == selected,
                  onSelected: (_) => onSelected(tab),
                ),
            ],
          ),
          // 播放全部独占一行，避免和分类抢同一行的宽度。
          if (showPlay) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.playlistPlayAll),
                  onPressed: onPlayAll,
                ),
                const Spacer(),
                Text(l10n.playlistTrackCount(count)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 分类芯片按可用宽度平铺。一行放得下就全部显示；放不下时先收成一行，
/// 末尾给出展开，展开后再按行铺开。
class _FoldableChips extends StatefulWidget {
  const _FoldableChips({
    super.key,
    required this.selectedIndex,
    required this.children,
  });

  final int selectedIndex;
  final List<Widget> children;

  @override
  State<_FoldableChips> createState() => _FoldableChipsState();
}

class _FoldableChipsState extends State<_FoldableChips> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: Motion.reduced(context) ? Duration.zero : Motion.swap,
      curve: Curves.easeOutCubic,
      child: _ChipFlow(
        expanded: _expanded,
        selectedIndex: widget.selectedIndex,
        spacing: 8,
        runSpacing: 4,
        children: [
          ...widget.children,
          IconButton(
            tooltip: _expanded
                ? material.expandedIconTapHint
                : material.collapsedIconTapHint,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(36, 36),
              fixedSize: const Size(36, 36),
              padding: EdgeInsets.zero,
              iconSize: 22,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ),
        ],
      ),
    );
  }
}

class _ChipFlow extends MultiChildRenderObjectWidget {
  const _ChipFlow({
    required this.expanded,
    required this.selectedIndex,
    required this.spacing,
    required this.runSpacing,
    required super.children,
  });

  final bool expanded;
  final int selectedIndex;
  final double spacing;
  final double runSpacing;

  @override
  MultiChildRenderObjectElement createElement() => _ChipFlowElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderChipFlow(
      expanded: expanded,
      selectedIndex: selectedIndex,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderChipFlow renderObject) {
    renderObject
      ..expanded = expanded
      ..selectedIndex = selectedIndex
      ..spacing = spacing
      ..runSpacing = runSpacing;
  }
}

class _ChipFlowElement extends MultiChildRenderObjectElement {
  _ChipFlowElement(super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    final flow = renderObject as _RenderChipFlow;
    for (final child in children) {
      final object = child.renderObject;
      if (object is RenderBox && flow.hides(object)) continue;
      visitor(child);
    }
  }
}

class _ChipFlowParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderChipFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ChipFlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ChipFlowParentData> {
  _RenderChipFlow({
    required bool expanded,
    required int selectedIndex,
    required double spacing,
    required double runSpacing,
  }) : _expanded = expanded,
       _selectedIndex = selectedIndex,
       _spacing = spacing,
       _runSpacing = runSpacing;

  bool _expanded;
  int _selectedIndex;
  double _spacing;
  double _runSpacing;
  final Set<RenderBox> _hidden = <RenderBox>{};

  bool hides(RenderBox child) => _hidden.contains(child);

  set expanded(bool value) {
    if (_expanded == value) return;
    _expanded = value;
    markNeedsLayout();
  }

  set selectedIndex(int value) {
    if (_selectedIndex == value) return;
    _selectedIndex = value;
    markNeedsLayout();
  }

  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ChipFlowParentData) {
      child.parentData = _ChipFlowParentData();
    }
  }

  List<RenderBox> get _boxes {
    final list = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      list.add(child);
      child = childAfter(child);
    }
    return list;
  }

  double _rowWidth(List<RenderBox> row) {
    var width = 0.0;
    for (var i = 0; i < row.length; i++) {
      if (i > 0) width += _spacing;
      width += row[i].size.width;
    }
    return width;
  }

  void _place(RenderBox child, Offset offset) {
    final data = child.parentData! as _ChipFlowParentData;
    data.offset = offset;
  }

  double _placeRow(List<RenderBox> row, double y) {
    var rowHeight = 0.0;
    for (final child in row) {
      rowHeight = math.max(rowHeight, child.size.height);
    }
    var x = 0.0;
    for (final child in row) {
      _place(child, Offset(x, y + (rowHeight - child.size.height) / 2));
      x += child.size.width + _spacing;
    }
    return rowHeight;
  }

  @override
  void performLayout() {
    final boxes = _boxes;
    final maxWidth = constraints.maxWidth;
    final childConstraints = maxWidth.isFinite
        ? BoxConstraints(maxWidth: maxWidth)
        : const BoxConstraints();
    for (final child in boxes) {
      child.layout(childConstraints, parentUsesSize: true);
    }
    _hidden.clear();
    if (boxes.isEmpty) {
      size = constraints.smallest;
      return;
    }

    final toggle = boxes.last;
    final chips = boxes.sublist(0, boxes.length - 1);
    final widthLimit = maxWidth.isFinite ? maxWidth : double.infinity;

    var oneLine = 0.0;
    var fits = true;
    for (var i = 0; i < chips.length; i++) {
      final next = i == 0
          ? chips[i].size.width
          : oneLine + _spacing + chips[i].size.width;
      if (next > widthLimit) {
        fits = false;
        break;
      }
      oneLine = next;
    }

    if (chips.isEmpty || fits) {
      _hidden.add(toggle);
      final height = chips.isEmpty ? 0.0 : _placeRow(chips, 0);
      for (final child in _hidden) {
        _place(child, Offset.zero);
      }
      final width = maxWidth.isFinite ? maxWidth : oneLine;
      size = constraints.constrain(Size(width, height));
      markNeedsSemanticsUpdate();
      return;
    }

    if (!_expanded) {
      final room = math.max(0.0, widthLimit - _spacing - toggle.size.width);
      final visible = <RenderBox>[];
      var used = 0.0;
      for (final chip in chips) {
        final next = visible.isEmpty
            ? chip.size.width
            : used + _spacing + chip.size.width;
        if (visible.isNotEmpty && next > room) break;
        visible.add(chip);
        used = next;
      }
      final selected = _selectedIndex;
      if (selected >= 0 && selected < chips.length) {
        final chip = chips[selected];
        if (!visible.contains(chip)) {
          while (visible.isNotEmpty &&
              _rowWidth(visible) + _spacing + chip.size.width > room) {
            visible.removeLast();
          }
          visible.add(chip);
        }
      }
      for (final chip in chips) {
        if (!visible.contains(chip)) _hidden.add(chip);
      }
      final row = <RenderBox>[...visible, toggle];
      final height = _placeRow(row, 0);
      final toggleOffset = toggle.parentData! as _ChipFlowParentData;
      final pinned = math.min(
        toggleOffset.offset.dx,
        math.max(0.0, widthLimit - toggle.size.width),
      );
      _place(toggle, Offset(pinned, toggleOffset.offset.dy));
      for (final child in _hidden) {
        _place(child, Offset.zero);
      }
      size = constraints.constrain(Size(widthLimit, height));
      markNeedsSemanticsUpdate();
      return;
    }

    final rows = <List<RenderBox>>[<RenderBox>[]];
    var used = 0.0;
    void add(RenderBox item) {
      final itemWidth = item.size.width;
      if (rows.last.isNotEmpty && used + _spacing + itemWidth > widthLimit) {
        rows.add(<RenderBox>[]);
        used = 0;
      }
      final row = rows.last;
      used = row.isEmpty ? itemWidth : used + _spacing + itemWidth;
      row.add(item);
    }

    for (final chip in chips) {
      add(chip);
    }
    add(toggle);
    var y = 0.0;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].isEmpty) continue;
      y += _placeRow(rows[i], y);
      if (i != rows.length - 1) y += _runSpacing;
    }
    size = constraints.constrain(Size(widthLimit, y));
    markNeedsSemanticsUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, (
      context,
      offset,
    ) {
      var child = firstChild;
      while (child != null) {
        if (!_hidden.contains(child)) {
          final data = child.parentData! as _ChipFlowParentData;
          context.paintChild(child, offset + data.offset);
        }
        child = childAfter(child);
      }
    });
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final current = child;
      if (!_hidden.contains(current)) {
        final data = current.parentData! as _ChipFlowParentData;
        final hit = result.addWithPaintOffset(
          offset: data.offset,
          position: position,
          hitTest: (result, transformed) {
            return current.hitTest(result, position: transformed);
          },
        );
        if (hit) return true;
      }
      child = childBefore(current);
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      if (!_hidden.contains(child)) visitor(child);
      child = childAfter(child);
    }
  }
}
