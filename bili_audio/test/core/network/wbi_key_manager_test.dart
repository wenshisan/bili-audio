import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/core/network/wbi_key_manager.dart';

void main() {
  group('WbiKeyManager', () {
    test('首次获取调用 fetch', () async {
      var fetchCount = 0;
      Future<(String, String)> fetch() async {
        fetchCount++;
        return (
          'https://example.com/img/testimg123.png',
          'https://example.com/sub/testsub456.png'
        );
      }

      final manager = WbiKeyManager(fetch);

      final key = await manager.mixinKey();
      expect(key, isNotEmpty);
      expect(fetchCount, 1);
    });

    test('TTL 内复用缓存', () async {
      var fetchCount = 0;
      Future<(String, String)> fetch() async {
        fetchCount++;
        return (
          'https://example.com/img/testimg123.png',
          'https://example.com/sub/testsub456.png'
        );
      }

      final manager = WbiKeyManager(fetch);

      await manager.mixinKey();
      await manager.mixinKey();
      await manager.mixinKey();

      expect(fetchCount, 1);
    });

    test('TTL 过期后重新 fetch', () async {
      var fetchCount = 0;
      var now = DateTime(2024, 1, 1);

      Future<(String, String)> fetch() async {
        fetchCount++;
        return (
          'https://example.com/img/testimg$fetchCount.png',
          'https://example.com/sub/testsub$fetchCount.png'
        );
      }

      final manager = WbiKeyManager(
        fetch,
        clock: () => now,
        ttl: const Duration(hours: 1),
      );

      await manager.mixinKey();
      expect(fetchCount, 1);

      // 推进 2 小时
      now = now.add(const Duration(hours: 2));
      await manager.mixinKey();

      expect(fetchCount, 2);
    });

    test('并发调用合并为一次请求', () async {
      var fetchCount = 0;
      Future<(String, String)> fetch() async {
        fetchCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return (
          'https://example.com/img/testimg.png',
          'https://example.com/sub/testsub.png'
        );
      }

      final manager = WbiKeyManager(fetch);

      final futures = List.generate(10, (_) => manager.mixinKey());
      await Future.wait(futures);

      expect(fetchCount, 1);
    });

    test('invalidate 清除缓存', () async {
      var fetchCount = 0;
      Future<(String, String)> fetch() async {
        fetchCount++;
        return (
          'https://example.com/img/testimg$fetchCount.png',
          'https://example.com/sub/testsub$fetchCount.png'
        );
      }

      final manager = WbiKeyManager(fetch);

      await manager.mixinKey();
      expect(fetchCount, 1);

      manager.invalidate();
      await manager.mixinKey();

      expect(fetchCount, 2);
    });
  });
}
