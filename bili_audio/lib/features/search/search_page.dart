import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../data/repositories/repositories.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../common/cover_image.dart';
import '../player/player_actions.dart';
import 'search_controller.dart';

/// 搜索页 (M6.1)
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final items = [
      for (final hit in state.items)
        if (hit.result.filtered != true && hit.result.duration <= 900) hit,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SearchBar(
            controller: _text,
            hintText: l10n.searchHint,
            leading: const Icon(Icons.search),
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
          child: switch (state) {
            SearchState(keyword: '') => _History(onTap: _searchFor),
            SearchState(items: [], loading: true) => const _Skeleton(),
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
            _ => ListView.builder(
              controller: _scroll,
              itemCount: items.length + 1,
              itemBuilder: (context, i) => i < items.length
                  ? _ResultTile(items[i])
                  : _Footer(
                      state: state,
                      onRetry: controller.retry,
                      onLoadMore: items.isEmpty ? controller.loadMore : null,
                    ),
            ),
          },
        ),
      ],
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile(this.hit);

  final SearchHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final r = hit.result;
    final artist = hit.cleaned.artist ?? r.author;
    final pageLabel = (r.totalPages ?? 1) > 1 && r.pageIndex != null
        ? 'P${r.pageIndex}/${r.totalPages}'
        : null;
    final actions = ref.read(playerActionsProvider);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }

    final subtitle = [
      ?pageLabel,
      r.author,
      l10n.playCount(r.play),
    ].join(' · ');

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
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => run(() => actions.playVideo(r.bvid, cid: r.cid)),
      onLongPress: () => _showMenu(context, ref, run),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        onPressed: () => _showMenu(context, ref, run),
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
    final bvid = hit.result.bvid;
    final cid = hit.result.cid;
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
                  () => actions.playNext(bvid, cid: cid),
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
                  () => actions.addToQueue(bvid, cid: cid),
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
                  final result = await actions.tracksOf(bvid, cid: cid);
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
                [
                  hit.result.cleanTitle,
                  ?pageLabel,
                  bvid,
                ].join('\n'),
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
    if (history.isEmpty) return Center(child: Text(l10n.searchEmpty));
    return ListView(
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
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w) => Container(
      width: w,
      height: 12,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, _) => ListTile(
        leading: Container(width: 56, height: 56, color: color),
        title: bar(180),
        subtitle: bar(100),
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
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return TextButton(
        onPressed: onRetry,
        child: Text(errorText(context.l10n, state.error)),
      );
    }
    if (onLoadMore != null && state.hasMore) {
      return TextButton(
        onPressed: onLoadMore,
        child: Text(context.l10n.searchLoadMore),
      );
    }
    return const SizedBox(height: 16);
  }
}
