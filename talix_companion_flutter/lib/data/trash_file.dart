// ============================================================
// 回收站文件数据模型 (Figma 1218:9817 Table-Header / Table-Body)
//
// 字段映射 (来自 /sl/app/recycled-file/list 响应,power接口需求(2).csv):
//   fileId       → id
//   fileName     → title
//   deleteTime   → dateText (毫秒 → "5月6日 09:22")
//   createTime   → 备用,若 deleteTime 缺失则回退
//   duration     → 回收站不展示时长,改用此字段估 size (后端未来会返 fileSize)
//   deviceId     → deviceSN (CSV(2) 把字段名从 deviceSN 改成了 deviceId,
//                              此处兼容两种命名)
//
// 区别于 RecordingFile: 回收站条目只展示 size (而非 duration),
// 操作仅为 恢复 / 永久删除 / 清空
// ============================================================
import '../utils/api_formatters.dart';

class TrashFile {
  final String id;
  final String title;
  final String dateText; // "5月6日 09:22"
  final String size; // "56K"
  final String? deviceSN; // CSV(2) 字段名为 deviceId,兼容

  // 用于内部撤销 (软删除最近一次被永久删除的文件)
  bool isSelected;

  TrashFile({
    required this.id,
    required this.title,
    required this.dateText,
    required this.size,
    this.deviceSN,
    this.isSelected = false,
  });

  factory TrashFile.fromJson(Map<String, dynamic> json) {
    final id = asString(json['fileId'] ?? json['id']);
    final title = asString(json['fileName'] ?? json['title'], fallback: id);

    // 优先用 deleteTime,缺失则回退 createTime
    final deleteMs = asInt(json['deleteTime']);
    final createMs = asInt(json['createTime']);
    final dateMs = deleteMs > 0 ? deleteMs : createMs;
    final dateText = json['dateText'] is String
        ? json['dateText'] as String
        : (dateMs > 0 ? formatRecycleDate(dateMs) : '');

    // 优先用后端 fileSize (字节) → 人读,否则把 duration(秒) 兜底展示
    final sizeBytes = asInt(json['fileSize']);
    final durationSec = asInt(json['duration']);
    final size = sizeBytes > 0
        ? _humanSize(sizeBytes)
        : (durationSec > 0 ? formatDuration(durationSec) : '');

    // CSV(2) 字段名改成了 deviceId;保留 deviceSN 兼容旧接口
    final deviceSN = asString(
      json['deviceId'] ?? json['deviceSN'] ?? json['deviceSn'],
    );

    return TrashFile(
      id: id,
      title: title,
      dateText: dateText,
      size: size,
      deviceSN: deviceSN.isEmpty ? null : deviceSN,
    );
  }
}

String _humanSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
}
