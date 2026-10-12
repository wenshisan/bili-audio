import '../../utils/api_formatters.dart';
import 'base_api_service.dart';

/// 纪要生成 / 重命名 / 重新生成 / 分享 / 上传 API
/// (power接口需求(2).csv 第 7 类)
///
/// 5 个端点:
/// - POST   /sl/app/summary/gen         纪要生成 (含思维导图)
/// - POST   /sl/app/summary/rename      纪要重命名
/// - POST   /sl/app/summary/regen       纪要重新生成
/// - POST   /sl/app/summary/share       内容分享 (CSV 标注 "shareContent")
/// - POST   /sl/app/summary/upload      录音文件上传 (CSV 标注 "uploadAudioFile")
///
/// 响应统一为 [SummaryResult] 包装类型,提供 summaryId / summaryName /
/// summaryText / summaryImage / speakerList / textRecord。
class SummaryApi extends BaseApiService {
  SummaryApi._();
  static final SummaryApi instance = SummaryApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'summary-api';

  /// POST /sl/app/summary/gen
  /// 生成纪要 (含思维导图 URL)
  ///
  /// 必传: fileId (针对哪个录音生成);
  /// 可选: location / aotoSeleteTemplate (typo) / templateId / languageId /
  ///       transLanguageId / modelId
  Future<SummaryResult> generate({
    required String fileId,
    String? location,
    bool? autoSelectTemplate,
    String? templateId,
    String? languageId,
    String? transLanguageId,
    String? modelId,
  }) async {
    return post<SummaryResult>(
      '/sl/app/summary/gen',
      data: {
        'fileId': fileId,
        if (location != null) 'location': location,
        // CSV 原字段 aotoSeleteTemplate (typo),保留原拼写
        if (autoSelectTemplate != null) 'aotoSeleteTemplate': autoSelectTemplate,
        if (templateId != null) 'templateId': templateId,
        if (languageId != null) 'languageId': languageId,
        if (transLanguageId != null) 'transLanguageId': transLanguageId,
        if (modelId != null) 'modelId': modelId,
      },
      fromData: (raw) => _parseResult(raw),
    );
  }

  /// POST /sl/app/summary/rename
  /// 重命名纪要
  Future<void> rename({
    required String fileId,
    required String summaryName,
  }) async {
    await post(
      '/sl/app/summary/rename',
      data: {
        'fileId': fileId,
        'summaryName': summaryName,
      },
    );
  }

  /// POST /sl/app/summary/regen
  /// 重新生成纪要 (服务端复用同 fileId 的旧纪要参数)
  Future<SummaryResult> regenerate({required String fileId}) async {
    return post<SummaryResult>(
      '/sl/app/summary/regen',
      data: {'fileId': fileId},
      fromData: (raw) => _parseResult(raw),
    );
  }

  /// POST /sl/app/summary/share  (CSV 标注 "shareContent")
  /// 内容分享,返回短链
  Future<String> shareContent({
    required String summaryId,
    required List<int> typeList, // 1=audio / 2=transcription / 3=summary
  }) async {
    return post<String>(
      '/sl/app/summary/share',
      data: {
        'summaryId': summaryId,
        'typeList': typeList,
      },
      fromData: (raw) {
        if (raw is Map) {
          return (raw['shareLink'] ?? '').toString();
        }
        return raw.toString();
      },
    );
  }

  /// POST /sl/app/summary/upload  (CSV 标注 "uploadAudioFile")
  /// 上传原始录音文件(若分享的是录音文件,则需要先调此接口拿到 url)
  ///
  /// file 为 MultipartFile 类型的二进制流;调用方需自己构造 dio.FormData
  /// (BaseApiService.post 只支持 JSON body, 上传请走 ApiClient.instance.dio.post)
  Future<void> uploadAudioFile({
    required String fileId,
    required dynamic file, // MultipartFile
  }) async {
    // 这里直接走 ApiClient 单例,因为 BaseApiService 的 post 是 JSON-only
    // (后续如果要支持 FormData,可在 BaseApiService 加一个 postForm 方法)
    // 暂时不实现上传逻辑,标注 TODO
    throw UnimplementedError(
      'uploadAudioFile: use ApiClient.instance.dio.post with FormData directly. '
      'fileId=$fileId, file=$file',
    );
  }

  // ===== internal =====

  SummaryResult _parseResult(dynamic raw) {
    if (raw is! Map) {
      return const SummaryResult(summaryId: '', summaryName: '');
    }
    final data = asMap(raw);
    final inner = (data['data'] is Map) ? asMap(data['data']) : data;
    return SummaryResult(
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
      textRecord: (inner['textRecord'] is List)
          ? (inner['textRecord'] as List).whereType<Map>().toList()
          : const [],
      summaryTime: asInt(inner['summaryTime']),
    );
  }
}

/// 纪要结果 (gen / regen 响应)
class SummaryResult {
  final String summaryId;
  final String summaryName;
  final String summaryText;
  final String summaryImage; // 思维导图 URL
  final String location;
  final List<String> speakerList;
  final List<Map> textRecord; // 原始 Map, 需用 TranscriptionApi.editText 回传
  final int summaryTime; // 毫秒

  const SummaryResult({
    required this.summaryId,
    required this.summaryName,
    this.summaryText = '',
    this.summaryImage = '',
    this.location = '',
    this.speakerList = const [],
    this.textRecord = const [],
    this.summaryTime = 0,
  });

  bool get hasMindmap => summaryImage.isNotEmpty;
}
