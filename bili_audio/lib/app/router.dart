import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/logging/app_logger.dart';
import '../features/home/bottom_nav.dart';
import '../features/home/home_shell.dart';
import '../l10n/l10n.dart';
import 'motion/motion.dart';
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
  observers: [NavLogObserver()],
  errorBuilder: (context, state) => NavErrorPage(
    uri: state.uri,
    message: state.error?.message ?? 'unknown route',
  ),
  routes: [
    ShellRoute(
      // 壳层本身不位移，分页动画在子路由上，全屏页盖上来时底下保持不动。
      pageBuilder: (context, state, child) => NoTransitionPage(
        key: state.pageKey,
        child: HomeShell(child: child),
      ),
      routes: [
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => shellTabPage(
            context: context,
            pageKey: state.pageKey,
            path: state.uri.path,
            tabIndex: navIndexForPath(state.uri.path),
            child: const SearchPage(),
          ),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => shellTabPage(
            context: context,
            pageKey: state.pageKey,
            path: state.uri.path,
            tabIndex: navIndexForPath(state.uri.path),
            child: const LibraryPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => shellTabPage(
            context: context,
            pageKey: state.pageKey,
            path: state.uri.path,
            tabIndex: navIndexForPath(state.uri.path),
            child: const SettingsPage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) => pushMotionPage(
        context: context,
        pageKey: state.pageKey,
        name: state.uri.path,
        vertical: true,
        child: const PlayerPage(),
      ),
    ),
    GoRoute(
      path: '/queue',
      pageBuilder: (context, state) => pushMotionPage(
        context: context,
        pageKey: state.pageKey,
        name: state.uri.path,
        child: const QueuePage(),
      ),
    ),
    GoRoute(
      path: '/playlist/:id',
      pageBuilder: (context, state) {
        final raw = state.pathParameters['id'];
        final id = int.tryParse(raw ?? '');
        final child = id == null
            ? NavErrorPage(uri: state.uri, message: 'invalid playlist id: $raw')
            : PlaylistDetailPage(id: id);
        return pushMotionPage(
          context: context,
          pageKey: state.pageKey,
          name: state.uri.path,
          child: child,
        );
      },
    ),
    GoRoute(
      path: '/cache',
      pageBuilder: (context, state) => pushMotionPage(
        context: context,
        pageKey: state.pageKey,
        name: state.uri.path,
        child: const CachePage(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => pushMotionPage(
        context: context,
        pageKey: state.pageKey,
        name: state.uri.path,
        child: const LoginPage(),
      ),
    ),
  ],
);

/// 记录页面 push / pop / replace。弹窗和底部菜单不是 [PageRoute]，不记。
class NavLogObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final loc = _location(route);
    if (loc == null) return;
    AppLogger.i(
      'push $loc from ${_location(previousRoute) ?? '-'}',
      tag: 'nav',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final loc = _location(route);
    if (loc == null) return;
    AppLogger.i('pop $loc -> ${_location(previousRoute) ?? '-'}', tag: 'nav');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final next = newRoute == null ? null : _location(newRoute);
    final prev = oldRoute == null ? null : _location(oldRoute);
    if (next == null && prev == null) return;
    AppLogger.i('replace ${prev ?? '-'} -> ${next ?? '-'}', tag: 'nav');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final loc = _location(route);
    if (loc == null) return;
    AppLogger.i(
      'remove $loc -> ${_location(previousRoute) ?? '-'}',
      tag: 'nav',
    );
  }
}

/// 页面路径。壳层容器没有路径，返回 null 以便跳过。
String? _location(Route<dynamic>? route) {
  if (route is! PageRoute) return null;
  final settings = route.settings;
  var path = settings.name;
  if (path == null || path.isEmpty) {
    final key = settings is Page<Object?> ? settings.key : null;
    if (key is ValueKey<String> && key.value.startsWith('/')) path = key.value;
  }
  if (path == null || path.isEmpty || !path.startsWith('/')) return null;
  final args = settings.arguments;
  if (args is Map && args.isNotEmpty) return '$path $args';
  return path;
}

/// 路由匹配失败或参数非法时的页面，并写入导航错误日志。
class NavErrorPage extends StatefulWidget {
  const NavErrorPage({super.key, required this.uri, required this.message});

  final Uri uri;
  final String message;

  @override
  State<NavErrorPage> createState() => _NavErrorPageState();
}

class _NavErrorPageState extends State<NavErrorPage> {
  @override
  void initState() {
    super.initState();
    AppLogger.e(
      'navigation failed ${widget.uri} ${widget.message}',
      tag: 'nav',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.errorUnknown(widget.message))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(widget.uri.toString()),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/search'),
              child: Text(l10n.navDiscover),
            ),
          ],
        ),
      ),
    );
  }
}
