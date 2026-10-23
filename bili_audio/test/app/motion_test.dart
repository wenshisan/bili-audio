import 'package:bili_audio/app/motion/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(tabMotion.reset);

  testWidgets('底栏切换先让出旧页，再显示新页', (tester) async {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        ShellRoute(
          pageBuilder: (context, state, child) => NoTransitionPage(
            key: state.pageKey,
            child: Scaffold(body: child),
          ),
          routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (context, state) => shellTabPage(
                context: context,
                pageKey: state.pageKey,
                path: state.uri.path,
                tabIndex: 0,
                child: const Text('search-body'),
              ),
            ),
            GoRoute(
              path: '/library',
              pageBuilder: (context, state) => shellTabPage(
                context: context,
                pageKey: state.pageKey,
                path: state.uri.path,
                tabIndex: 1,
                child: const Text('library-body'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('search-body'), findsOneWidget);
    expect(find.text('library-body'), findsNothing);

    router.go('/library');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(tabMotion.travel, greaterThan(0));
    expect(find.text('search-body'), findsOneWidget);
    expect(find.text('library-body'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('library-body'), findsOneWidget);
    expect(find.text('search-body'), findsNothing);

    router.go('/search');
    await tester.pump();
    expect(tabMotion.travel, lessThan(0));
    await tester.pumpAndSettle();
    expect(find.text('search-body'), findsOneWidget);
    expect(find.text('library-body'), findsNothing);
  });

  testWidgets('减少动态效果时分页立即切换', (tester) async {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => shellTabPage(
            context: context,
            pageKey: state.pageKey,
            path: state.uri.path,
            tabIndex: 0,
            child: const Text('search-body'),
          ),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => shellTabPage(
            context: context,
            pageKey: state.pageKey,
            path: state.uri.path,
            tabIndex: 1,
            child: const Text('library-body'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/library');
    await tester.pump();
    expect(find.text('library-body'), findsOneWidget);
    expect(find.text('search-body'), findsNothing);
  });

  testWidgets('状态替换结束后只留下新内容', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _SwapHost()));
    expect(find.text('第一页'), findsOneWidget);

    await tester.tap(find.text('第一页'));
    await tester.pump();
    expect(find.text('第一页'), findsOneWidget);
    expect(find.text('第二页'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('第一页'), findsNothing);
    expect(find.text('第二页'), findsOneWidget);
  });

  testWidgets('列表前几项入场后仍可找到', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListEntranceScope(
            child: ListView(
              children: const [
                ListEntrance(index: 0, child: Text('item-0')),
                ListEntrance(index: 1, child: Text('item-1')),
                ListEntrance(index: 2, child: Text('item-2')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('item-0'), findsOneWidget);
    expect(find.text('item-2'), findsOneWidget);
  });

  testWidgets('骨架屏画出占位行', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonList(count: 3))),
    );
    expect(find.byType(ListTile), findsNWidgets(3));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _SwapHost extends StatefulWidget {
  const _SwapHost();

  @override
  State<_SwapHost> createState() => _SwapHostState();
}

class _SwapHostState extends State<_SwapHost> {
  var _second = false;

  @override
  Widget build(BuildContext context) {
    return MotionSwap(
      swapKey: _second ? 'b' : 'a',
      child: TextButton(
        onPressed: () => setState(() => _second = true),
        child: Text(_second ? '第二页' : '第一页'),
      ),
    );
  }
}
