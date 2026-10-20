import 'package:drift/drift.dart';

/// 音频轨道表
class Tracks extends Table {
  TextColumn get bvid => text()();
  IntColumn get cid => integer()();

  TextColumn get title => text()(); // B站原始标题
  TextColumn get cleanedName => text().nullable()(); // 清洗后歌名
  TextColumn get artist => text().nullable()(); // 清洗后歌手
  BoolColumn get userEdited => boolean().withDefault(const Constant(false))(); // 用户是否手动编辑

  IntColumn get duration => integer()(); // 秒
  TextColumn get cover => text().nullable()();
  TextColumn get uploader => text().nullable()();
  IntColumn get pageIndex => integer().nullable()(); // 分P序号 (1-based)
  IntColumn get totalPages => integer().nullable()(); // 总分P数

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {bvid, cid};

  @override
  List<String> get customConstraints => [
    'CHECK(duration > 0)',
    'CHECK(page_index IS NULL OR page_index > 0)',
    'CHECK(total_pages IS NULL OR total_pages > 0)',
  ];
}

/// 歌单表
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get cover => text().nullable()();
  BoolColumn get isReadonly => boolean().withDefault(const Constant(false))(); // B站收藏夹同步的为只读
  TextColumn get source => text().nullable()(); // 'local' | 'bilibili_fav'
  TextColumn get sourceId => text().nullable()(); // B站收藏夹 media_id

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 歌单-轨道关联表
class PlaylistTracks extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get bvid => text()();
  IntColumn get cid => integer()();

  IntColumn get position => integer()(); // 排序位置，从0开始
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {playlistId, bvid, cid};

  @override
  List<String> get customConstraints => [
    'CHECK(position >= 0)',
    'FOREIGN KEY (bvid, cid) REFERENCES tracks(bvid, cid) ON DELETE CASCADE',
  ];
}

/// 播放历史表
class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bvid => text()();
  IntColumn get cid => integer()();

  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get positionMs => integer().withDefault(const Constant(0))(); // 播放到的位置
  RealColumn get completion => real().withDefault(const Constant(0.0))(); // 完成度 0.0-1.0
  TextColumn get source => text().nullable()(); // 'search' | 'playlist' | 'history'

  @override
  List<String> get customConstraints => [
    'CHECK(position_ms >= 0)',
    'CHECK(completion >= 0.0 AND completion <= 1.0)',
    'FOREIGN KEY (bvid, cid) REFERENCES tracks(bvid, cid) ON DELETE CASCADE',
  ];
}

/// 歌词缓存表
class LyricsCache extends Table {
  TextColumn get bvid => text()();
  IntColumn get cid => integer()();

  TextColumn get lrcPath => text().nullable()(); // 本地LRC文件路径，相对于lyrics目录
  TextColumn get source => text().nullable()(); // 'lrclib' | 'bilibili_cc' | 'manual'
  RealColumn get matchScore => real().nullable()();
  IntColumn get offsetMs => integer().withDefault(const Constant(0))(); // 用户校准偏移量
  BoolColumn get noLyrics => boolean().withDefault(const Constant(false))(); // 标记为无歌词

  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {bvid, cid};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (bvid, cid) REFERENCES tracks(bvid, cid) ON DELETE CASCADE',
  ];
}

/// 音频缓存索引表
class CacheIndex extends Table {
  TextColumn get cacheKey => text()(); // ${bvid}_${cid}_${quality_id}

  TextColumn get filePath => text()(); // 相对于audio目录的路径
  IntColumn get fileSize => integer()(); // 字节
  BoolColumn get complete => boolean().withDefault(const Constant(false))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();

  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))(); // 歌单内的歌曲标记为pinned

  @override
  Set<Column> get primaryKey => {cacheKey};

  @override
  List<String> get customConstraints => [
    'CHECK(file_size >= 0)',
    'CHECK(downloaded_bytes >= 0)',
    'CHECK(downloaded_bytes <= file_size)',
  ];
}

/// 流地址缓存表
@DataClassName('StreamUrlRow')
class StreamUrls extends Table {
  TextColumn get bvid => text()();
  IntColumn get cid => integer()();
  IntColumn get quality => integer()(); // DASH audio id

  TextColumn get url => text()();
  TextColumn get backupUrls => text().withDefault(const Constant(''))(); // JSON数组
  TextColumn get mime => text()();
  IntColumn get bandwidth => integer().nullable()();
  DateTimeColumn get expiresAt => dateTime()();

  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {bvid, cid, quality};

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (bvid, cid) REFERENCES tracks(bvid, cid) ON DELETE CASCADE',
  ];
}

/// 队列快照表 (单行)
class QueueSnapshot extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))(); // 固定为1

  TextColumn get originalQueue => text()(); // JSON数组: [Track, ...]
  TextColumn get currentOrder => text()(); // JSON数组: [index, ...]
  IntColumn get cursor => integer()();
  TextColumn get mode => text()(); // 'sequential' | 'listLoop' | ...
  IntColumn get seed => integer()();
  TextColumn get history => text()(); // JSON数组: [index, ...]
  IntColumn get positionMs => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK(id = 1)', // 强制单行
  ];
}

/// 设置表 (简单KV)
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
