import 'dart:io';

import 'package:bili_audio/app/app.dart';
import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/app/theme.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/data/lyrics/lyrics_manager.dart';
import 'package:bili_audio/data/repositories/fake_repositories.dart';
import 'package:bili_audio/domain/lyrics/lrc_parser.dart';
import 'package:bili_audio/domain/lyrics/lyrics_provider.dart';
import 'package:bili_audio/features/lyrics/lyrics_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data/player/fakes.dart';

const _lrc = '[00:00.00]窗外的麻雀\n[00:05.00]在电线杆上多嘴';

class _FixedLyrics implements LyricsProvider {
  @override
  String get name => 'fixed';
  @override
  int get priority => 0;
  @override
  Future<List<LyricsCandidate>> search(LyricsQuery q) async => [
    LyricsCandidate(
      lyrics: LrcParser.parse(_lrc),
      source: name,
      matchScore: 0.95,
      lrcText: _lrc,
    ),
  ];
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late FakeEngine engine;
  late BiliAudioHandler handler;

  setUp(() async {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('widget_');
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

  Widget app() => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      searchRepositoryProvider.overrideWithValue(
        FakeSearchRepository(latency: Duration.zero),
      ),
      videoRepositoryProvider.overrideWithValue(FakeVideoRepository()),
      audioHandlerProvider.overrideWithValue(handler),
      lyricsManagerProvider.overrideWithValue(
        LyricsManager(db, dir, providers: [_FixedLyrics()]),
      ),
    ],
    child: const BiliAudioApp(),
  );

  testWidgets('启动显示搜索页; 无播放时隐藏迷你播放栏', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.text('排行榜'), findsOneWidget);
    expect(find.text('年代'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('年代')).dx,
      lessThan(tester.getTopLeft(find.text('排行榜')).dx),
    );
    expect(find.text('热度'), findsOneWidget);
    expect(find.text('评价最高'), findsOneWidget);
    expect(find.text('中文'), findsNothing);
    expect(find.text('七里香 - 周杰伦'), findsOneWidget);
    expect(find.text('4 首'), findsOneWidget);
    expect(find.textContaining('超长'), findsNothing);
    expect(find.text('播放全部'), findsOneWidget);
    expect(find.byIcon(Icons.queue_music), findsNothing);
  });

  testWidgets('搜索 → 显示清洗后标题; 点击开始播放', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '七里香');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('七里香 - 周杰伦'), findsOneWidget);
    expect(find.byTooltip('播放'), findsOneWidget);

    await tester.tap(find.byTooltip('播放'));
    await tester.pumpAndSettle();

    expect(handler.currentTrack?.bvid, 'BV1fake00001');
    expect(engine.playing, true);
    // 迷你播放栏出现, 显示当前曲, 以及上一首/下一首
    expect(find.text('七里香'), findsWidgets);
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
    expect(find.byTooltip('上一首'), findsOneWidget);
    expect(find.byTooltip('下一首'), findsOneWidget);

    await tester.tap(find.byTooltip('下一首'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('上一首'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);
  });

  testWidgets('超过 15 分钟的搜索结果不显示', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '录播');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('没有找到相关结果'), findsOneWidget);
    expect(find.text('播放全部'), findsNothing);
    expect(find.textContaining('超长'), findsNothing);
  });

  testWidgets('搜索结果可以播放全部', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '七里香');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('播放全部'), findsOneWidget);
    expect(find.text('1 首'), findsOneWidget);

    await tester.tap(find.text('播放全部'));
    await tester.pumpAndSettle();

    expect(handler.currentTrack?.bvid, 'BV1fake00001');
    expect(engine.playing, true);
    expect(find.text('七里香'), findsWidgets);
  });

  testWidgets('推荐分类放不下时折叠，播放全部不挡住分类', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final play = tester.getRect(find.text('播放全部'));
    final heat = tester.getRect(find.text('热度'));
    expect(play.overlaps(heat), isFalse);
    expect(play.top, greaterThanOrEqualTo(heat.bottom));
    expect(find.text('AI音乐'), findsNothing);
    expect(find.byTooltip('展开'), findsOneWidget);

    final expand = tester.getRect(find.byIcon(Icons.expand_more));
    expect(expand.overlaps(heat), isFalse);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.text('AI音乐'), findsOneWidget);
    expect(find.byTooltip('收起'), findsOneWidget);
    expect(
      tester
          .getRect(find.text('播放全部'))
          .overlaps(tester.getRect(find.text('AI音乐'))),
      isFalse,
    );

    await tester.tap(find.text('AI音乐'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pumpAndSettle();

    expect(find.text('AI音乐'), findsOneWidget);
    expect(find.byTooltip('展开'), findsOneWidget);

    await tester.tap(find.text('播放全部'));
    await tester.pumpAndSettle();
    expect(engine.playing, isTrue);
  });

  testWidgets('推荐分类一行放得下时不显示展开', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('AI音乐'), findsOneWidget);
    expect(find.text('VOCALOID'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byIcon(Icons.expand_less), findsNothing);
    final play = tester.getRect(find.text('播放全部'));
    expect(play.overlaps(tester.getRect(find.text('热度'))), isFalse);
    expect(
      play.top,
      greaterThanOrEqualTo(tester.getRect(find.text('热度')).bottom),
    );
  });

  testWidgets('底部导航切换到歌单页', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('歌单').last);
    await tester.pumpAndSettle();

    expect(find.text('还没有歌单'), findsOneWidget);

    // drift 的 watch 查询在取消订阅时注册 0 延迟定时器, 卸载后需推进一帧
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  test('ThemeController updates mode and seed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(themeControllerProvider.notifier);
    expect(container.read(themeControllerProvider).mode, ThemeMode.system);

    controller.setMode(ThemeMode.dark);
    controller.setSeed(presetSeeds[1]);

    final state = container.read(themeControllerProvider);
    expect(state.mode, ThemeMode.dark);
    expect(state.seed, presetSeeds[1]);
  });

  test('主题: 编解码往返; 修改时调用持久化回调; 默认 seed 兼容旧格式', () {
    const theme = ThemeState(mode: ThemeMode.dark, seed: Color(0xFF00AEEC));
    final (m, s) = theme.encode();
    final back = ThemeState.decode(m, s);
    expect(back.mode, ThemeMode.dark);
    expect(back.seed, const Color(0xFF00AEEC));
    // M0.3 默认值写的是 0xFF2196F3
    expect(
      ThemeState.decode('system', '0xFF2196F3').seed,
      const Color(0xFF2196F3),
    );
    expect(ThemeState.decode(null, 'garbage').seed, presetSeeds.first);

    final saved = <ThemeState>[];
    final container = ProviderContainer(
      overrides: [
        initialThemeProvider.overrideWithValue(back),
        themeSaverProvider.overrideWithValue((t) async => saved.add(t)),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(themeControllerProvider).mode, ThemeMode.dark);
    container.read(themeControllerProvider.notifier).setMode(ThemeMode.light);
    expect(saved.single.mode, ThemeMode.light);
  });
}
