import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/tracks_dao.dart';
import 'daos/playlists_dao.dart';
import 'daos/cache_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/stream_urls_dao.dart';
import 'daos/history_dao.dart';

part 'app_database.g.dart';

/// 应用数据库，包含所有业务表
@DriftDatabase(
  tables: [
    Tracks,
    Playlists,
    PlaylistTracks,
    PlayHistory,
    LyricsCache,
    CacheIndex,
    StreamUrls,
    QueueSnapshot,
    Settings,
  ],
  daos: [
    TracksDao,
    PlaylistsDao,
    CacheDao,
    SettingsDao,
    StreamUrlsDao,
    HistoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 用于测试的内存数据库
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本的迁移逻辑
      },
      beforeOpen: (details) async {
        // 启用外键约束
        await customStatement('PRAGMA foreign_keys = ON;');

        if (details.wasCreated) {
          // 插入默认设置
          await into(settings).insert(
            SettingsCompanion.insert(
              key: 'theme_mode',
              value: 'system',
            ),
          );
          await into(settings).insert(
            SettingsCompanion.insert(
              key: 'theme_seed',
              value: '0xFF2196F3', // blue
            ),
          );
          await into(settings).insert(
            SettingsCompanion.insert(
              key: 'cache_max_size',
              value: '1073741824', // 1GB
            ),
          );
          await into(settings).insert(
            SettingsCompanion.insert(
              key: 'default_quality',
              value: '30232', // 132K
            ),
          );
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bili_audio', 'app.db'));

    // 确保目录存在
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return NativeDatabase.createInBackground(file);
  });
}
