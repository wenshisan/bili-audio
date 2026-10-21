import 'dart:io';

import 'package:bili_audio/data/audio/audio_cache_store.dart';
import 'package:bili_audio/data/audio/cache_migrator.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late AppDatabase db;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('migrate_');
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  test('迁移后新目录可命中缓存, 旧目录清空', () async {
    final oldDir = Directory(p.join(root.path, 'old'))..createSync();
    final newDir = Directory(p.join(root.path, 'new'));
    final oldStore = AudioCacheStore(db, oldDir, limitBytes: () async => 1 << 30);
    await oldStore.tmpFile('k').writeAsBytes([1, 2, 3]);
    await oldStore.finalize('k', 3);
    await oldStore.tmpFile('partial').writeAsBytes([9]);
    File(p.join(oldDir.path, 'other.txt')).writeAsStringSync('keep');

    final progress = <int>[];
    final moved = await const CacheMigrator()
        .migrate(oldDir, newDir, onProgress: (d, _) => progress.add(d));

    expect(moved, 2);
    expect(progress, [1, 2]);
    final newStore = AudioCacheStore(db, newDir, limitBytes: () async => 1 << 30);
    expect(await newStore.completed('k'), isNotNull);
    expect(newStore.tmpFile('partial').existsSync(), true);
    expect(oldDir.listSync().map((e) => p.basename(e.path)), ['other.txt']);
  });

  test('源与目标相同时不操作', () async {
    expect(await const CacheMigrator().migrate(root, root), 0);
  });

  test('设置项: 自定义缓存目录读写', () async {
    expect(await db.settingsDao.getCacheDir(), isNull);
    await db.settingsDao.setCacheDir('D:/cache');
    expect(await db.settingsDao.getCacheDir(), 'D:/cache');
    await db.settingsDao.setCacheDir(null);
    expect(await db.settingsDao.getCacheDir(), isNull);
  });
}
