import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/network/bili_http.dart';
import '../core/network/buvid_manager.dart';
import '../core/network/interceptors/header_interceptor.dart';
import '../core/network/wbi_key_manager.dart';
import '../core/storage/path_manager.dart';
import '../core/storage/secure_store.dart';
import '../data/audio/audio_cache_store.dart';
import '../data/audio/cache_download_manager.dart';
import '../data/bili/bili_search_api.dart';
import '../data/bili/bili_stream_api.dart';
import '../data/bili/bili_video_api.dart';
import '../data/db/app_database.dart';
import '../data/player/audio_engine.dart';
import '../data/player/bili_audio_handler.dart';
import '../data/player/queue_snapshot_store.dart';
import '../data/repositories/bili_repositories.dart';
import '../data/repositories/stream_url_manager.dart';
import '../domain/entities/audio_track.dart';
import '../domain/title/title_cleaner.dart';
import 'platform/desktop_platform.dart';
import 'providers.dart';

/// 构建真实依赖并返回 ProviderScope overrides (M6)
///
/// 要求 [PathManager.init] 已完成。失败时抛出, 由 main 展示启动错误页。
Future<List<Override>> bootstrap() async {
  await initDesktopPlatform();

  final db = AppDatabase();
  final SecureStore store = FlutterSecureStore();

  // 获取 buvid / WBI key 的请求不经过 BiliHttp 拦截器链, 避免递归
  final raw = Dio(BaseOptions(baseUrl: 'https://api.bilibili.com'))
    ..interceptors.add(HeaderInterceptor());
  final http = BiliHttp(
    store: store,
    buvidManager: BuvidManager(store, () async {
      final res = await raw.get<Map<String, dynamic>>('/x/frontend/finger/spi');
      final data = res.data!['data'] as Map<String, dynamic>;
      return (data['b_3'] as String, data['b_4'] as String);
    }),
    wbiKeyManager: WbiKeyManager(() async {
      // 未登录时 code=-101, 但 wbi_img 仍然返回
      final res = await raw.get<Map<String, dynamic>>('/x/web-interface/nav');
      final img = (res.data!['data'] as Map<String, dynamic>)['wbi_img']
          as Map<String, dynamic>;
      return (img['img_url'] as String, img['sub_url'] as String);
    }),
  );

  final cleaner = TitleCleaner.fromJson(
    await rootBundle.loadString('assets/config/title_cleaning_rules.json'),
  );

  final customDir = await db.settingsDao.getCacheDir();
  final downloads = CacheDownloadManager(
    AudioCacheStore(
      db,
      customDir == null ? PathManager.audioDir : Directory(customDir),
      limitBytes: db.settingsDao.getCacheMaxSize,
    ),
    Dio(),
  );

  final qualityId = await db.settingsDao.getDefaultQuality();
  final prefs = PlaybackPrefs(
    quality: AudioQuality.values.firstWhere(
      (q) => q.id == qualityId,
      orElse: () => AudioQuality.k132,
    ),
    loggedIn: (await store.readCookies())?.contains('SESSDATA') ?? false,
  );

  BiliAudioHandler build() => BiliAudioHandler(
        engine: JustAudioEngine(),
        streams: BiliStreamRepository(
          StreamUrlManager(db, BiliStreamApi(http)),
        ),
        downloads: downloads,
        snapshots: QueueSnapshotStore(db),
        recorder: (track) async {
          await db.tracksDao.ensureTrack(TracksCompanion.insert(
            bvid: track.bvid,
            cid: track.cid,
            title: track.title,
            duration: track.duration.inSeconds,
          ));
          final id = await db.historyDao.start(track.bvid, track.cid);
          return (Duration p) =>
              unawaited(db.historyDao.updateProgress(id, p, track.duration));
        },
        quality: () => prefs.quality,
        loggedIn: () => prefs.loggedIn,
      );

  // audio_service 不支持 Windows/Linux (D3): 直接构造, Windows 另接 SMTC
  final BiliAudioHandler handler;
  if (Platform.isWindows || Platform.isLinux) {
    handler = build();
    if (Platform.isWindows) WindowsMediaBridge(handler);
  } else {
    handler = await AudioService.init(
      builder: build,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.bilimusic.bili_audio.playback',
        androidNotificationChannelName: '音频播放',
        androidStopForegroundOnPause: false,
      ),
    );
  }
  await handler.restore();

  return [
    databaseProvider.overrideWithValue(db),
    playbackPrefsProvider.overrideWithValue(prefs),
    searchRepositoryProvider
        .overrideWithValue(BiliSearchRepository(BiliSearchApi(http), cleaner)),
    videoRepositoryProvider.overrideWithValue(
      BiliVideoRepository(db, BiliVideoApi(http), cleaner),
    ),
    audioHandlerProvider.overrideWithValue(handler),
  ];
}
