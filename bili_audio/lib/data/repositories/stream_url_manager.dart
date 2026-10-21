import 'dart:convert';
import 'package:drift/drift.dart';

import '../../core/logging/app_logger.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/stream_url.dart';
import '../../domain/entities/audio_track.dart';
import '../db/app_database.dart';
import '../bili/bili_stream_api.dart';

/// 流地址管理器 (M2.5)
///
/// - 读写 `stream_urls` 表, `expiresAt - 10min` 内视为过期
/// - 同一 (bvid, cid, quality) 的并发请求合并为一次
/// - [refresh] 用于 CDN 403 等场景强制刷新
class StreamUrlManager {
  StreamUrlManager(this._db, this._streamApi, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const expiryMargin = Duration(minutes: 10);

  final AppDatabase _db;
  final BiliStreamApi _streamApi;
  final DateTime Function() _clock;
  final Map<String, Future<Result<StreamSelection>>> _inflight = {};

  Future<Result<StreamSelection>> getStreamUrl({
    required String bvid,
    required int cid,
    required AudioQuality quality,
    bool loggedIn = false,
  }) async {
    final cached = await _db.streamUrlsDao.getStreamUrl(bvid, cid, quality.id);
    if (cached != null && !_isExpired(cached)) {
      AppLogger.d(
        'cache hit $bvid cid=$cid q=${quality.name} '
        'expires=${cached.expiresAt.toIso8601String()}',
        tag: 'stream',
      );
      return Result.success((
        stream: _toEntity(cached),
        downgradedForGuest: false,
      ));
    }
    if (cached != null) {
      AppLogger.d(
        'cache expired $bvid cid=$cid q=${quality.name}',
        tag: 'stream',
      );
    }
    return _fetch(bvid, cid, quality, loggedIn);
  }

  /// 忽略缓存强制刷新
  Future<Result<StreamSelection>> refresh({
    required String bvid,
    required int cid,
    required AudioQuality quality,
    bool loggedIn = false,
  }) => _fetch(bvid, cid, quality, loggedIn);

  Future<Result<StreamSelection>> _fetch(
    String bvid,
    int cid,
    AudioQuality quality,
    bool loggedIn,
  ) {
    final key = '${bvid}_${cid}_${quality.id}';
    return _inflight[key] ??=
        () async {
          final result = await _streamApi.getStreamUrl(
            bvid: bvid,
            cid: cid,
            quality: quality,
            loggedIn: loggedIn,
          );
          final selection = result.valueOrNull;
          if (selection == null) {
            AppLogger.w(
              'fetch failed $bvid cid=$cid q=${quality.name} '
              'loggedIn=$loggedIn error=${result.errorOrNull}',
              tag: 'stream',
            );
          }
          if (selection != null) {
            final s = selection.stream;
            await _db.streamUrlsDao.upsertStreamUrl(
              StreamUrlsCompanion.insert(
                bvid: bvid,
                cid: cid,
                quality: quality.id,
                url: s.url,
                backupUrls: Value(jsonEncode(s.backupUrls)),
                mime: 'audio/mp4',
                expiresAt: DateTime.fromMillisecondsSinceEpoch(
                  s.expiresAt * 1000,
                ),
              ),
            );
          }
          return result;
        }().whenComplete(() {
          _inflight.remove(key); // 不能用 =>: 返回自身 Future 会导致自等待
        });
  }

  Future<int> cleanExpired() =>
      _db.streamUrlsDao.deleteExpired(_clock().millisecondsSinceEpoch ~/ 1000);

  bool _isExpired(StreamUrlRow row) =>
      !_clock().isBefore(row.expiresAt.subtract(expiryMargin));

  StreamUrl _toEntity(StreamUrlRow row) {
    List<String> backups;
    try {
      backups = (jsonDecode(row.backupUrls) as List<dynamic>).cast<String>();
    } catch (_) {
      backups = const [];
    }
    return StreamUrl(
      bvid: row.bvid,
      cid: row.cid,
      quality: AudioQuality.values.firstWhere(
        (q) => q.id == row.quality,
        orElse: () => AudioQuality.k132,
      ),
      url: row.url,
      backupUrls: backups,
      expiresAt: row.expiresAt.millisecondsSinceEpoch ~/ 1000,
    );
  }
}
