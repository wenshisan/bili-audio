import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 统一管理本地文件目录: 音频缓存 / 封面 / 歌词 / 数据库。
///
/// 启动时调用一次 [init], 之后通过静态 getter 同步访问。
/// 缓存根目录后续可由设置项覆盖 (见 dev-tasks M3.5)。
class PathManager {
  PathManager._();

  static late Directory _cacheRoot;
  static late Directory _supportRoot;

  static Directory get audioDir => Directory('${_cacheRoot.path}/audio');
  static Directory get coversDir => Directory('${_cacheRoot.path}/covers');
  static Directory get lyricsDir => Directory('${_supportRoot.path}/lyrics');
  static Directory get logsDir => Directory('${_supportRoot.path}/logs');
  static File get databaseFile =>
      File('${_supportRoot.path}/bili_audio.sqlite');

  static Future<void> init({String? customCacheRoot}) async {
    _supportRoot = await getApplicationSupportDirectory();
    _cacheRoot = customCacheRoot != null
        ? Directory(customCacheRoot)
        : await getApplicationCacheDirectory();

    for (final dir in [audioDir, coversDir, lyricsDir]) {
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    }
  }
}
