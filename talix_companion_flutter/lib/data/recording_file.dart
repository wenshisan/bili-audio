// ============================================================
// 录音文件数据模型 (Figma 1218:5609 record-item)
//
// 字段映射 (来自 /sl/app/recording-file/list 响应):
//   fileId        → id
//   fileName      → title
//   createTime    → dateText (毫秒 → "今天 21:22" / "5月6日 09:22")
//   duration      → "25分钟" / "56分钟" (秒 → 已格式化)
//   status (int)  → fileStatus (内部值) + statusText (UI 文本)
//   deviceSN      → 用于推断 sourceLabel ("设备" / "手机")
//
// UI 字段约定:
//   - title: 录音标题 (15px / #333333)
//   - dateText: "今天 21:22" / "5月6日 09:22" (12px / #A1A1A1)
//   - duration: "25分钟" / "56分钟" (完成态) - null 时表示正在转写
//   - statusText: "正在转写" / "正在同步至手机" / "等待同步至手机" - 状态文本
//   - sourceLabel: '设备' | '手机' (仅 all 视图显示)
//   - failureReason: 失败原因
//   - fileStatus: 'completed' | 'transcribing' | 'failed' | 'waiting' | 'pending'
//     'pending' (Figma 1218:6792) 表示录音文件已同步但尚未生成转写,
//     详情页显示 "转写未生成" 占位页, 点击 "生成" 触发转写流程
// ============================================================
import '../utils/api_formatters.dart';

class RecordingFile {
  final String id;
  String title;
  final String dateText;
  final String? duration; // '25分钟' / '56分钟' / '136分钟' - 完成态
  final String? statusText; // '正在转写' / '正在同步至手机' / '等待同步至手机' - 状态文本
  String?
      fileStatus; // 'completed' | 'transcribing' | 'failed' | 'waiting' | 'pending' - 内部状态
  String? sourceLabel; // '设备' | '手机' (用于 'all' 视图)
  String? failureReason;
  bool isSelected;
  final String? deviceSN; // 原始字段,用于详情跳转

  RecordingFile({
    required this.id,
    required this.title,
    required this.dateText,
    this.duration,
    this.statusText,
    this.fileStatus = 'completed',
    this.sourceLabel,
    this.failureReason,
    this.isSelected = false,
    this.deviceSN,
  });

  factory RecordingFile.fromJson(Map<String, dynamic> json) {
    final id = asString(json['fileId'] ?? json['id']);
    final title = asString(json['fileName'] ?? json['title'], fallback: id);
    final createMs = asInt(json['createTime']);
    final dateText = json['dateText'] is String
        ? json['dateText'] as String
        : (createMs > 0 ? formatChatDate(createMs) : '');

    final durationSec = asInt(json['duration']);
    final fileStatus = mapFileStatusToInternal(json['status']);
    final statusText = mapFileStatusToText(fileStatus);

    return RecordingFile(
      id: id,
      title: title,
      dateText: dateText,
      duration: fileStatus == 'completed' ? formatDuration(durationSec) : null,
      statusText: statusText,
      fileStatus: fileStatus,
      failureReason: json['failureReason'] as String?,
      deviceSN: asString(json['deviceSN'] ?? json['deviceSn']),
      // sourceLabel 由 FileManagerViewModel 在合并设备/手机列表时填充
    );
  }
}
