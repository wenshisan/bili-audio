// ============================================================
// 转写详情数据模型 (transcription_detail_screen.dart)
//
// 字段映射 (来自 getTextRecordinglList 响应 textRecord 数组元素):
//   textId       → (CSV 未给,使用 index 顺序)
//   speakerName  → speaker (mutable: 支持 updateSpeakerName 改名)
//   startTime    → time (秒) + timeText ("00:05")
//   text         → text (mutable: 支持 updateTextRecordinglList 改文)
//   textTrans    → translation
// ============================================================
import '../utils/api_formatters.dart';

class DialogueBlock {
  final int index;
  String speaker;
  final int time;
  final String timeText;
  String text;
  final String translation;
  final String? textId; // 后端 ID,改名/改文时回传

  DialogueBlock({
    required this.index,
    required this.speaker,
    required this.time,
    required this.timeText,
    required this.text,
    required this.translation,
    this.textId,
  });

  factory DialogueBlock.fromJson(Map<String, dynamic> json, {required int index}) {
    final timeSec = asInt(json['startTime']);
    return DialogueBlock(
      index: index,
      speaker: asString(json['speakerName'] ?? json['speaker'], fallback: '发言人'),
      time: timeSec,
      timeText: asString(
        json['timeText'],
        fallback: formatTimecode(timeSec),
      ),
      text: asString(json['text']),
      translation: asString(json['textTrans'] ?? json['translation']),
      textId: json['textId'] as String?,
    );
  }
}
