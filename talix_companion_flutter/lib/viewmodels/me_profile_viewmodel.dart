import 'package:flutter/foundation.dart';

// UserPreferences / BillingItem 来自 data/user_models.dart;
// UserProfile (主类) 来自 models/auth_models.dart;
// data/user_models.dart 里的 UserProfile 是 @Deprecated 占位,这里 hide 掉避免冲突
import '../data/user_models.dart' hide UserProfile;
import '../models/auth_models.dart';
import '../services/api/auth_api.dart';
import '../services/api/subscription_api.dart';
import '../utils/app_logger.dart';
import '../utils/safe_change_notifier.dart';

// ============================================================
// 个人中心 ViewModel (MVVM)
// 状态: profile + subScreen + preferences + billing + feedback + modals
//
// 继承 SafeChangeNotifier: 多个网络请求并发 (loadUserProfile / loadCurrentPlan
// / loadPreferences / loadBillList 等),用户切到其他屏时这些请求还在 in-flight,
// 任何一个超时/失败都会触发 finally 块的 notifyListeners(),基类守护避免闪退。
// ============================================================
class MeProfileViewModel extends SafeChangeNotifier {
  final AuthApi _api = AuthApi.instance;
  final SubscriptionApi _subApi = SubscriptionApi.instance;

  // 当前子页面
  String _activeSubScreen = 'me-01';
  String get activeSubScreen => _activeSubScreen;
  set activeSubScreen(String v) {
    _activeSubScreen = v;
    notifyListeners();
  }

  // Profile - 使用 auth_models.dart 中的 UserProfile
  UserProfile? _profile;
  UserProfile? get profile => _profile;
  
  String get nickname => _profile?.nickname ?? '';
  String get email => _profile?.email ?? '';
  String get avatar => _profile?.avatar ?? '';
  String get sn => _profile?.sn ?? '';
  String get mobile => _profile?.mobile ?? '';
  bool get isTourist => _profile?.isTourist ?? false;
  
  // 兼容旧代码: isPremiumUser 始终返回 false (后端暂无会员系统)
  bool get isPremiumUser => false;
  set isPremiumUser(bool v) {
    // 后端暂无会员系统, 此占位保留
  }

  // 升级订阅状态
  String _selectedPlan = 'premium';
  String get selectedPlan => _selectedPlan;
  set selectedPlan(String v) {
    _selectedPlan = v;
    notifyListeners();
  }

  String _selectedBillingCycle = 'yearly';
  String get selectedBillingCycle => _selectedBillingCycle;
  set selectedBillingCycle(String v) {
    _selectedBillingCycle = v;
    notifyListeners();
  }

  bool _isAutoRenew = true;
  bool get isAutoRenew => _isAutoRenew;
  set isAutoRenew(bool v) {
    _isAutoRenew = v;
    notifyListeners();
  }

  // 密码可见性
  bool _showOldPassword = false;
  bool get showOldPassword => _showOldPassword;
  set showOldPassword(bool v) {
    _showOldPassword = v;
    notifyListeners();
  }

  bool _showNewPassword = false;
  bool get showNewPassword => _showNewPassword;
  set showNewPassword(bool v) {
    _showNewPassword = v;
    notifyListeners();
  }

  bool _showConfirmPassword = false;
  bool get showConfirmPassword => _showConfirmPassword;
  set showConfirmPassword(bool v) {
    _showConfirmPassword = v;
    notifyListeners();
  }

  // 偏好设置 (来自后端,加载失败 fallback 到默认)
  UserPreferences _preferences = const UserPreferences(
    template: '默认模板',
    audioLang: '中文',
    aiModel: 'GPT-4',
    translationLang: '英文',
    onlyWifiUpload: false,
    appCacheSize: '0 MB',
  );
  UserPreferences get preferences => _preferences;

  // 反馈
  String _feedbackCategory = '功能建议';
  String get feedbackCategory => _feedbackCategory;
  set feedbackCategory(String v) {
    _feedbackCategory = v;
    notifyListeners();
  }

  // 上传的文件
  final List<String> _uploadedFiles = [];
  List<String> get uploadedFiles => List.unmodifiable(_uploadedFiles);

  void addUploadedFile(String name) {
    _uploadedFiles.add(name);
    notifyListeners();
  }

  void removeUploadedFile(String name) {
    _uploadedFiles.remove(name);
    notifyListeners();
  }

  // Billing
  List<BillingItem> _billingHistory = [];
  List<BillingItem> get billingHistory => List.unmodifiable(_billingHistory);

  // 当前套餐 (来自 getCurrentServicePlan)
  ServicePlan? _currentPlan;
  ServicePlan? get currentPlan => _currentPlan;

