import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/adaptive/layout_settings.dart';
import '../../app/adaptive/split_view.dart';
import '../../app/adaptive/window_metrics.dart';
import '../../app/widgets/region_surface.dart';
import '../../l10n/l10n.dart';
import '../player/widgets/car_player.dart';
import '../player/widgets/mini_player.dart';
import '../player/widgets/now_playing_pane.dart';
import '../settings/update_prompt.dart';
import 'bottom_nav.dart';

/// 主界面外壳：按内容区宽高切换底栏、侧栏或主从栏。
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).matchedLocation;
    final settings = ref.watch(layoutSettingsProvider);
    return UpdatePrompt(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = WindowMetrics.fromSize(constraints.biggest);
          return WindowMetricsScope(
            metrics: metrics,
            child: settings.carLayout
                ? ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: const SafeArea(child: CarPlayer()),
                  )
                : _AdaptiveBody(path: path, metrics: metrics, child: child),
          );
        },
      ),
    );
  }
}

class _AdaptiveBody extends ConsumerWidget {
  const _AdaptiveBody({
    required this.path,
    required this.metrics,
    required this.child,
  });

  final String path;
  final WindowMetrics metrics;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget body;
    if (metrics.usesMasterDetail) {
      final ratio = ref.watch(layoutSettingsProvider).splitRatio;
      body = _withRail(
        SplitView(
          ratio: ratio,
          onRatioEnd: (next) =>
              ref.read(layoutSettingsProvider.notifier).setSplitRatio(next),
          first: child,
          second: const NowPlayingPane(),
        ),
      );
    } else if (metrics.usesRail) {
      body = _withRail(
        Column(
          children: [
            Expanded(child: child),
            const MiniPlayer(),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      );
    }
    return Scaffold(
      // 表面铺到系统栏下面。可点内容仍让出状态栏、刘海和手势区。
      // 有底栏时，底栏自己垫起系统导航栏，这里不再让出底部。
      body: _InsetContent(includeBottom: !metrics.usesBottomNav, child: body),
      bottomNavigationBar: metrics.usesBottomNav ? BottomNav(path: path) : null,
    );
  }

  Widget _withRail(Widget content) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: _railExtent),
          child: content,
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _railExtent,
          child: RegionSurface(
            key: const Key('nav-rail-surface'),
            edge: RegionEdge.trailing,
            child: _NavRail(path: path),
          ),
        ),
      ],
    );
  }
}

/// 只把内容推进安全区，父级表面仍盖住状态栏和系统导航栏。
class _InsetContent extends StatelessWidget {
  const _InsetContent({required this.includeBottom, required this.child});

  final bool includeBottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: includeBottom,
      child: includeBottom
          ? child
          : MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
    );
  }
}

const _railExtent = 80.0;

class _NavRail extends StatelessWidget {
  const _NavRail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final index = navIndexForPath(path);
    final items = [
      (Icons.search_outlined, Icons.search, l10n.navDiscover, null),
      (
        Icons.library_music_outlined,
        Icons.library_music,
        l10n.navLibrary,
        null,
      ),
      (
        Icons.settings_outlined,
        Icons.settings,
        l10n.navMine,
        const Key('nav-mine'),
      ),
    ];
    return ColoredBox(
      key: const Key('nav-rail'),
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i == 2) const Spacer(),
              NavTarget(
                key: items[i].$4,
                icon: items[i].$1,
                selectedIcon: items[i].$2,
                label: items[i].$3,
                selected: index == i,
                onTap: () => goNavDestination(context, i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
