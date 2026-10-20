import 'package:go_router/go_router.dart';

import '../features/home_page.dart';

/// 应用路由配置 (dev-tasks M0.4)。
///
/// 当前仅占位首页，后续在 M6 补充完整路由:
/// /search, /player, /lyrics, /queue, /playlist/:id, /settings/*
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    // TODO: M6 补充完整路由表
  ],
);
