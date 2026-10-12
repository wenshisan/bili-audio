import '../../data/user_models.dart';
import 'base_api_service.dart';

/// 订阅 / 套餐 / 账单 / 偏好 / FAQ API
/// (power接口需求(2).csv 第 11 类)
///
/// 10 个端点:
/// - GET    /sl/app/subscription/current-plan         当前套餐
/// - GET    /sl/app/subscription/preference           偏好设置查询
/// - POST   /sl/app/subscription/preference           偏好设置设定
/// - GET    /sl/app/subscription/recommended-plan     推荐套餐列表
/// - POST   /sl/app/subscription/try-advanced         免费试用升级
/// - GET    /sl/app/subscription/faq                  常见问题 (Markdown/HTML)
/// - POST   /sl/app/subscription/subscribe            套餐订阅
/// - GET    /sl/app/subscription/bill-list            账单列表
/// - POST   /sl/app/subscription/delete-bill          删除账单
/// - POST   /sl/app/subscription/unsubscribe          取消订阅
///
/// 注: CSV 给的是 camelCase (getCurrentServicePlan),这里按 sl/app 风格
/// 统一转成 kebab-case 路径;若后端期望原样,改 path 字符串即可。
class SubscriptionApi extends BaseApiService {
  SubscriptionApi._();
  static final SubscriptionApi instance = SubscriptionApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'subscription-api';

  /// GET /sl/app/subscription/current-plan
  /// 当前套餐 — CSV 响应字段: id / name / planAttr / authMinutes / prices[] 等
  Future<ServicePlan> getCurrentServicePlan() async {
    return get<ServicePlan>(
      '/sl/app/subscription/current-plan',
      fromData: (raw) {
        if (raw is! Map) return const ServicePlan();
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        return ServicePlan.fromJson(inner);
      },
    );
  }

