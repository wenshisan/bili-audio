// ============================================================
// 设备条目 (device_list.dart / device_detail_offline.dart)
//
// 字段映射 (来自 /sl/app/recording-device/list 响应):
//   deviceSN     → id + serialNumber
//   deviceName   → name
//   deviceToken  → (后端返回,保留作未来推/拉指令使用,目前不上屏)
//   connected    → 默认 false,真实连态由蓝牙插件刷新
//   productLine  → CSV 未给,目前默认 null
// ============================================================
import '../utils/api_formatters.dart';

class DeviceItem {
  final String id;
  final String name;
  final String serialNumber;
  final String? deviceToken;
  bool connected;
  final String? productLine; // 'note' | 'power' | 'audio'

  DeviceItem({
    required this.id,
    required this.name,
    required this.serialNumber,
    this.deviceToken,
    this.connected = false,
    this.productLine,
  });

  factory DeviceItem.fromJson(Map<String, dynamic> json) {
    final sn = asString(json['deviceSN'] ?? json['deviceSn']);
    return DeviceItem(
      id: sn, // 设备自然 ID = serialNumber
      name: asString(json['deviceName'], fallback: sn),
      serialNumber: sn,
      deviceToken: json['deviceToken'] as String?,
      connected: false, // 后端 list 不含连态,默认离线;由蓝牙插件刷新
      productLine: json['productLine'] as String?,
    );
  }
}

// 固件升级信息 (firmware_update.dart)
class FirmwareInfo {
  final String version;
  final String packageSizeText;
  final String estimatedTimeText;
  final List<String> releaseNotes;
  final int estimatedSeconds;

  const FirmwareInfo({
    required this.version,
    required this.packageSizeText,
    required this.estimatedTimeText,
    required this.releaseNotes,
    required this.estimatedSeconds,
  });

  /// 通用 fromJson — 兼容后端两种常见字段命名
  /// - `version` / `firmwareVersion` / `firmwareVersionName`
  /// - `packageSize` (bytes) 或 `packageSizeText` (已格式化)
  /// - `estimatedTime` (seconds) 或 `estimatedTimeText` (已格式化)
  /// - `releaseNotes` (List<String> 或 String[] 字符串数组)
  factory FirmwareInfo.fromJson(Map<String, dynamic> json) {
    final version = asString(
      json['version'] ?? json['firmwareVersion'] ?? json['firmwareVersionName'],
    );

    int? packageSizeBytes = asInt(json['packageSize']).let((v) => v == 0 ? null : v);
    final packageSizeText = asString(
      json['packageSizeText'],
      fallback: packageSizeBytes != null ? _humanSize(packageSizeBytes) : '',
    );

    final estimatedSeconds = asInt(json['estimatedTime']);
    final estimatedTimeText = asString(
      json['estimatedTimeText'],
      fallback: formatDuration(estimatedSeconds),
    );

    final notesRaw = json['releaseNotes'];
    final releaseNotes = notesRaw is List
        ? notesRaw.map((e) => e.toString()).toList()
        : (notesRaw is String && notesRaw.isNotEmpty ? [notesRaw] : <String>[]);

    return FirmwareInfo(
      version: version,
      packageSizeText: packageSizeText,
      estimatedTimeText: estimatedTimeText,
      releaseNotes: releaseNotes,
      estimatedSeconds: estimatedSeconds,
    );
  }
}

// 包体大小 → 可读字符串 (4.2MB / 1.1GB / 256KB)
String _humanSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
}

// 简易 .let 扩展 (与 Kotlin 类似),让上述链式判断更紧凑
extension _Let<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}
