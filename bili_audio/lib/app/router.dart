import 'package:go_router/go_router.dart';

import '../features/home/home_shell.dart';
import '../features/library/library_page.dart';
import '../features/library/playlist_detail_page.dart';
import '../features/login/login_page.dart';
import '../features/player/player_page.dart';
import '../features/queue/queue_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/cache_page.dart';
import '../features/settings/settings_page.dart';

/// 应用路由 (M0.4 / M6)
///
/// 底部导航三个 Tab 共用 [HomeShell] (迷你播放栏常驻);
/// 播放页、队列、歌单详情、缓存管理为全屏页面。
final appRouter = GoRouter(
  initialLocation: '/search',
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/search',
          pageBuilder: (_, _) => const NoTransitionPage(child: SearchPage()),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (_, _) => const NoTransitionPage(child: LibraryPage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (_, _) => const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
    GoRoute(path: '/player', builder: (_, _) => const PlayerPage()),
    GoRoute(path: '/queue', builder: (_, _) => const QueuePage()),
    GoRoute(
      path: '/playlist/:id',
      builder: (_, state) =>
          PlaylistDetailPage(id: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(path: '/cache', builder: (_, _) => const CachePage()),
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
  ],
);
