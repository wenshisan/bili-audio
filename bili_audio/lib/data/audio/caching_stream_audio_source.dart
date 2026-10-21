import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'cache_download_manager.dart';

/// 边听边存音频源 (M3.2, D5)
///
/// 1. `cache_index` 完整命中: 直接读本地文件, 不发网络请求
/// 2. 否则启动/复用 [CacheDownloadManager] 的顺序下载任务,
///    范围请求从已下载部分读取, 未到达的部分等待下载进度
/// 3. 中断或切歌时 `.tmp` 保留, 下次断点续传
class CachingStreamAudioSource extends StreamAudioSource {
  CachingStreamAudioSource({
    required this.cacheKey,
    required this.resolveUrl,
    required this.downloads,
    this.refreshUrl,
    super.tag,
  });

  final String cacheKey;

  /// 懒加载流地址: 缓存命中时不会被调用
  final Future<String> Function() resolveUrl;
  final Future<String> Function()? refreshUrl;
  final CacheDownloadManager downloads;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final store = downloads.store;
    final file = await store.completed(cacheKey);
    if (file != null) {
      unawaited(store.touch(cacheKey));
      final length = await file.length();
      final s = start ?? 0;
      final e = (end ?? length).clamp(s, length);
      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: start != null ? length : null,
        contentLength: e - s,
        offset: start,
        contentType: 'audio/mp4',
        stream: file.openRead(s, e),
      );
    }

    final task = downloads.taskFor(cacheKey) ??
        downloads.start(
          key: cacheKey,
          url: await resolveUrl(),
          refreshUrl: refreshUrl,
        );
    final total = await task.totalLength;
    final s = start ?? 0;
    final e = (end ?? total).clamp(s, total);
    return StreamAudioResponse(
      rangeRequestsSupported: true,
      sourceLength: start != null ? total : null,
      contentLength: e - s,
      offset: start,
      contentType: task.mime,
      stream: task.read(s, e),
    );
  }
}
