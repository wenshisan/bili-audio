import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'audio_cache_store.dart';

const biliCdnHeaders = {
  'Referer': 'https://www.bilibili.com',
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
};

/// 单个音频的后台完整下载 (M3.2)
///
/// 顺序写入 `.tmp`, 支持断点续传 (Range); 完成后 finalize 为正式文件。
/// 播放端通过 [read] 跟随已下载部分读取, 实现边听边存。
class CacheDownloadTask {
  CacheDownloadTask({
    required this.key,
    required this._url,
    required this.store,
    required this.dio,
    this.refreshUrl,
    this.protectedKeys,
  });

  final String key;
  final AudioCacheStore store;
  final Dio dio;

  /// CDN 403 时获取新地址 (StreamUrlResolver.refresh)
  final Future<String> Function()? refreshUrl;
  final Set<String> Function()? protectedKeys;

  String _url;
  String get url => _url;
  final _total = Completer<int>();
  final _changes = StreamController<void>.broadcast();
  int downloaded = 0;
  bool done = false;
  Object? error;
  String mime = 'audio/mp4';
  CancelToken _cancel = CancelToken();

  Future<int> get totalLength => _total.future;

  Future<void>? _running;

  /// 启动下载; 重复调用返回同一个 Future
  Future<void> run() => _running ??= _run();

  Future<void> _run() async {
    var refreshed = false;
    while (true) {
      try {
        await _download();
        break;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          _fail(e);
          break;
        }
        if (e.response?.statusCode == 403 && !refreshed && refreshUrl != null) {
          refreshed = true;
          _url = await refreshUrl!();
          continue;
        }
        _fail(e);
        break;
      } catch (e) {
        _fail(e);
        break;
      }
    }
  }

  void cancel() => _cancel.cancel();

  void _fail(Object e) {
    error = e;
    if (!_total.isCompleted) {
      _total.future.ignore(); // 无人等待时不报未处理异常
      _total.completeError(e);
    }
    _changes.add(null);
  }

  Future<void> _download() async {
    _cancel = CancelToken();
    final tmp = store.tmpFile(key);
    await tmp.parent.create(recursive: true);
    downloaded = tmp.existsSync() ? tmp.lengthSync() : 0;

    final res = await dio.get<ResponseBody>(
      _url,
      cancelToken: _cancel,
      options: Options(
        responseType: ResponseType.stream,
        headers: {...biliCdnHeaders, if (downloaded > 0) 'Range': 'bytes=$downloaded-'},
        validateStatus: (s) => s != null && (s < 300 || s == 416),
      ),
    );

    if (res.statusCode == 416) {
      // 已下载完整但未 finalize
      return _complete(downloaded);
    }
    if (res.statusCode == 200) downloaded = 0; // 服务端忽略 Range, 从头写
    mime = res.headers.value(Headers.contentTypeHeader) ?? mime;
    final total = _parseTotal(res) ?? -1;
    if (total <= 0) throw StateError('unknown content length');
    if (!_total.isCompleted) _total.complete(total);
    await store.ensureSpace(
      total - downloaded,
      protectedKeys: {key, ...?protectedKeys?.call()},
    );

    final raf = await tmp.open(
      mode: downloaded == 0 ? FileMode.write : FileMode.append,
    );
    var lastRecorded = downloaded;
    try {
      await for (final chunk in res.data!.stream) {
        await raf.writeFrom(chunk);
        downloaded += chunk.length;
        _changes.add(null);
        if (downloaded - lastRecorded >= 1 << 20) {
          lastRecorded = downloaded;
          await store.recordPartial(key, downloaded, total);
        }
      }
    } finally {
      await raf.close();
    }
    if (downloaded < total) {
      await store.recordPartial(key, downloaded, total);
      throw StateError('stream ended early: $downloaded/$total');
    }
    await _complete(total);
  }

  Future<void> _complete(int total) async {
    if (!_total.isCompleted) _total.complete(total);
    // Windows 上读端短暂占用时 rename 可能失败, 稍后重试
    for (var i = 0;; i++) {
      try {
        await store.finalize(key, total);
        break;
      } on FileSystemException {
        if (i >= 10) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    downloaded = total;
    done = true;
    _changes.add(null);
  }

  static int? _parseTotal(Response<ResponseBody> res) {
    final range = res.headers.value('content-range');
    final m = range == null ? null : RegExp(r'/(\d+)$').firstMatch(range);
    if (m != null) return int.parse(m.group(1)!);
    final len = int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '');
    return len;
  }

  /// 读取 [start, end) 字节, 未下载到的部分等待下载进度
  Stream<List<int>> read(int start, int end) async* {
    var pos = start;
    var stalledSince = DateTime.now();
    while (pos < end) {
      if (pos < downloaded) {
        final n = min(min(downloaded, end) - pos, 64 * 1024);
        final bytes = await _readAt(pos, n);
        if (bytes.isNotEmpty) {
          yield bytes;
          pos += bytes.length;
          stalledSince = DateTime.now();
          continue;
        }
      }
      if (error != null) throw error!;
      if (DateTime.now().difference(stalledSince) > const Duration(seconds: 30)) {
        throw TimeoutException('cache download stalled');
      }
      await _changes.stream.first
          .timeout(const Duration(milliseconds: 500), onTimeout: () {});
    }
  }

  Future<Uint8List> _readAt(int pos, int n) async {
    for (final file in done
        ? [store.completeFile(key)]
        : [store.tmpFile(key), store.completeFile(key)]) {
      try {
        final raf = await file.open();
        try {
          await raf.setPosition(pos);
          return await raf.read(n);
        } finally {
          await raf.close();
        }
      } on FileSystemException {
        continue; // tmp 已被 rename, 换正式文件
      }
    }
    return Uint8List(0);
  }
}
