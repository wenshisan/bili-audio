import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_download_manager.dart';
import 'package:bili_audio/data/audio/cache_download_task.dart';
import 'package:bili_audio/data/audio/caching_stream_audio_source.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 模拟 CDN: 支持 Range, 分块慢速输出, 可配置 403
class _FakeCdn implements HttpClientAdapter {
  _FakeCdn(this.data, {this.contentType = 'audio/mp4'});

  final Uint8List data;
  String contentType;
  final requests = <RequestOptions>[];
  final forbiddenUrls = <String>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? _,
    Future<void>? _,
  ) async {
    requests.add(o);
    if (forbiddenUrls.contains(o.uri.toString())) {
      return ResponseBody.fromString('', 403);
    }
    final range = o.headers['Range'] as String?;
    final start = range == null
        ? 0
        : int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
    final body = data.sublist(start);
    Stream<Uint8List> chunks() async* {
      for (var i = 0; i < body.length; i += 1000) {
        await Future<void>.delayed(Duration.zero);
        yield body.sublist(i, (i + 1000).clamp(0, body.length));
      }
    }

    return ResponseBody(
      chunks(),
      range == null ? 200 : 206,
      headers: {
        Headers.contentLengthHeader: ['${body.length}'],
        Headers.contentTypeHeader: [contentType],
        if (range != null)
          'content-range': ['bytes $start-${data.length - 1}/${data.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late AudioCacheStore store;
  late _FakeCdn cdn;
  late CacheDownloadManager manager;
  final data = Uint8List.fromList(List.generate(10000, (i) => i % 251));

  setUp(() async {
    db = AppDatabase.memory();
    dir = await Directory.systemTemp.createTemp('caching_');
    store = AudioCacheStore(db, dir, limitBytes: () async => 1 << 30);
    cdn = _FakeCdn(data);
    manager = CacheDownloadManager(store, Dio()..httpClientAdapter = cdn);
  });

  tearDown(() async {
    manager.cancelAll();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<List<int>> collect(Stream<List<int>> s) async =>
      (await s.toList()).expand((e) => e).toList();

  test('完整下载后 finalize, 文件内容一致且携带 Referer', () async {
    final task = manager.start(key: 'k', url: 'https://cdn/a');
    await task.run();

    expect(await store.completed('k'), isNotNull);
    expect(await store.completeFile('k').readAsBytes(), data);
    expect(cdn.requests.first.headers['Referer'], 'https://www.bilibili.com');
  });

  test('下载过程中可读取任意范围 (边听边存)', () async {
    final task = manager.start(key: 'k', url: 'https://cdn/a');
    final bytes = await collect(task.read(4000, 6000));
    expect(bytes, data.sublist(4000, 6000));
  });

  test('已有 .tmp 时断点续传 (Range)', () async {
    await store.tmpFile('k').writeAsBytes(data.sublist(0, 3000));
    final task = manager.start(key: 'k', url: 'https://cdn/a');
    await task.run();

    expect(cdn.requests.single.headers['Range'], 'bytes=3000-');
    expect(await store.completeFile('k').readAsBytes(), data);
  });

  test('CDN 403 时刷新地址后重试', () async {
    cdn.forbiddenUrls.add('https://cdn/expired');
    var refreshed = 0;
    final task = manager.start(
      key: 'k',
      url: 'https://cdn/expired',
      refreshUrl: () async {
        refreshed++;
        return 'https://cdn/fresh';
      },
    );
    await task.run();
    expect(refreshed, 1);
    expect(task.done, true);
  });

  test('音频源: 缓存完整命中时不解析地址、不发请求', () async {
    await manager.start(key: 'k', url: 'https://cdn/a').run();
    cdn.requests.clear();
    var resolved = 0;
    final source = CachingStreamAudioSource(
      cacheKey: 'k',
      resolveUrl: () async {
        resolved++;
        return 'https://cdn/a';
      },
      downloads: manager,
    );

    final res = await source.request(100, 200);

    expect(await collect(res.stream), data.sublist(100, 200));
    expect(res.sourceLength, data.length);
    expect(resolved, 0);
    expect(cdn.requests, isEmpty);
  });

  test('CDN 的 octet-stream 不传给播放器', () async {
    cdn.contentType = 'application/octet-stream';
    final source = CachingStreamAudioSource(
      cacheKey: 'k',
      resolveUrl: () async => 'https://cdn/a',
      downloads: manager,
    );

    final res = await source.request();

    expect(res.contentType, 'audio/mp4');
    expect(mediaContentType('video/mp4; charset=binary'), 'video/mp4');
    expect(mediaContentType('audio/flac'), 'audio/flac');
  });

  test('音频源: 未缓存时流式返回并在后台写满缓存', () async {
    final source = CachingStreamAudioSource(
      cacheKey: 'k',
      resolveUrl: () async => 'https://cdn/a',
      downloads: manager,
    );
    final res = await source.request();
    expect(await collect(res.stream), data);

    // 等待后台任务 finalize
    for (var i = 0; i < 100 && await store.completed('k') == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(await store.completed('k'), isNotNull);
  });

  test('两首歌并发下载互不阻塞', () async {
    final a = manager.start(key: 'a', url: 'https://cdn/a');
    final b = manager.start(key: 'b', url: 'https://cdn/b');
    await Future.wait([a.run(), b.run()]);
    expect(await store.completed('a'), isNotNull);
    expect(await store.completed('b'), isNotNull);
  });
}
