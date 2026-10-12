import 'package:flutter/foundation.dart';
import 'user_models.dart';

// ============================================================
// 用户中心 Fake 数据源 (仅 debug 模式加载)
// ============================================================
class FakeUserDataSource {
  static const UserProfile defaultProfile = UserProfile(
    nickname: 'Will Wiley',
    email: 'willwillwillwiley@gmail.com',
    isPremium: false,
  );

  static List<BillingItem> getBillingHistory() {
    if (!kDebugMode) return [];
    return const [
      BillingItem(
        id: 'inv_01',
        date: '2026-05-08',
        name: '专业版月度订阅',
        amount: '\$18.99',
        status: 'paid',
      ),
      BillingItem(
        id: 'inv_02',
        date: '2026-04-08',
        name: '专业版月度订阅',
        amount: '\$18.99',
        status: 'paid',
      ),
      BillingItem(
        id: 'inv_03',
        date: '2026-03-08',
        name: '专业版月度订阅',
        amount: '\$18.99',
        status: 'paid',
      ),
    ];
  }

  static const UserPreferences defaultPreferences = UserPreferences(
    template: '智能纪要',
    audioLang: '中文简体-普通话',
    aiModel: '自动',
    translationLang: '不翻译',
    onlyWifiUpload: true,
    appCacheSize: '24.5 MB',
  );

  static const List<String> feedbackCategories = [
    '设备连接问题',
    '音频转写不准',
    'AI摘要不好用',
    '功能报错/崩溃',
    '其他建议',
  ];

  static const List<String> templates = [
    '智能纪要',
    '会议记录',
    '课堂笔记',
    '讲座访谈',
    '灵感草稿',
  ];

  static const List<String> audioLangs = [
    '中文简体-普通话',
    '英语',
    '粤语',
    '四川话',
    '中英混合',
  ];

  static const List<String> aiModels = [
    '自动',
    'Gemini 3.5 Flash',
    'Gemini 3.5 Pro',
    'DeepMind Core',
  ];

  static const List<String> translationLangs = [
    '不翻译',
    '英语',
    '日语',
    '韩语',
    '德语',
  ];
}
