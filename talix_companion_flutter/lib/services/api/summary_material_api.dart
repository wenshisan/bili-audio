import 'base_api_service.dart';

/// 纪要模式物料信息 API (power接口需求(2).csv 第 8 类)
///
/// 1 个端点 (合并 4 类下拉选项为统一接口):
/// - GET /sl/app/summary-material/get   模板 / 模型 / 语言列表等
///
/// 返回 4 个列表:
///   - templateList        纪要模板
///   - audioLanguageList   录音语言
///   - transLanguageList   翻译语言
///   - modelList           AI 模型
class SummaryMaterialApi extends BaseApiService {
  SummaryMaterialApi._();
  static final SummaryMaterialApi instance = SummaryMaterialApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'summary-material-api';

  /// GET /sl/app/summary-material/get
  /// 一次性拉 4 个列表 (模板/录音语言/翻译语言/AI 模型)
  Future<SummaryMaterials> getMaterials() async {
    return get<SummaryMaterials>(
      '/sl/app/summary-material/get',
      fromData: (raw) {
        if (raw is! Map) {
          return const SummaryMaterials(
            templates: [],
            audioLanguages: [],
            transLanguages: [],
            models: [],
          );
        }
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;

        return SummaryMaterials(
          templates: _parseList(inner['templateList']),
          audioLanguages: _parseList(inner['audioLanguageList']),
          transLanguages: _parseList(inner['transLanguageList']),
          models: _parseList(inner['modelList']),
        );
      },
    );
  }

  List<MaterialItem> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MaterialItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// 模板/语言/模型 三种下拉选项的通用结构
/// CSV 字段: id / name / description
class MaterialItem {
  final String id; // templateId / languageId / modelId
  final String name; // templateName / languageName / modelName
  final String description;

  const MaterialItem({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: (json['templateId'] ?? json['languageId'] ?? json['modelId'] ?? '')
          .toString(),
      name: (json['templateName'] ??
              json['languageName'] ??
              json['modelName'] ??
              '')
          .toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

/// 物料信息响应 (4 个列表合一)
class SummaryMaterials {
  final List<MaterialItem> templates;
  final List<MaterialItem> audioLanguages;
  final List<MaterialItem> transLanguages;
  final List<MaterialItem> models;

  const SummaryMaterials({
    required this.templates,
    required this.audioLanguages,
    required this.transLanguages,
    required this.models,
  });

  /// 从 languageId 查中文名 (用于 setPreferenceSettings 后回显)
  String audioLanguageName(String? id) =>
      audioLanguages.firstWhere(
        (e) => e.id == id,
        orElse: () => const MaterialItem(id: '', name: ''),
      ).name;

  String transLanguageName(String? id) =>
      transLanguages.firstWhere(
        (e) => e.id == id,
        orElse: () => const MaterialItem(id: '', name: ''),
      ).name;

  String templateName(String? id) => templates
      .firstWhere(
        (e) => e.id == id,
        orElse: () => const MaterialItem(id: '', name: ''),
      )
      .name;

  String modelName(String? id) => models
      .firstWhere(
        (e) => e.id == id,
        orElse: () => const MaterialItem(id: '', name: ''),
      )
      .name;
}
