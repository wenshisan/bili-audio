import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/audio_track.dart';
import 'audio_cache_store.dart';

/// 边播边缓存的音频源 (M3.3)
///
/// 完整缓存命中时直接从文件读取; 否则Range请求CDN并逐块写入.tmp文件。
/// 文件写满后自动 finalize()。
class CachingStreamAudioSource extends StreamAudioSource {
  CachingStreamAudioSource({
    required Track track,
    required this._url,
    required this._store,
    required this._dio,
  })  : _track = track,
        _key = '${track.bvid}_${track.cid}';

  final Track _track;
  final String _url;
  final AudioCacheStore _store;
  final Dio _dio;
  final String _key;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // 1. 完整缓存命中
    final cached = await _store.completed(_key);
    if (cached != null) {
      await _store.touch(_key);
      final length = cached.lengthSync();
      return StreamAudioResponse(
        sourceLength: length,
        contentLength: (end ?? length) - (start ?? 0),
        offset: start ?? 0,
        contentType: 'audio/mp4',
        stream: cached.openRead(start, end),
      );
    }

    // 2. 未缓存: 流式下载并写入
    return _streamAndCache(start, end);
  }

  Future<StreamAudioResponse> _streamAndCache(int? start, int? end) async {
    final options = Options(
      headers: {
        'Referer': 'https://www.bilibili.com',
        'User-Agent': 'Mozilla/5.0',
        if (start != null) 'Range': 'bytes=$start-${end ?? ""}',
      },
      responseType: ResponseType.stream,
    );

    final response = await _dio.get<ResponseBody>(_url, options: options);
    final body = response.data!;
    final sourceLength = _parseContentRange(response) ?? body.contentLength;

    final controller = StreamController<List<int>>();
    final tmpFile = _store.tmpFile(_key);
    IOSink? sink;

    // 仅当从头开始下载时才写入缓存
    if (start == null || start == 0) {
      sink = tmpFile.openWrite(mode: FileMode.writeOnlyAppend);
    }

    var written = tmpFile.existsSync() ? tmpFile.lengthSync() : 0;

    body.stream.listen(
      (chunk) {
        controller.add(chunk);
        if (sink != null) {
          sink.add(chunk);
          written += chunk.length;
          _store.recordPartial(_key, written, sourceLength);
        }
      },
      onDone: () async {
        await sink?.close();
        if (written >= sourceLength) {
          await _store.finalize(_key, sourceLength);
        }
        await controller.close();
      },
      onError: (e, st) {
        sink?.close();
        controller.addError(e, st);
      },
      cancelOnError: true,
    );

    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: body.contentLength ?? 0,
      offset: start ?? 0,
      contentType: 'audio/mp4',
      stream: controller.stream,
    );
  }

  int? _parseContentRange(Response<ResponseBody> response) {
    final range = response.headers.value('content-range');
    if (range == null) return null;
    final match = RegExp(r'/(\d+)$').firstMatch(range);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
