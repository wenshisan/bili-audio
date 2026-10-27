import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/lyrics/lyrics_provider.dart';

/// 每个歌词请求的连接和读取上限。失败后由管理器再试一次。
const lyricsRequestTimeout = Duration(seconds: 3);

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

/// 歌词搜索词。
///
/// [omitArtist] 为真时不把歌手拼进搜索词。
String lyricsKeyword(String title, String? artist, {required bool omitArtist}) {
  final name = title.trim();
  if (omitArtist) return name;
  final who = artist?.trim();
  if (who == null || who.isEmpty) return name;
  return '$name $who';
}

/// 歌词接口返回的 JSON。
///
/// 对象原样收下。字符串先去掉外层回调，再解析花括号里的对象。
Map<String, dynamic>? lyricsJsonBody(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  if (data is! String) return null;
  final start = data.indexOf('{');
  final end = data.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final decoded = jsonDecode(data.substring(start, end + 1));
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } on FormatException {
    return null;
  }
  return null;
}

/// 同步歌词文本。
///
/// 已经带时间轴的原文直接返回。没有时间轴时按 Base64 再解一次。
String? syncedLrcText(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return null;
  if (text.contains('[')) return text;
  try {
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    final decoded = utf8.decode(base64.decode(compact));
    if (decoded.contains('[')) return decoded;
  } on FormatException {
    return null;
  }
  return null;
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
