/// 缓存条目 (M1.7)
class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.size,
    required this.lastPlayedAt,
    this.pinned = false,
  });

  final String key;

  /// 文件大小 (字节)
  final int size;

  /// 最后播放时间 (Unix timestamp)
  final int lastPlayedAt;

  /// 是否受保护 (歌单内歌曲)
  final bool pinned;
}

/// 淘汰结果 (M1.7)
class EvictionResult {
  const EvictionResult({required this.toEvict, required this.overQuota});

  /// 待删除条目 (按最久未播放排序)
  final List<CacheEntry> toEvict;

  /// 删除所有可删项后仍超出上限 (pinned 总量过大), 供 UI 提示
  final bool overQuota;

  int get freedBytes => toEvict.fold(0, (sum, e) => sum + e.size);
}

/// LRU 淘汰策略 (M1.7, 纯算法)
class LruPolicy {
  const LruPolicy();

  /// 计算为写入 [incomingSize] 字节需要淘汰的条目
  ///
  /// - [limit]: 缓存上限 (字节)
  /// - [protectedKeys]: 当前播放 / 正在下载的条目, 不可删除
  EvictionResult evict({
    required List<CacheEntry> entries,
    required int limit,
    int incomingSize = 0,
    Set<String> protectedKeys = const {},
  }) {
    final used = entries.fold<int>(0, (sum, e) => sum + e.size);
    var excess = used + incomingSize - limit;
    if (excess <= 0) {
      return const EvictionResult(toEvict: [], overQuota: false);
    }

    final candidates = entries
        .where((e) => !e.pinned && !protectedKeys.contains(e.key))
        .toList()
      ..sort((a, b) => a.lastPlayedAt.compareTo(b.lastPlayedAt));

    final toEvict = <CacheEntry>[];
    for (final entry in candidates) {
      if (excess <= 0) break;
      toEvict.add(entry);
      excess -= entry.size;
    }

    return EvictionResult(toEvict: toEvict, overQuota: excess > 0);
  }
}
