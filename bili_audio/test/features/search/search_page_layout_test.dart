import 'dart:io';

import 'package:bili_audio/app/adaptive/window_metrics.dart';
import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/repositories/fake_repositories.dart';
import 'package:bili_audio/data/lyrics/lyrics_manager.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/features/lyrics/lyrics_controller.dart';
import 'package:bili_audio/features/lyrics/lyrics_view.dart';
import 'package:bili_audio/features/search/search_page.dart';
import 'package:bili_audio/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/player/fakes.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late BiliAudioHandler handler;

  setUp(() {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('search_layout_');
    handler = BiliAudioHandler(
      engine: FakeEngine(),
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          searchRepositoryProvider.overrideWithValue(
            FakeSearchRepository(latency: Duration.zero),
          ),
          audioHandlerProvider.overrideWithValue(handler),
          lyricsManagerProvider.overrideWithValue(
            LyricsManager(db, dir, providers: const []),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LayoutBuilder(
            builder: (context, constraints) => WindowMetricsScope(
              metrics: WindowMetrics.fromSize(constraints.biggest),
              child: const SearchPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('搜索图标落在搜索栏圆角端的圆心', (tester) async {
    await pumpAt(tester, const Size(800, 800));
    final bar = tester.getRect(find.byType(SearchBar));
    final icon = tester.getRect(find.byIcon(Icons.search));
    expect((icon.center.dx - (bar.left + bar.height / 2)).abs(), lessThan(2));
    expect((icon.center.dy - bar.center.dy).abs(), lessThan(2));
  });

  testWidgets('完全展开时中间栏显示歌词', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    expect(find.byKey(const Key('lyrics-column')), findsOneWidget);
    expect(find.byType(LyricsView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未完全展开时不单列歌词', (tester) async {
    await pumpAt(tester, const Size(800, 800));
    expect(find.byType(LyricsView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