  // 推荐套餐列表 (来自 getRecommendedServicePlan)
  List<ServicePlan> _recommendedPlans = [];
  List<ServicePlan> get recommendedPlans => List.unmodifiable(_recommendedPlans);

  // FAQ (来自 getFAQ,可能是 HTML/Markdown 文本)
  String _faqContent = '';
  String get faqContent => _faqContent;

  // 删除账号输入
  String _deleteInput = '';
  String get deleteInput => _deleteInput;
  set deleteInput(String v) {
    _deleteInput = v;
    notifyListeners();
  }

  // ============================================================
  // 模态弹窗状态
  // ============================================================
  String? _activeModal;
  String? get activeModal => _activeModal;

  void openChangePasswordModal() {
    _activeModal = 'changePassword';
    notifyListeners();
  }

  void openDeleteAccountModal() {
    _activeModal = 'deleteAccount';
    notifyListeners();
  }

  void openCancelSubscriptionModal() {
    _activeModal = 'cancelSubscription';
    notifyListeners();
  }

  void openLatestVersionModal() {
    _activeModal = 'latestVersion';
    notifyListeners();
  }

  void openNewFeaturesModal() {
    _activeModal = 'newFeatures';
    notifyListeners();
  }

  void closeModal() {
    _activeModal = null;
    notifyListeners();
  }

  // ============================================================
  // APP 升级
  // ============================================================
  final String _currentVersion = '1.1.45';
  String get currentVersion => _currentVersion;

  final String _updateTargetVersion = 'v1.0.0';
  String get updateTargetVersion => _updateTargetVersion;

  final List<String> _updateChangelog = const [
    '1. 新功能：新增的功能特性',
    '2. 新功能：新增的功能特性',
    '3. 修复：已修复的Bug列表',
  ];
  List<String> get updateChangelog => _updateChangelog;

  String _updateState = 'idle';
  String get updateState => _updateState;
  bool get isCheckingUpdate => _updateState == 'checking';
  bool get isUpdateAvailable => _updateState == 'available';

  Future<void> checkForUpdate() async {
    if (_updateState == 'checking') return;
    _updateState = 'checking';
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    bool hasUpdate;
    if (kDebugMode) {
      hasUpdate = DateTime.now().millisecondsSinceEpoch % 2 == 0;
    } else {
      hasUpdate = false;
    }

    _updateState = hasUpdate ? 'available' : 'latest';
    notifyListeners();

    if (hasUpdate) {
      openNewFeaturesModal();
    } else {
      openLatestVersionModal();
    }
  }

