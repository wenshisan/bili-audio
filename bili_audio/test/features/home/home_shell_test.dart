import 'dart:io';

import 'package:bili_audio/app/adaptive/layout_settings.dart';
import 'package:bili_audio/app/adaptive/split_view.dart';
import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/features/home/home_shell.dart';
import 'package:bili_audio/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../data/player/fakes.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late FakeEngine engine;
  late BiliAudioHandler handler;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('shell_');
    engine = FakeEngine();
    handler = BiliAudioHandler(
      engine: engine,
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_harness(db, handler));
    await tester.pumpAndSettle();
  }

  testWidgets('390 宽使用底栏', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('now-playing-pane')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('800 宽使用侧栏', (tester) async {
    await pumpAt(tester, const Size(800, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const Key('now-playing-pane')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('侧栏把我的放在底部，并与主界面有分界', (tester) async {
    await pumpAt(tester, const Size(800, 800));
    _expectMinePinnedToBottom(tester);

    await tester.tap(find.byKey(const Key('nav-mine')));
    await tester.pumpAndSettle();
    expect(find.text('settings-body'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAt(tester, const Size(1280, 800));
    _expectMinePinnedToBottom(tester);
  });

  testWidgets('iPad 三分屏宽度使用底栏', (tester) async {
    await pumpAt(tester, const Size(375, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('768 宽使用侧栏', (tester) async {
    await pumpAt(tester, const Size(768, 1024));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byKey(const Key('now-playing-pane')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPad 全屏横屏使用主从栏', (tester) async {
    await pumpAt(tester, const Size(1194, 834));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byKey(const Key('now-playing-pane')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1280 宽使用右播放栏', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byKey(const Key('now-playing-pane')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('分隔条拖到两端后比例写入设置', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    await tester.drag(
      find.byKey(const Key('split-handle')),
      const Offset(800, 0),
    );
    await tester.pumpAndSettle();
    expect(await _storedRatio(db), 0.75);

    await tester.drag(
      find.byKey(const Key('split-handle')),
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();
    expect(await _storedRatio(db), 0.4);
  });

  testWidgets('横屏系统插入区内仍是底栏，不是车机布局', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    const inset = FakeViewPadding(left: 47, right: 47, bottom: 21);
    tester.view.padding = inset;
    tester.view.viewPadding = inset;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(_harness(db, handler));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('car-layout')), findsNothing);
    final nav = tester.getRect(find.byType(NavigationBar));
    expect(nav.bottom, lessThanOrEqualTo(390 - 21));
    expect(nav.left, greaterThanOrEqualTo(47));
    expect(tester.takeException(), isNull);
  });

  testWidgets('844×390 打开车机开关后才是车机布局', (tester) async {
    await db.settingsDao.set('layout.car_mode', 'on');
    await pumpAt(tester, const Size(844, 390));
    expect(find.byKey(const Key('car-layout')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1280×720 打开车机布局后可直接切歌，关闭后恢复主从栏', (tester) async {
    await db.settingsDao.set('layout.car_mode', 'on');
    await pumpAt(tester, const Size(1280, 720));
    expect(find.byKey(const Key('car-layout')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('transport-play'))).width,
      greaterThanOrEqualTo(76),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('car-exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('car-layout')), findsNothing);
    expect(find.byKey(const Key('now-playing-pane')), findsOneWidget);
  });

  testWidgets('1920×480 车机布局无溢出', (tester) async {
    await db.settingsDao.set('layout.car_mode', 'on');
    await pumpAt(tester, const Size(1920, 480));
    expect(find.byKey(const Key('car-layout')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('transport-next'))).width,
      greaterThanOrEqualTo(76),
    );
    expect(tester.takeException(), isNull);
  });

  test('重新打开后恢复分隔比例', () async {
    await db.settingsDao.set('layout.split_ratio', '0.4');
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(layoutSettingsProvider);
    await _waitFor(container, (s) => s.splitRatio == 0.4);
    expect(container.read(layoutSettingsProvider).splitRatio, 0.4);
  });
}

void _expectMinePinnedToBottom(WidgetTester tester) {
  final discover = tester.getCenter(find.text('发现'));
  final library = tester.getCenter(find.text('歌单'));
  final mine = tester.getCenter(find.byKey(const Key('nav-mine')));
  expect(library.dy, greaterThan(discover.dy));
  expect(mine.dy, greaterThan(library.dy + 200));
  final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
  final scheme = Theme.of(tester.element(find.byType(NavigationRail)))
      .colorScheme;
  expect(rail.backgroundColor, scheme.surfaceContainer);
  expect(rail.backgroundColor, isNot(scheme.surface));
  final boundary = tester.getSize(find.byKey(const Key('nav-rail-surface')));
  expect(boundary.width, 80);
  expect(boundary.height, greaterThan(700));
  expect(find.byType(VerticalDivider), findsNothing);
  expect(
    find.descendant(
      of: find.byKey(const Key('nav-rail-surface')),
      matching: find.byWidgetPredicate((widget) {
        final decoration = widget is DecoratedBox ? widget.decoration : null;
        return decoration is BoxDecoration && decoration.gradient != null;
      }),
    ),
    findsOneWidget,
  );
}

Future<double> _storedRatio(AppDatabase db) async {
  for (var i = 0; i < 20; i++) {
    final raw = await db.settingsDao.get('layout.split_ratio');
    final value = double.tryParse(raw ?? '');
    if (value != null) return SplitView.clampRatio(value);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('layout.split_ratio was not written');
}

Future<void> _waitFor(
  ProviderContainer container,
  bool Function(LayoutSettings settings) ready,
) async {
  for (var i = 0; i < 20; i++) {
    if (ready(container.read(layoutSettingsProvider))) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Widget _harness(AppDatabase db, BiliAudioHandler handler) {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      ShellRoute(
        builder: (_, _, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/search',
            builder: (_, _) => const Text('search-body'),
          ),
          GoRoute(
            path: '/library',
            builder: (_, _) => const Text('library-body'),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const Text('settings-body'),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      audioHandlerProvider.overrideWithValue(handler),
    ],
    child: MaterialApp.router(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}
