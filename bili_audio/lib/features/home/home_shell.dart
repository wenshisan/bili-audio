import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/adaptive/layout_settings.dart';
import '../../app/adaptive/split_view.dart';
import '../../app/adaptive/window_metrics.dart';
import '../../l10n/l10n.dart';
import '../player/widgets/car_player.dart';
import '../player/widgets/mini_player.dart';
import '../player/widgets/now_playing_pane.dart';
import 'bottom_nav.dart';

/// 主界面外壳：按内容区宽高切换底栏、侧栏或主从栏。
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).matchedLocation;
    final settings = ref.watch(layoutSettingsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = WindowMetrics.fromSize(constraints.biggest);
        return WindowMetricsScope(
          metrics: metrics,
          child: SafeArea(
            child: settings.carLayout
                ? const CarPlayer()
                : _AdaptiveBody(path: path, metrics: metrics, child: child),
          ),
        );
      },
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
    final rail = _NavRail(path: path, extended: metrics.usesMasterDetail);
    if (metrics.usesMasterDetail) {
      final ratio = ref.watch(layoutSettingsProvider).splitRatio;
      return Row(
        children: [
          rail,
          Expanded(
            child: SplitView(
              ratio: ratio,
              onRatioEnd: (next) => ref
                  .read(layoutSettingsProvider.notifier)
                  .setSplitRatio(next),
              first: child,
              second: const NowPlayingPane(),
            ),
          ),
        ],
      );
    }
    if (metrics.usesRail) {
      return Row(
        children: [
          rail,
          Expanded(
            child: Column(
              children: [
                Expanded(child: child),
                const MiniPlayer(),
              ],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNav(path: path),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({required this.path, required this.extended});

  final String path;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      (Icons.search_outlined, Icons.search, l10n.navDiscover),
      (Icons.library_music_outlined, Icons.library_music, l10n.navLibrary),
      (Icons.settings_outlined, Icons.settings, l10n.navMine),
    ];
    return NavigationRail(
      extended: extended,
      selectedIndex: navIndexForPath(path),
      onDestinationSelected: (i) => goNavDestination(context, i),
      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      destinations: [
        for (final (icon, selected, label) in destinations)
          NavigationRailDestination(
            icon: Icon(icon),
            selectedIcon: Icon(selected),
            label: Text(label),
          ),
      ],
    );
  }
}
