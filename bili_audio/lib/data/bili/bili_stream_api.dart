import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/bili_http.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import '../../domain/entities/stream_url.dart';
import '../../domain/entities/audio_track.dart';
import 'audio_quality_selector.dart';

/// 流选择结果 (M2.4)
typedef StreamSelection = ({StreamUrl stream, bool downgradedForGuest});

/// Bilibili 音频流地址 API (M2.4)
class BiliStreamApi {
  BiliStreamApi(this._http);

  final BiliHttp _http;

  /// 获取音频流地址
  ///
  /// [loggedIn] 是否已登录; 未登录时最高 132K
  /// [downgradedForGuest] 表示因未登录而降级
  Future<Result<StreamSelection>> getStreamUrl({
    required String bvid,
    required int cid,
    required AudioQuality quality,
    bool loggedIn = false,
  }) async {
    try {
      final response = await _http.dio.get<Map<String, dynamic>>(
        '/x/player/wbi/playurl',
        queryParameters: {
          'bvid': bvid,
          'cid': cid,
          'qn': 0,
          'fnval': 4048, // DASH + Dolby + Flac + HDR + 4K
          'fourk': 1,
        },
        options: Options(extra: {'wbi': true}),
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final dash = data['dash'] as Map<String, dynamic>?;

      if (dash == null) {
        AppLogger.w('playurl $bvid cid=$cid has no dash', tag: 'stream');
        return const Result.failure(AppError.unknown(message: 'No DASH data'));
      }

      final candidates = AudioQualitySelector.collect(dash);
      final selected = AudioQualitySelector.select(
        candidates,
        quality,
        loggedIn: loggedIn,
      );

      if (selected == null) {
        AppLogger.w(
          'playurl $bvid cid=$cid no audio '
          'candidates=${candidates.length} want=${quality.name}',
          tag: 'stream',
        );
        return const Result.failure(
          AppError.unknown(message: 'No audio streams'),
        );
      }

      final expiresAt = _extractExpiry(selected.url);
      final downgradedForGuest =
          !loggedIn &&
          AudioQualitySelector.rank(quality) >
              AudioQualitySelector.rank(AudioQualitySelector.guestCap);

      final streamUrl = StreamUrl(
        bvid: bvid,
        cid: cid,
        quality: selected.quality,
        url: selected.url,
        backupUrls: selected.backupUrls,
        expiresAt: expiresAt,
      );

      AppLogger.i(
        'playurl $bvid cid=$cid want=${quality.name} '
        'got=${selected.quality.name} loggedIn=$loggedIn '
        'downgraded=$downgradedForGuest '
        'candidates=${candidates.map((c) => c.quality.name).join(',')}',
        tag: 'stream',
      );

      return Result.success((
        stream: streamUrl,
        downgradedForGuest: downgradedForGuest,
      ));
    } on DioException catch (e) {
      final error = e.error;
      AppLogger.e(
        'playurl $bvid cid=$cid failed',
        tag: 'stream',
        error: error ?? e,
      );
      if (error is AppError) {
        return Result.failure(error);
      }
      return Result.failure(
        AppError.network(message: 'Get stream URL failed', cause: e),
      );
    } catch (e, st) {
      AppLogger.e(
        'playurl $bvid cid=$cid failed',
        tag: 'stream',
        error: e,
        stackTrace: st,
      );
      return Result.failure(
        AppError.unknown(
          message: 'Stream URL error: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  int _extractExpiry(String url) {
    try {
      final uri = Uri.parse(url);
      final deadline = uri.queryParameters['deadline'];
      if (deadline != null) return int.parse(deadline);
    } catch (_) {}
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200;
  }
}
