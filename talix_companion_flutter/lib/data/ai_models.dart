// ============================================================
// Ask AI 屏数据模型 (ask_ai_screen.dart)
//
// 字段映射:
// - AiQuickPrompt: 来自 getQuestionList 响应 list 数组 (后端返回纯字符串数组,
//                  前端转换为 id/title/desc/query 四元组以便 UI 渲染)
// - AiDialogue:    Ask AI 屏的对话消息 (前端自行构造,不直接来自后端)
// - AiCitedFile:   askQuestion 响应中可能携带的引用文件 (CSV 未明确,
//                  实际可能需要扩展后端响应)
// - AiSelectableFile: 录音文件选择器 (从 recording-file/list 派生)
// ============================================================
import '../utils/api_formatters.dart';

class AiQuickPrompt {
  final String id;
  final String title;
  final String desc;
  final String query;

  const AiQuickPrompt({
    required this.id,
    required this.title,
    required this.desc,
    required this.query,
  });

  /// 后端 getQuestionList 返回 `data.list = ["为什么", "你说"]`
  /// 把每个字符串包成 UI 用的四元组 (id 用下标,desc 暂时用同 query)
  factory AiQuickPrompt.fromString(int index, String question) {
    return AiQuickPrompt(
      id: 'q$index',
      title: question,
      desc: question,
      query: question,
    );
  }
}

class AiDialogue {
  final String speaker;
  final String timeText;
  final String text;
  final bool isUser; // 区分用户提问与 AI 回答

  const AiDialogue({
    required this.speaker,
    required this.timeText,
    required this.text,
    this.isUser = false,
  });

  /// 构造用户消息
  factory AiDialogue.user(String text) {
    return AiDialogue(
      speaker: '我',
      timeText: _nowText(),
      text: text,
      isUser: true,
    );
  }

  /// 构造 AI 回答消息
  factory AiDialogue.ai(String text, {String speaker = 'Talix AI'}) {
    return AiDialogue(
      speaker: speaker,
      timeText: _nowText(),
      text: text,
      isUser: false,
    );
  }
}

class AiCitedFile {
  final String id;
  final String title;
  final String dateText;
  final String timeText;
  final String sizeText;
  final int durationSec;

  const AiCitedFile({
    required this.id,
    required this.title,
    required this.dateText,
    required this.timeText,
    required this.sizeText,
    required this.durationSec,
  });

  /// 从后端响应 (字段名待定,容错多版本) 构造
  factory AiCitedFile.fromJson(Map<String, dynamic> json) {
    final createMs = asInt(json['createTime']);
    final duration = asInt(json['duration']);
    return AiCitedFile(
      id: asString(json['fileId'] ?? json['id']),
      title: asString(json['fileName'] ?? json['title']),
      dateText: createMs > 0 ? formatChatDate(createMs) : '',
      timeText: asString(json['timeText']),
      sizeText: asString(json['sizeText'] ?? json['fileSizeText']),
      durationSec: duration,
    );
  }
}

class AiSelectableFile {
  final String id;
  final String title;
  final String dateText;
  final String timeText;

  const AiSelectableFile({
    required this.id,
    required this.title,
    required this.dateText,
    required this.timeText,
  });

  /// 录音文件 → 选中态文件 (dateText/timeText 拆分)
  factory AiSelectableFile.fromJson(Map<String, dynamic> json) {
    final createMs = asInt(json['createTime']);
    String dateText = '';
    String timeText = '';
    if (createMs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(createMs);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        dateText = '今天';
        timeText = '${_p2(dt.hour)}:${_p2(dt.minute)}';
      } else {
        dateText = '${dt.month}月${dt.day}日';
        timeText = '${_p2(dt.hour)}:${_p2(dt.minute)}';
      }
    }
    return AiSelectableFile(
      id: asString(json['fileId'] ?? json['id']),
      title: asString(json['fileName'] ?? json['title']),
      dateText: dateText,
      timeText: timeText,
    );
  }
}

String _p2(int n) => n.toString().padLeft(2, '0');
String _nowText() {
  final n = DateTime.now();
  return '${_p2(n.hour)}:${_p2(n.minute)}';
}
