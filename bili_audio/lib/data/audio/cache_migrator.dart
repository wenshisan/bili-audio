import 'dart:io';

import 'package:path/path.dart' as p;

/// 迁移进度 (已处理文件数, 总文件数)
typedef MigrationProgress = void Function(int done, int total);

/// 缓存目录迁移 (M3.5)
///
/// `cache_index` 只存文件名, 迁移只需移动文件, 无需改索引。
/// 跨盘符时 rename 失败, 回退为复制后删除。
class CacheMigrator {
  const CacheMigrator();

  /// 将 [from] 下的缓存文件移动到 [to]; 返回成功移动的文件数
  ///
  /// 目标已存在同名文件时跳过 (保留目标文件, 删除源文件)。
  Future<int> migrate(
    Directory from,
    Directory to, {
    MigrationProgress? onProgress,
  }) async {
    if (p.equals(from.path, to.path) || !from.existsSync()) return 0;
    await to.create(recursive: true);

    final files = from
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.audio') || f.path.endsWith('.tmp'))
        .toList();

    var moved = 0;
    for (var i = 0; i < files.length; i++) {
      final src = files[i];
      final dst = File(p.join(to.path, p.basename(src.path)));
      if (dst.existsSync()) {
        await src.delete();
      } else {
        await _move(src, dst);
        moved++;
      }
      onProgress?.call(i + 1, files.length);
    }
    return moved;
  }

  Future<void> _move(File src, File dst) async {
    try {
      await src.rename(dst.path);
    } on FileSystemException {
      await src.copy(dst.path);
      await src.delete();
    }
  }
}
