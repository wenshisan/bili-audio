import 'dart:io';

import 'package:bili_audio/app/providers.dart';
import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/db/app_database.dart' hide Track;
import 'package:bili_audio/data/lyrics/lyrics_manager.dart';
import 'package:bili_audio/features/lyrics/lyrics_controller.dart';
import 'package:bili_audio/data/player/bili_audio_handler.dart';
import 'package:bili_audio/domain/entities/audio_track.dart';
import 'package:bili_audio/features/player/player_page.dart';
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

  setUp(() async {
    db = AppDatabase.memory();
    dir = Directory.systemTemp.createTempSync('player_layout_');
    handler = BiliAudioHandler(
      engine: FakeEngine(),
      streams: CountingStreamRepository(),
      downloads: CacheDownloadManager(
        AudioCacheStore(db, dir, limitBytes: () async => 1 << 30),
        Dio(),
      ),
    );
    await handler.setTracks([
      const Track(
        bvid: 'BV1',
        cid: 1,
        title: '晴天',
        artist: '周杰伦',
        duration: Duration(minutes: 4),
      ),
    ]);
  });

  tearDown(() async {
    await handler.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  for (final size in const [Size(390, 844), Size(844, 390), Size(1280, 800)]) {
    testWidgets('播放页 ${size.width.toInt()}×${size.height.toInt()} 无溢出', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            audioHandlerProvider.overrideWithValue(handler),
            lyricsManagerProvider.overrideWithValue(
              LyricsManager(db, dir, providers: const []),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PlayerPage(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('晴天'), findsWidgets);
    });
  }
}
