import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../player/widgets/mini_player.dart';
import 'bottom_nav.dart';

/// 主界面外壳 (M6): 底部导航 + 内容 + 迷你播放器
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: Column(children: [Expanded(child: child), const MiniPlayer()]),
      bottomNavigationBar: BottomNav(path: path),
    );
  }
}
