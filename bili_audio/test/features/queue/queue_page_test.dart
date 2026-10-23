import 'dart:io';

import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart' hide Track;
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/features/queue/queue_page.dart';
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

  const tracks = [
    Track(
      bvid: 'BV1',
      cid: 1,
      title: '晴天',
      artist: '周杰伦',
      duration: Duration(minutes: 4),
    ),
    Track(
      bvid: 'BV2',
      cid: 2,
      title: '七里香',
      artist: '周杰伦',
      duration: Duration(minutes: 4),
    ),
    Track(
      bvid: 'BV3',
      cid: 3,
      title: '江南',
      artist: '林俊杰',
      duration: Duration(minutes: 4),
    ),
  ];

  setUp(() async {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('queue_page_');
    handler = BiliAudioHandler(
      engine: FakeEngine(),
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
    await handler.setTracks(tracks, autoplay: false);
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  Future<void> pumpQueue(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    Widget child = const QueuePage(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          audioHandlerProvider.overrideWithValue(handler),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pump();
    // 跑完列表入场，并让入场窗口过期，后面的筛选不再重播。
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(const Key('queue-search')), query);
    await tester.pump();
  }

  testWidgets('搜索后点结果跳到原队列位置', (tester) async {
    await pumpQueue(tester);
    expect(find.text('晴天'), findsOneWidget);
    expect(find.text('七里香'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

    await search(tester, '江南');
    expect(find.widgetWithText(ListTile, '江南'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '晴天'), findsNothing);
    expect(find.widgetWithText(ListTile, '七里香'), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, '江南'));
    await tester.pump();
    await tester.pump();

    expect(handler.playbackQueue.cursor, 2);
    expect(handler.currentTrack?.title, '江南');
  });

  testWidgets('清除搜索后恢复整列', (tester) async {
    await pumpQueue(tester);
    await search(tester, '七里');
    expect(find.text('晴天'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('queue-search')),
        matching: find.byIcon(Icons.clear),
      ),
    );
    await tester.pump();

    expect(find.text('晴天'), findsOneWidget);
    expect(find.text('七里香'), findsOneWidget);
    expect(find.text('江南'), findsOneWidget);
  });

  testWidgets('拼音只留下匹配项，没有结果时给出说明', (tester) async {
    await pumpQueue(tester);
    await search(tester, 'zhou');
    expect(find.text('晴天'), findsOneWidget);
    expect(find.text('七里香'), findsOneWidget);
    expect(find.text('江南'), findsNothing);

    await search(tester, '没有这首');
    expect(find.text('队列中没有匹配的歌曲'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('从搜索结果移除的是原队列中的那一首', (tester) async {
    await pumpQueue(tester);
    await search(tester, '江南');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(handler.playbackQueue.orderedTracks.map((track) => track.title), [
      '晴天',
      '七里香',
    ]);
    expect(handler.currentTrack?.title, '晴天');
  });

  testWidgets('车机即将播放列表不提供搜索', (tester) async {
    await pumpQueue(
      tester,
      child: const Scaffold(body: QueueList(upcomingOnly: true)),
    );
    expect(find.byKey(const Key('queue-search')), findsNothing);
    expect(find.text('七里香'), findsOneWidget);
    expect(find.text('江南'), findsOneWidget);
    expect(find.text('晴天'), findsNothing);
  });

  testWidgets('窄宽度队列页无溢出', (tester) async {
    await pumpQueue(tester, size: const Size(320, 640));
    await search(tester, '周');
    expect(tester.takeException(), isNull);

    await pumpQueue(
      tester,
      size: const Size(280, 360),
      child: const Scaffold(body: QueueList(embedded: true)),
    );
    expect(find.byKey(const Key('queue-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
