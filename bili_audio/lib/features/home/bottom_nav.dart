import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';

/// 底部导航栏 (M6): 自动跳转 shell 路由
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final index = switch (path) {
      '/library' => 1,
      '/settings' => 2,
      _ => 0,
    };
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => context.go(switch (i) {
        1 => '/library',
        2 => '/settings',
        _ => '/search',
      }),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: l10n.navDiscover,
        ),
        NavigationDestination(
          icon: const Icon(Icons.library_music_outlined),
          selectedIcon: const Icon(Icons.library_music),
          label: l10n.navLibrary,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navMine,
        ),
      ],
    );
  }
}
