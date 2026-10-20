import 'package:dio/dio.dart';

import '../../core/network/bili_http.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import '../../domain/entities/stream_url.dart';
import '../../domain/entities/audio_track.dart';

/// Bilibili 音频流地址 API (M2.4)
class BiliStreamApi {
  BiliStreamApi(this._http);

  final BiliHttp _http;

  /// 获取音频流地址
  ///
  /// [bvid] 视频BV号
  /// [cid] 分P的cid
  /// [quality] 音质档位
  Future<Result<StreamUrl>> getStreamUrl({
    required String bvid,
    required int cid,
    required AudioQuality quality,
  }) async {
    try {
      final response = await _http.dio.get<Map<String, dynamic>>(
        '/x/player/wbi/playurl',
        queryParameters: {
          'bvid': bvid,
          'cid': cid,
          'qn': 0, // 音频固定为 0
          'fnval': 16, // DASH 格式
          'fourk': 1,
        },
        options: Options(extra: {'wbi': true}),
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      final dash = data['dash'] as Map<String, dynamic>?;

      if (dash == null) {
        return const Result.failure(
          AppError.unknown(message: 'No DASH data'),
        );
      }

      final audioList = dash['audio'] as List<dynamic>?;
      if (audioList == null || audioList.isEmpty) {
        return const Result.failure(
          AppError.unknown(message: 'No audio streams'),
        );
      }

      // 查找匹配的音质
      Map<String, dynamic>? targetAudio;
      for (final audio in audioList) {
        final audioMap = audio as Map<String, dynamic>;
        if (audioMap['id'] == quality.id) {
          targetAudio = audioMap;
          break;
        }
      }

      // 降级策略: 未找到目标音质时使用第一个
      targetAudio ??= audioList.first as Map<String, dynamic>;

      final baseUrl = targetAudio['base_url'] as String?;
      final backupUrl = (targetAudio['backup_url'] as List<dynamic>?)
          ?.firstOrNull as String?;

      if (baseUrl == null || baseUrl.isEmpty) {
        return const Result.failure(
          AppError.unknown(message: 'Empty stream URL'),
        );
      }

      // 从 URL 提取过期时间
      final expiresAt = _extractExpiry(baseUrl);

      final streamUrl = StreamUrl(
        bvid: bvid,
        cid: cid,
        quality: quality,
        url: baseUrl,
        backupUrl: backupUrl,
        expiresAt: expiresAt,
      );

      return Result.success(streamUrl);
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppError) {
        return Result.failure(error);
      }
      return Result.failure(
        AppError.network(message: 'Get stream URL failed', cause: e),
      );
    } catch (e, st) {
      return Result.failure(
        AppError.unknown(
          message: 'Stream URL error: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// 从 URL 的 deadline 参数提取过期时间
  int _extractExpiry(String url) {
    try {
      final uri = Uri.parse(url);
      final deadline = uri.queryParameters['deadline'];
      if (deadline != null) {
        return int.parse(deadline);
      }
    } catch (_) {}

    // 默认 2 小时后过期
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200;
  }
}
