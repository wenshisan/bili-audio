// ============================================================
// 个人中心数据模型 (me_profile_screen.dart)
//
// 字段映射:
// - BillingItem: 来自 getBillList 响应 billList 元素
//     billId         → id
//     paymentDate    → date (毫秒 → "2025年5月8日")
//     paymentTool    → name (例 "App Store")
//     purchasePlan   → (1月付/2年付) → 状态描述文本
// - UserProfile: **已废弃** — 真实版本在 lib/models/auth_models.dart
//   保留空类仅为不破坏旧 import,后续清理阶段删除
// - UserPreferences: 来自 getPreferenceSettings 响应
//     template.templateId        → template
//     audioLanguage.languageId   → audioLang
//     transLanguage.languageId   → translationLang
//     model.modelId              → aiModel
//     onlyWifiUpload / appCacheSize 由客户端计算
// ============================================================
import '../utils/api_formatters.dart';

class BillingItem {
  final String id;
  final String date;
  final String name;
  final String amount;
  final String status; // 'paid' | 'refunded' | 'pending'

  const BillingItem({
    required this.id,
    required this.date,
    required this.name,
    required this.amount,
    required this.status,
  });

  /// 后端字段 (CSV 给出的):
  ///   billId, purchasePlan (1月付/2年付), paymentTool ("App Store"),
  ///   paymentDate (毫秒时间戳)
  /// 此外如果有 amount/price 字段也会读取
  factory BillingItem.fromJson(Map<String, dynamic> json) {
    final payMs = asInt(json['paymentDate']);
    String dateText = '';
    if (payMs > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(payMs);
      dateText = '${dt.year}年${dt.month}月${dt.day}日';
    }

    final purchasePlan = asInt(json['purchasePlan']);
    final cycle = purchasePlan == 1 ? '月付' : (purchasePlan == 2 ? '年付' : '');
    final paymentTool = asString(json['paymentTool']);
    final name = cycle.isNotEmpty
        ? '$paymentTool · $cycle'
        : paymentTool;

    // amount 字段: CSV 暂未列, 兼容多种字段名
    final amount = asString(
      json['amount'] ?? json['price'] ?? json['finalAmount'],
      fallback: '',
    );

    // status 字段: CSV 暂未列, 默认为 'paid'
    return BillingItem(
      id: asString(json['billId'] ?? json['id']),
      date: dateText,
      name: name,
      amount: amount,
      status: asString(json['status'], fallback: 'paid'),
    );
  }
}

/// ⚠️ 已废弃: 真实 UserProfile 在 lib/models/auth_models.dart
/// 保留仅为防止旧代码编译失败 — 后续清理阶段会删除
@Deprecated('Use UserProfile from lib/models/auth_models.dart instead')
class UserProfile {
  final String nickname;
  final String email;
  final bool isPremium;

  const UserProfile({
    required this.nickname,
    required this.email,
    required this.isPremium,
  });
}

class UserPreferences {
  final String template;
  final String audioLang;
  final String aiModel;
  final String translationLang;
  final bool onlyWifiUpload;
  final String appCacheSize;

  const UserPreferences({
    required this.template,
    required this.audioLang,
    required this.aiModel,
    required this.translationLang,
    required this.onlyWifiUpload,
    required this.appCacheSize,
  });

  /// 空偏好 — 加载失败 / 首次进入时使用,UI 仍可显示
  const UserPreferences.empty()
      : template = '',
        audioLang = '',
        aiModel = '',
        translationLang = '',
        onlyWifiUpload = false,
        appCacheSize = '0KB';

  UserPreferences copyWith({
    String? template,
    String? audioLang,
    String? aiModel,
    String? translationLang,
    bool? onlyWifiUpload,
    String? appCacheSize,
  }) {
    return UserPreferences(
      template: template ?? this.template,
      audioLang: audioLang ?? this.audioLang,
      aiModel: aiModel ?? this.aiModel,
      translationLang: translationLang ?? this.translationLang,
      onlyWifiUpload: onlyWifiUpload ?? this.onlyWifiUpload,
      appCacheSize: appCacheSize ?? this.appCacheSize,
    );
  }

  /// 后端 getPreferenceSettings 响应:
  /// {
  ///   template: { templateId, templateName, ... },
  ///   audioLanguage: { languageId, ... },
  ///   transLanguage: { languageId, ... },
  ///   model: { modelId, modelName, ... }
  /// }
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    String idOf(dynamic v) {
      if (v is Map) return asString(v['templateId'] ?? v['languageId'] ?? v['modelId']);
      return asString(v);
    }

    return UserPreferences(
      template: idOf(json['template']),
      audioLang: idOf(json['audioLanguage'] ?? json['language']),
      aiModel: idOf(json['model']),
      translationLang: idOf(json['transLanguage']),
      onlyWifiUpload: asBool(json['onlyWifiUpload']),
      appCacheSize: asString(json['appCacheSize'], fallback: '0KB'),
    );
  }

  /// 序列化为 setPreferenceSettings 请求体
  Map<String, dynamic> toUpdateJson() {
    return {
      'templateId': template,
      'languageId': audioLang,
      'transLanguageId': translationLang,
      'modelId': aiModel,
    };
  }
}
