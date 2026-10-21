import 'package:dio/dio.dart';

import 'audio_cache_store.dart';
import 'cache_download_task.dart';

/// 下载任务登记处 (M3.2)
///
/// 同一 cacheKey 只存在一个下载任务, 播放与批量缓存共享;
/// 不同 key 互不阻塞。
class CacheDownloadManager {
  CacheDownloadManager(this.store, this.dio);

  final AudioCacheStore store;
  final Dio dio;
  final Map<String, CacheDownloadTask> _tasks = {};

  /// 当前播放项, LRU 淘汰时受保护
  String? playingKey;

  Set<String> get activeKeys => {..._tasks.keys, ?playingKey};

  CacheDownloadTask? taskFor(String key) => _tasks[key];

  /// 获取或启动下载任务; 已完成/失败的任务会被替换
  CacheDownloadTask start({
    required String key,
    required String url,
    Future<String> Function()? refreshUrl,
  }) {
    final existing = _tasks[key];
    if (existing != null && existing.error == null && !existing.done) {
      return existing;
    }
    final task = CacheDownloadTask(
      key: key,
      url: url,
      store: store,
      dio: dio,
      refreshUrl: refreshUrl,
      protectedKeys: () => activeKeys,
    );
    _tasks[key] = task;
    task.run().whenComplete(() {
      if (identical(_tasks[key], task)) _tasks.remove(key);
    });
    return task;
  }

  void cancel(String key) => _tasks.remove(key)?.cancel();

  void cancelAll() {
    for (final t in _tasks.values) {
      t.cancel();
    }
    _tasks.clear();
  }
}
