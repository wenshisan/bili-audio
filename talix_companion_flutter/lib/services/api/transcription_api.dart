import '../../data/dialogue_block.dart';
import '../../utils/api_formatters.dart';
import 'base_api_service.dart';

/// 转写 / 摘要编辑 API (power接口需求(2).csv 第 9 类)
/// 3 个端点:
/// - GET    /sl/app/summary/detail?fileId=xxx   查询转写及摘要
/// - POST   /sl/app/summary/edit-text           编辑转写内容
/// - POST   /sl/app/summary/edit-speaker        编辑发言人
///
/// 注意: 旧 CSV 标注为 "transcription" 域, 路径 /sl/app/text-recording/* 已废弃;
/// 新 CSV(2) 改用 /sl/app/summary/* 统一入口(详情/编辑都在 summary 域)。
class TranscriptionApi extends BaseApiService {
  TranscriptionApi._();
  static final TranscriptionApi instance = TranscriptionApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'transcription-api';

  /// GET /sl/app/summary/detail?fileId=xxx
  /// 查询转写及摘要。响应中 textRecord 是核心字段;
  /// 同时返回 summaryName / summaryTime / summaryText / location / speakerList
  /// 等摘要字段(如果该文件已生成纪要)。
  Future<TranscriptionDetailResp> getDetail({required String fileId}) async {
    return get<TranscriptionDetailResp>(
      '/sl/app/summary/detail',
      query: {'fileId': fileId},
      fromData: (raw) {
        if (raw is! Map) {
          return const TranscriptionDetailResp(
            summaryId: '',
            textRecord: [],
          );
        }
        final data = asMap(raw);
        // data 内嵌 — 响应可能是 {code, data: {summaryId, textRecord[]}}
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        final list = (inner['textRecord'] is List)
            ? inner['textRecord'] as List
            : <dynamic>[];
        final dialogues = <DialogueBlock>[];
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map) {
            dialogues.add(
              DialogueBlock.fromJson(
                Map<String, dynamic>.from(item),
                index: i,
              ),
            );
          }
        }
        return TranscriptionDetailResp(
          summaryId: asString(inner['summaryId']),
          summaryName: asString(inner['summaryName']),
          summaryText: asString(inner['summaryText']),
          summaryImage: asString(inner['summaryImage']),
          location: asString(inner['location']),
          speakerList: (inner['speakerList'] is List)
              ? (inner['speakerList'] as List)
                  .whereType<String>()
                  .toList()
              : const <String>[],
          textRecord: dialogues,
        );
      },
    );
  }

  /// POST /sl/app/summary/edit-text
  /// 整批回传该文件的所有转写段 (CSV 字段: textRecord[], 含 textId/text/startTime/speakerName/textTrans)
  Future<void> editText({
    required String fileId,
    required List<Map<String, dynamic>> textRecord,
  }) async {
    await post(
      '/sl/app/summary/edit-text',
      data: {
        'fileId': fileId,
        'textRecord': textRecord,
      },
    );
  }

  /// POST /sl/app/summary/edit-speaker
  /// 重命名发言人 — CSV 字段: fileId / speakerName / newSpakerName (CSV 原拼写错误保留)
  Future<void> editSpeaker({
    required String fileId,
    required String speakerName,
    required String newSpeakerName,
  }) async {
    await post(
      '/sl/app/summary/edit-speaker',
      data: {
        'fileId': fileId,
        'speakerName': speakerName,
        // 后端字段名 newSpakerName (CSV 原拼写错误),保持原样避免联调失败
        'newSpakerName': newSpeakerName,
      },
    );
  }
}

/// 转写详情响应 (GET /sl/app/summary/detail)
class TranscriptionDetailResp {
  final String summaryId;
  final String summaryName; // 空 = 还未生成纪要
  final String summaryText; // 空 = 还未生成纪要
  final String summaryImage; // 思维导图 URL (可能空)
  final String location;
  final List<String> speakerList;
  final List<DialogueBlock> textRecord;

  const TranscriptionDetailResp({
    required this.summaryId,
    this.summaryName = '',
    this.summaryText = '',
    this.summaryImage = '',
    this.location = '',
    this.speakerList = const [],
    this.textRecord = const [],
  });

  bool get hasSummary => summaryId.isNotEmpty && summaryText.isNotEmpty;
}