  /// GET /sl/app/subscription/recommended-plan
  /// 推荐套餐列表 — 响应 data.planList
  Future<List<ServicePlan>> getRecommendedServicePlan() async {
    return get<List<ServicePlan>>(
      '/sl/app/subscription/recommended-plan',
      fromData: (raw) {
        if (raw is! Map) return const [];
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        final list = (inner['planList'] is List)
            ? inner['planList'] as List
            : <dynamic>[];
        return list
            .whereType<Map>()
            .map((e) => ServicePlan.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  /// POST /sl/app/subscription/try-advanced
  /// 免费试用升级
  Future<void> tryAdvancedServicePlan() async {
    await post('/sl/app/subscription/try-advanced');
  }

  /// POST /sl/app/subscription/subscribe
  /// 套餐订阅 — purchasePlan: 1=月付 / 2=年付
  Future<void> subscribeServicePlan({
    required String planId,
    required int purchasePlan,
  }) async {
    await post(
      '/sl/app/subscription/subscribe',
      data: {
        'planId': planId,
        'purchasePlan': purchasePlan,
      },
    );
  }

  /// POST /sl/app/subscription/unsubscribe
  /// 取消订阅
  Future<void> unsubscribeServicePlan({required String planId}) async {
    await post(
      '/sl/app/subscription/unsubscribe',
      data: {'planId': planId},
    );
  }

  /// GET /sl/app/subscription/preference
  /// 偏好设置查询
  Future<UserPreferences> getPreferenceSettings() async {
    return get<UserPreferences>(
      '/sl/app/subscription/preference',
      fromData: (raw) {
        if (raw is! Map) return const UserPreferences.empty();
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        return UserPreferences.fromJson(inner);
      },
    );
  }

  /// POST /sl/app/subscription/preference
  /// 偏好设置设定
  Future<void> setPreferenceSettings({
    required String templateId,
    required String languageId,
    required String transLanguageId,
    required String modelId,
  }) async {
    await post(
      '/sl/app/subscription/preference',
      data: {
        'templateId': templateId,
        'languageId': languageId,
        'transLanguageId': transLanguageId,
        'modelId': modelId,
      },
    );
  }

  /// GET /sl/app/subscription/faq
  /// 常见问题 (后台发布的富文本)
  Future<String> getFAQ() async {
    return get<String>(
      '/sl/app/subscription/faq',
      fromData: (raw) {
        if (raw is Map) {
          return (raw['data'] is Map ? asMap(raw['data'])['content'] : null) ??
              (raw['content'] ?? '').toString();
        }
        return raw.toString();
      },
    );
  }

  /// GET /sl/app/subscription/bill-list
  /// 账单列表
  Future<List<BillingItem>> getBillList() async {
    return get<List<BillingItem>>(
      '/sl/app/subscription/bill-list',
      fromData: (raw) {
        if (raw is! Map) return const [];
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        final list = (inner['billList'] is List)
            ? inner['billList'] as List
            : <dynamic>[];
        return list
            .whereType<Map>()
            .map((e) => BillingItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  /// POST /sl/app/subscription/delete-bill
  /// 删除账单(批量)
  Future<void> deleteBillList(List<String> billIds) async {
    if (billIds.isEmpty) return;
    await post(
      '/sl/app/subscription/delete-bill',
      data: {'billList': billIds},
    );
  }
}

/// 套餐信息 (current / recommended 通用)
/// CSV 字段: id / name / recommended / planAttr / authMinutes / prices[] 等
class ServicePlan {
  final String id;
  final String name;
  final bool recommended;
  final int planAttr;
  final int authMinutes;
  final List<String> abilityList; // 推荐套餐的 abilityList
  final double monthPrice;
  final double yearPrice;
  final List<PlanPrice> prices;
  final String effectiveTime;
  final int planStatus; // 1=有效
  final int billingCycle;
  final int freeTrialDays;
  final String summaryTemplateScope;
  final int summaryTemplateLimit;
  final bool voiceprintEnable;
  final bool customTemplateEnable;
  final int customVocabLimit;
  final List<String> supportLanguages; // CSV: supportLanguages[].languageId
  final List<String> effectiveRegions;
  final List<String> thirdIntegrations;

  const ServicePlan({
    this.id = '',
    this.name = '',
    this.recommended = false,
    this.planAttr = 0,
    this.authMinutes = 0,
    this.abilityList = const [],
    this.monthPrice = 0,
    this.yearPrice = 0,
    this.prices = const [],
    this.effectiveTime = '',
    this.planStatus = 0,
    this.billingCycle = 0,
    this.freeTrialDays = 0,
    this.summaryTemplateScope = '',
    this.summaryTemplateLimit = 0,
    this.voiceprintEnable = false,
    this.customTemplateEnable = false,
    this.customVocabLimit = 0,
    this.supportLanguages = const [],
    this.effectiveRegions = const [],
    this.thirdIntegrations = const [],
  });

  factory ServicePlan.fromJson(Map<String, dynamic> json) {
    final pricesRaw = json['prices'];
    final prices = (pricesRaw is List)
        ? pricesRaw
            .whereType<Map>()
            .map((e) => PlanPrice.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PlanPrice>[];

    final supportLangsRaw = json['supportLanguages'];
    final supportLangs = (supportLangsRaw is List)
        ? supportLangsRaw
            .whereType<Map>()
            .map((e) => (e['languageId'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    final abilityRaw = json['abilityList'];
    final abilityList = (abilityRaw is List)
        ? abilityRaw.whereType<String>().toList()
        : <String>[];

    final regionsRaw = json['effectiveRegions'];
    final regions = (regionsRaw is List)
        ? regionsRaw.whereType<String>().toList()
        : <String>[];

    final thirdRaw = json['thirdIntegrations'];
    final third = (thirdRaw is List)
        ? thirdRaw.whereType<String>().toList()
        : <String>[];

    return ServicePlan(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['planName'] ?? '').toString(),
      recommended: json['recommended'] == true,
      planAttr: int.tryParse('${json['planAttr'] ?? 0}') ?? 0,
      authMinutes: int.tryParse('${json['authMinutes'] ?? 0}') ?? 0,
      abilityList: abilityList,
      monthPrice: double.tryParse('${json['monthPrice'] ?? 0}') ?? 0,
      yearPrice: double.tryParse('${json['yearPrice'] ?? 0}') ?? 0,
      prices: prices,
      effectiveTime: (json['effectiveTime'] ?? '').toString(),
      planStatus: int.tryParse('${json['planStatus'] ?? 0}') ?? 0,
      billingCycle: int.tryParse('${json['billingCycle'] ?? 0}') ?? 0,
      freeTrialDays: int.tryParse('${json['freeTrialDays'] ?? 0}') ?? 0,
      summaryTemplateScope: (json['summaryTemplateScope'] ?? '').toString(),
      summaryTemplateLimit:
          int.tryParse('${json['summaryTemplateLimit'] ?? 0}') ?? 0,
      voiceprintEnable: json['voiceprintEnable'] == true,
      customTemplateEnable: json['customTemplateEnable'] == true,
      customVocabLimit: int.tryParse('${json['customVocabLimit'] ?? 0}') ?? 0,
      supportLanguages: supportLangs,
      effectiveRegions: regions,
      thirdIntegrations: third,
    );
  }
}

/// 套餐价格条目 (CSV prices[].currency / amount / discountPercent / finalAmount)
class PlanPrice {
  final String currency;
  final double amount;
  final int discountPercent;
  final double finalAmount;

  const PlanPrice({
    required this.currency,
    required this.amount,
    required this.discountPercent,
    required this.finalAmount,
  });

  factory PlanPrice.fromJson(Map<String, dynamic> json) {
    return PlanPrice(
      currency: (json['currency'] ?? '').toString(),
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      discountPercent:
          int.tryParse('${json['discountPercent'] ?? 0}') ?? 0,
      finalAmount: double.tryParse('${json['finalAmount'] ?? 0}') ?? 0,
    );
  }

  /// "USD 99.00" 或 "USD 69.30 (70% 折扣)" — UI 用
  String displayText() {
    if (discountPercent > 0 && finalAmount > 0 && finalAmount < amount) {
      return '$currency ${finalAmount.toStringAsFixed(2)} (省$discountPercent%)';
    }
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}
