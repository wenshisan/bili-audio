import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/core/network/buvid_manager.dart';
import 'package:bili_audio/core/storage/secure_store.dart';

void main() {
  group('BuvidManager', () {
    test('从存储读取已有 buvid', () async {
      final store = MemorySecureStore();
      await store.write('buvid3', 'stored-b3');
      await store.write('buvid4', 'stored-b4');

      var fetchCalled = false;
      Future<(String, String)> fetch() async {
        fetchCalled = true;
        return ('fetched-b3', 'fetched-b4');
      }

      final manager = BuvidManager(store, fetch);
      final (b3, b4) = await manager.get();

      expect(b3, 'stored-b3');
      expect(b4, 'stored-b4');
      expect(fetchCalled, false);
    });

    test('存储为空时调用 fetch', () async {
      final store = MemorySecureStore();

      Future<(String, String)> fetch() async {
        return ('fetched-b3', 'fetched-b4');
      }

      final manager = BuvidManager(store, fetch);
      final (b3, b4) = await manager.get();

      expect(b3, 'fetched-b3');
      expect(b4, 'fetched-b4');

      // 验证已持久化
      expect(await store.read('buvid3'), 'fetched-b3');
      expect(await store.read('buvid4'), 'fetched-b4');
    });

    test('fetch 失败时本地生成', () async {
      final store = MemorySecureStore();

      Future<(String, String)> fetch() async {
        throw Exception('Network error');
      }

      final manager = BuvidManager(
        store,
        fetch,
        random: Random(42), // 固定种子
      );

      final (b3, b4) = await manager.get();

      expect(b3, isNotEmpty);
      expect(b4, isNotEmpty);

      // 格式验证
      expect(b3.contains('-'), true);
      expect(b4.contains('-'), true);

      // 已持久化
      expect(await store.read('buvid3'), b3);
      expect(await store.read('buvid4'), b4);
    });

    test('并发调用合并为一次请求', () async {
      final store = MemorySecureStore();
      var fetchCount = 0;

      Future<(String, String)> fetch() async {
        fetchCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return ('fetched-b3', 'fetched-b4');
      }

      final manager = BuvidManager(store, fetch);

      final futures = List.generate(5, (_) => manager.get());
      await Future.wait(futures);

      expect(fetchCount, 1);
    });

    test('第二次调用返回缓存', () async {
      final store = MemorySecureStore();

      var fetchCount = 0;
      Future<(String, String)> fetch() async {
        fetchCount++;
        return ('fetched-b3', 'fetched-b4');
      }

      final manager = BuvidManager(store, fetch);

      await manager.get();
      await manager.get();
      await manager.get();

      expect(fetchCount, 1);
    });
  });
}