  Future<void> restartAndUpdate() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _updateState = 'idle';
    notifyListeners();
  }

  void resetUpdateState() {
    if (_updateState != 'checking') {
      _updateState = 'idle';
      notifyListeners();
    }
  }

  // ============================================================
  // 初始化与数据加载
  // ============================================================
  MeProfileViewModel({String initialSubScreen = 'me-01'}) {
    _activeSubScreen = initialSubScreen;
    _loadData();
  }

  Future<void> _loadData() async {
    // 并行加载多个数据源 — 用户资料 / 当前套餐 / 偏好 / 账单列表
    await Future.wait([
      loadUserProfile(),
      loadCurrentPlan(),
      loadPreferences(),
      loadBillList(),
    ]);
  }

  /// 从后端加载用户资料
  Future<void> loadUserProfile() async {
    try {
      _profile = await _api.getUserProfile();
      notifyListeners();
    } catch (e) {
      AppLogger.w('loadUserProfile failed: $e', 'me-profile');
    }
  }

  /// 从后端加载当前套餐
  Future<void> loadCurrentPlan() async {
    try {
      _currentPlan = await _subApi.getCurrentServicePlan();
      notifyListeners();
    } catch (e) {
      AppLogger.w('loadCurrentPlan failed: $e', 'me-profile');
    }
  }

  /// 从后端加载推荐套餐
  Future<void> loadRecommendedPlans() async {
    try {
      _recommendedPlans = await _subApi.getRecommendedServicePlan();
      notifyListeners();
    } catch (e) {
      AppLogger.w('loadRecommendedPlans failed: $e', 'me-profile');
    }
  }

  /// 从后端加载偏好设置
  Future<void> loadPreferences() async {
    try {
      _preferences = await _subApi.getPreferenceSettings();
      notifyListeners();
    } catch (e) {
      AppLogger.w('loadPreferences failed: $e', 'me-profile');
    }
  }

  /// 保存偏好设置到后端
  Future<void> savePreferences() async {
    try {
      await _subApi.setPreferenceSettings(
        templateId: _preferences.template,
        languageId: _preferences.audioLang,
        transLanguageId: _preferences.translationLang,
        modelId: _preferences.aiModel,
      );
    } catch (e) {
      AppLogger.w('savePreferences failed: $e', 'me-profile');
      rethrow;
    }
  }

  /// 从后端加载账单列表
  Future<void> loadBillList() async {
    try {
      _billingHistory = await _subApi.getBillList();
      notifyListeners();
    } catch (e) {
      AppLogger.w('loadBillList failed: $e', 'me-profile');
    }
  }

  /// 从后端删除账单(批量)
  Future<void> deleteBills(List<String> billIds) async {
    try {
      await _subApi.deleteBillList(billIds);
      _billingHistory.removeWhere((b) => billIds.contains(b.id));
      notifyListeners();
    } catch (e) {
      AppLogger.w('deleteBills failed: $e', 'me-profile');
      rethrow;
    }
  }

  /// 订阅套餐
  Future<void> subscribe({
    required String planId,
    required int purchasePlan, // 1=月付 / 2=年付
  }) async {
    try {
      await _subApi.subscribeServicePlan(
        planId: planId,
        purchasePlan: purchasePlan,
      );
      await loadCurrentPlan(); // 重新拉当前套餐
    } catch (e) {
      AppLogger.w('subscribe failed: $e', 'me-profile');
      rethrow;
    }
  }

  /// 取消订阅
  Future<void> unsubscribe({required String planId}) async {
    try {
      await _subApi.unsubscribeServicePlan(planId: planId);
      await loadCurrentPlan();
    } catch (e) {
      AppLogger.w('unsubscribe failed: $e', 'me-profile');
      rethrow;
    }
  }

  /// 加载 FAQ
  Future<void> loadFAQ() async {
    try {
      _faqContent = await _subApi.getFAQ();
      notifyListeners();
    } catch (e) {
      AppLogger.w('loadFAQ failed: $e', 'me-profile');
    }
  }

  /// 加载更多(下拉刷新入口)
  Future<void> refreshAll() async {
    await _loadData();
  }

  // ============================================================
  // 用户资料操作 (真实 API)
  // ============================================================

  /// 更新昵称
  Future<void> updateNickname(String nickname) async {
    try {
      await _api.updateNickName(nickname);
      // 更新本地状态
      if (_profile != null) {
        _profile = UserProfile(
          id: _profile!.id,
          nickname: nickname,
          sn: _profile!.sn,
          email: _profile!.email,
          mobile: _profile!.mobile,
          sex: _profile!.sex,
          avatar: _profile!.avatar,
          loginIp: _profile!.loginIp,
          loginDate: _profile!.loginDate,
          createTime: _profile!.createTime,
          isTourist: _profile!.isTourist,
        );
        notifyListeners();
      }
    } catch (e) {
      AppLogger.w('updateNickname failed: $e', 'me-profile');
      rethrow;
    }
  }

  /// 修改密码
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _api.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      AppLogger.w('updatePassword failed: $e', 'me-profile');
      rethrow;
    }
  }

  /// 删除账号
  Future<void> deleteAccount() async {
    try {
      await _api.deleteAccount();
    } catch (e) {
      AppLogger.w('deleteAccount failed: $e', 'me-profile');
      rethrow;
    }
  }

  // ===== 选项列表 =====
  List<String> get feedbackCategories => const [
        '功能建议',
        '体验问题',
        'Bug反馈',
        '其他',
      ];
  List<String> get templates => const [
        '默认模板',
        '会议纪要',
        '项目总结',
        '周报',
      ];
  List<String> get audioLangs => const [
        '中文',
        '英文',
        '日文',
        '韩文',
      ];
  List<String> get aiModels => const [
        'GPT-4',
        'GPT-3.5',
        'Claude-3',
      ];
  List<String> get translationLangs => const [
        '英文',
        '中文',
        '日文',
        '韩文',
      ];

  // ===== Preferences Commands =====
  void updateTemplate(String v) {
    // _preferences 目前是本地状态, 后续可接入后端
    notifyListeners();
  }

  void updateAudioLang(String v) {
    notifyListeners();
  }

  void updateAiModel(String v) {
    notifyListeners();
  }

  void updateTranslationLang(String v) {
    notifyListeners();
  }

  void toggleOnlyWifiUpload() {
    notifyListeners();
  }

  void clearCache() {
    notifyListeners();
  }

  // ===== Logout =====
  void logout() {
    _profile = null;
    _isAutoRenew = false;
    _selectedPlan = 'premium';
    _selectedBillingCycle = 'yearly';
    _activeSubScreen = 'me-01';
    _activeModal = null;
    _updateState = 'idle';
    notifyListeners();
  }
}

// BillingItem / UserPreferences / ServicePlan / PlanPrice
// 已统一定义在 lib/data/user_models.dart 与 lib/services/api/subscription_api.dart,
// 本文件直接通过 import 复用 (避免重复定义导致类型不一致)。
