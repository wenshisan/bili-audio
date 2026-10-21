import 'dart:io';

import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late AudioCacheStore store;
  var limit = 100;
  var now = DateTime(2024);

  setUp(() async {
    db = AppDatabase.memory();
    dir = await Directory.systemTemp.createTemp('cache_store_');
    limit = 100;
    store = AudioCacheStore(db, dir,
        limitBytes: () async => limit, clock: () => now);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<void> putComplete(String key, int size, {bool pinned = false}) async {
    await store.tmpFile(key).writeAsBytes(List.filled(size, 1));
    await store.finalize(key, size);
    if (pinned) await db.cacheDao.setPinned(key, true);
  }

  test('finalize 改名并标记完整, completed 命中', () async {
    await putComplete('k1', 10);

    expect(store.tmpFile('k1').existsSync(), false);
    final file = await store.completed('k1');
    expect(file!.lengthSync(), 10);
    final row = await db.cacheDao.getCacheEntry('k1');
    expect(row!.complete, true);
    expect(row.filePath, 'k1.audio'); // 相对路径
  });

  test('索引完整但文件丢失时修正索引', () async {
    await putComplete('k1', 10);
    await store.completeFile('k1').delete();

    expect(await store.completed('k1'), isNull);
    expect(await db.cacheDao.getCacheEntry('k1'), isNull);
  });

  test('recordPartial 记录下载进度', () async {
    await store.recordPartial('k1', 30, 100);
    final row = await db.cacheDao.getCacheEntry('k1');
    expect(row!.complete, false);
    expect(row.downloadedBytes, 30);
    expect(await store.completed('k1'), isNull);
  });

  test('ensureSpace 淘汰最久未播放的非 pinned 条目并删除文件', () async {
    now = DateTime(2020);
    await putComplete('old', 40);
    now = DateTime(2024);
    await putComplete('pinned', 40, pinned: true);
    await putComplete('new', 10);

    final result = await store.ensureSpace(30);

    expect(result.toEvict.map((e) => e.key), ['old']);
    expect(result.overQuota, false);
    expect(store.completeFile('old').existsSync(), false);
    expect(store.completeFile('pinned').existsSync(), true);
  });

  test('pinned 总量超上限时返回 overQuota 且不删除', () async {
    await putComplete('p', 90, pinned: true);
    final result = await store.ensureSpace(50);
    expect(result.toEvict, isEmpty);
    expect(result.overQuota, true);
  });

  test('protectedKeys 不被淘汰', () async {
    await putComplete('playing', 90);
    final result = await store.ensureSpace(50, protectedKeys: {'playing'});
    expect(result.toEvict, isEmpty);
  });

  test('clearUnpinned 删除文件与索引, 保留 pinned 和受保护项', () async {
    await putComplete('a', 10);
    await putComplete('p', 10, pinned: true);
    await putComplete('playing', 10);

    expect(await store.stats(), (3, 30));
    final n = await store.clearUnpinned(protectedKeys: {'playing'});

    expect(n, 1);
    expect(store.completeFile('a').existsSync(), false);
    expect(store.completeFile('p').existsSync(), true);
    expect(store.completeFile('playing').existsSync(), true);
    expect(await store.stats(), (2, 20));
  });
}
