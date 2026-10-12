import '../../data/ai_models.dart';
import '../../utils/api_formatters.dart';
import 'base_api_service.dart';

/// AI 问答 API (power接口需求(2).csv 第 10 类)
/// 2 个端点:
/// - POST /sl/app/ai/ask-question       问答接口 (CSV 标注 "askQuestion")
/// - POST /sl/app/ai/get-question-list   推荐问题卡片 (CSV 标注 "getQuestionList")
///
/// 响应中:
///   ask-question       → { answer: string }
///   get-question-list  → { list: [string, string, ...] }
class AiApi extends BaseApiService {
  AiApi._();
  static final AiApi instance = AiApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'ai-api';

  /// POST /sl/app/ai/ask-question
  /// 问答接口
  Future<AiAnswerResp> askQuestion({
    required List<String> fileList,
    required String question,
  }) async {
    return post<AiAnswerResp>(
      '/sl/app/ai/ask-question',
      data: {
        'fileList': fileList,
        'question': question,
      },
      fromData: (raw) {
        if (raw is! Map) {
          return const AiAnswerResp(answer: '');
        }
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        return AiAnswerResp(answer: asString(inner['answer']));
      },
    );
  }

  /// POST /sl/app/ai/get-question-list
  /// 推荐问题卡片 — 返回 string 数组
  Future<List<AiQuickPrompt>> getQuestionList({
    required List<String> fileList,
  }) async {
    return post<List<AiQuickPrompt>>(
      '/sl/app/ai/get-question-list',
      data: {'fileList': fileList},
      fromData: (raw) {
        if (raw is! Map) return const [];
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        final list = (inner['list'] is List)
            ? inner['list'] as List
            : <dynamic>[];
        return list
            .whereType<String>()
            .toList()
            .asMap()
            .entries
            .map((e) => AiQuickPrompt.fromString(e.key, e.value))
            .toList();
      },
    );
  }
}

/// AI 回答响应
class AiAnswerResp {
  final String answer;
  const AiAnswerResp({required this.answer});
}
