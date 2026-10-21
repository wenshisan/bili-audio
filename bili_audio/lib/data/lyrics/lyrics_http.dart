import 'package:dio/dio.dart';

import '../../domain/lyrics/lyrics_provider.dart';

/// 每个歌词请求的连接和读取上限。失败后由管理器再试一次。
const lyricsRequestTimeout = Duration(seconds: 1);

Dio lyricsClient(String baseUrl, {Map<String, Object?>? headers}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: lyricsRequestTimeout,
      receiveTimeout: lyricsRequestTimeout,
      sendTimeout: lyricsRequestTimeout,
      headers: headers,
    ),
  );
}

Options lyricsRequestOptions({
  Map<String, dynamic>? headers,
  Map<String, dynamic>? extra,
}) {
  return Options(
    headers: headers,
    extra: extra,
    connectTimeout: lyricsRequestTimeout,
    receiveTimeout: lyricsRequestTimeout,
    sendTimeout: lyricsRequestTimeout,
  );
}

/// 超时或连不上时抛出，让管理器重试并换下一个歌词源。
void throwIfLyricsTransport(DioException error, String source) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      throw LyricsSourceUnavailable('$source ${error.type.name}');
    default:
      return;
  }
}
