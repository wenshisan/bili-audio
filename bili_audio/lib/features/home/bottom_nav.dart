import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/widgets/region_surface.dart';
import '../../l10n/l10n.dart';

/// 底栏与侧栏共用的选中项。
int navIndexForPath(String path) => switch (path) {
  '/library' => 1,
  '/settings' => 2,
  _ => 0,
};

void goNavDestination(BuildContext context, int index) =>
    context.go(switch (index) {
      1 => '/library',
      2 => '/settings',
      _ => '/search',
    });

/// 底部导航栏 (M6): 自动跳转 shell 路由。
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final index = navIndexForPath(path);
    final items = [
      (Icons.search_outlined, Icons.search, l10n.navDiscover),
      (Icons.library_music_outlined, Icons.library_music, l10n.navLibrary),
      (Icons.settings_outlined, Icons.settings, l10n.navMine),
    ];
    return RegionSurface(
      key: const Key('bottom-nav'),
      edge: RegionEdge.top,
      child: Material(
        color: scheme.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Center(
                    child: NavTarget(
                      icon: items[i].$1,
                      selectedIcon: items[i].$2,
                      label: items[i].$3,
                      selected: index == i,
                      onTap: () => goNavDestination(context, i),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 一个导航项：图标和文字共用同一块悬停、按下和选中区域。
class NavTarget extends StatelessWidget {
  const NavTarget({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    final overlay = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Material(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          borderRadius: _radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: _radius,
            hoverColor: overlay.withValues(alpha: 0.08),
            highlightColor: overlay.withValues(alpha: 0.10),
            splashColor: overlay.withValues(alpha: 0.12),
            focusColor: overlay.withValues(alpha: 0.10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? selectedIcon : icon, color: foreground),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? foreground : scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
