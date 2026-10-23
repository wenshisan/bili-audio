import 'dart:io';

import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/data/album/album_manager.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:bili_audio/data/lyrics/lyrics_manager.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/domain/lyrics/lrc_parser.dart';
import 'package:bili_audio/features/album/album_controller.dart';
import 'package:bili_audio/features/lyrics/lyrics_controller.dart';
import 'package:bili_audio/features/lyrics/lyrics_view.dart';
import 'package:bili_audio/features/player/widgets/car_player.dart';
import 'package:bili_audio/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../data/player/fakes.dart';

class _ReadyAlbum extends AlbumController {
  @override
  Future<AlbumResult?> build() async => const AlbumFound(
    albumName: '叶惠美',
    year: 2003,
    description: '周杰伦第四张录音室专辑，收录晴天。',
    fromCache: false,
  );
}

class _ReadyLyrics extends LyricsController {
  @override
  Future<LyricsResult?> build() async => LyricsFound(
    LrcParser.parse('[00:00.00]故事的小黄花\n[00:05.00]从出生那年就飘着'),
    fromCache: true,
  );
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late BiliAudioHandler handler;

  setUp(() async {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('car_player_');
    handler = BiliAudioHandler(
      engine: FakeEngine(),
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
    await handler.setTracks(makeTracks(3));
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  for (final size in const [Size(844, 390), Size(1280, 720), Size(1920, 480)]) {
    testWidgets('车机 ${size.width.toInt()}×${size.height.toInt()} 歌词置顶、介绍在右', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            audioHandlerProvider.overrideWithValue(handler),
            albumControllerProvider.overrideWith(_ReadyAlbum.new),
            lyricsControllerProvider.overrideWith(_ReadyLyrics.new),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CarPlayer(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final line = tester.widget<Text>(
        find.byKey(const Key('current-lyric-line')),
      );
      expect(line.data, '故事的小黄花');
      expect(line.maxLines, 2);
      expect(line.style?.fontWeight, FontWeight.w700);
      expect(line.style?.fontSize, greaterThan(22));

      final layout = tester.getRect(find.byKey(const Key('car-layout')));
      final banner = tester.getRect(find.byKey(const Key('car-current-lyric')));
      final lyricLine = tester.getRect(
        find.byKey(const Key('current-lyric-line')),
      );
      final lyrics = tester.getRect(find.byType(LyricsView));
      final intro = tester.getRect(find.byKey(const Key('album-intro')));
      final toggle = tester.getRect(find.byKey(const Key('car-panel-toggle')));
      final play = tester.getRect(find.byKey(const Key('transport-play')));

      expect(banner.contains(lyricLine.center), isTrue);
      expect(banner.top, lessThanOrEqualTo(layout.top + 1));
      expect(banner.bottom, lessThanOrEqualTo(lyrics.top + 1));
      expect(lyrics.center.dx, lessThan(intro.center.dx));
      expect(lyrics.right, lessThanOrEqualTo(intro.left));
      expect(toggle.left, greaterThanOrEqualTo(lyrics.left));
      expect(toggle.left, lessThanOrEqualTo(lyrics.left + 20));
      expect(toggle.top, greaterThanOrEqualTo(lyrics.top));
      expect(toggle.top, lessThanOrEqualTo(lyrics.top + 20));
      expect(toggle.right, lessThan(lyrics.right));
      expect(toggle.height, inInclusiveRange(40, 56));
      expect(play.bottom, greaterThan(layout.bottom - 20));
      expect(play.width, greaterThanOrEqualTo(76));
      expect(tester.takeException(), isNull);
    });
  }
}
