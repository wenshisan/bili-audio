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
            child: SafeArea(
              child: settings.carLayout
                  ? const CarPlayer()
                  : _AdaptiveBody(path: path, metrics: metrics, child: child),
            ),
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
      body: body,
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

const _railExtent = 80.0;

class _NavRail extends StatelessWidget {
  const _NavRail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final index = navIndexForPath(path);
    final onMine = index == 2;
    final destinations = [
      (Icons.search_outlined, Icons.search, l10n.navDiscover),
      (Icons.library_music_outlined, Icons.library_music, l10n.navLibrary),
    ];
    return NavigationRail(
      backgroundColor: scheme.surface,
      selectedIndex: onMine ? null : index,
      onDestinationSelected: (i) => goNavDestination(context, i),
      labelType: NavigationRailLabelType.all,
      trailingAtBottom: true,
      trailing: _RailMineButton(
        selected: onMine,
        label: l10n.navMine,
        onTap: () => goNavDestination(context, 2),
      ),
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

/// 侧栏底部的「我的」。与音乐目的地分开，固定在栏底。
class _RailMineButton extends StatelessWidget {
  const _RailMineButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  static const double _indicatorWidth = 56;
  static const double _indicatorHeight = 32;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final indicator = SizedBox(
      width: _indicatorWidth,
      height: _indicatorHeight,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: selected ? scheme.secondaryContainer : const Color(0x00000000),
          shape: const StadiumBorder(),
        ),
        child: Icon(
          selected ? Icons.settings : Icons.settings_outlined,
          color: selected
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    );
    final text = Text(
      label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: scheme.onSurface),
      overflow: TextOverflow.fade,
      softWrap: false,
    );
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 4),
          text,
          const SizedBox(height: 12),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: _railExtent,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            key: const Key('nav-mine'),
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: body,
          ),
        ),
      ),
    );
  }
}
