import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/domain/cache/lru_policy.dart';

void main() {
  const policy = LruPolicy();

  CacheEntry entry(String key, int size, int lastPlayedAt,
          {bool pinned = false}) =>
      CacheEntry(
        key: key,
        size: size,
        lastPlayedAt: lastPlayedAt,
        pinned: pinned,
      );

  group('LruPolicy', () {
    test('空间刚好够时不删除', () {
      final result = policy.evict(
        entries: [entry('a', 40, 1), entry('b', 40, 2)],
        limit: 100,
        incomingSize: 20,
      );
      expect(result.toEvict, isEmpty);
      expect(result.overQuota, false);
    });

    test('按最久未播放顺序删除', () {
      final result = policy.evict(
        entries: [entry('new', 40, 3), entry('old', 40, 1), entry('mid', 40, 2)],
        limit: 100,
        incomingSize: 30,
      );
      // 已用 120 + 写入 30 - 上限 100 = 超出 50, 需删两条
      expect(result.toEvict.map((e) => e.key), ['old', 'mid']);
      expect(result.freedBytes, 80);
      expect(result.overQuota, false);
    });

    test('跳过 pinned 条目', () {
      final result = policy.evict(
        entries: [entry('pin', 50, 1, pinned: true), entry('b', 50, 2)],
        limit: 60,
      );
      expect(result.toEvict.map((e) => e.key), ['b']);
      expect(result.overQuota, false);
    });

    test('全部 pinned 时返回 overQuota', () {
      final result = policy.evict(
        entries: [
          entry('a', 50, 1, pinned: true),
          entry('b', 50, 2, pinned: true),
        ],
        limit: 60,
      );
      expect(result.toEvict, isEmpty);
      expect(result.overQuota, true);
    });

    test('跳过当前播放 / 正在下载项', () {
      final result = policy.evict(
        entries: [entry('playing', 50, 1), entry('b', 50, 2)],
        limit: 60,
        protectedKeys: {'playing'},
      );
      expect(result.toEvict.map((e) => e.key), ['b']);
    });

    test('并发写入预留空间', () {
      // 两个下载并发: 各自预留 30, 第二次计算时把第一次的预留计入 incomingSize
      final entries = [entry('a', 30, 1), entry('b', 30, 2), entry('c', 30, 3)];
      final result = policy.evict(
        entries: entries,
        limit: 100,
        incomingSize: 60,
      );
      expect(result.toEvict.map((e) => e.key), ['a', 'b']);
    });
  });
}
