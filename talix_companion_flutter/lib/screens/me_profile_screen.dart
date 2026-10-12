import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/server_profile.dart';
import '../services/api/api_client.dart';
import '../services/server_config_service.dart';
import '../utils/app_logger.dart';
import '../utils/force_logout.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/me_profile_viewmodel.dart';
import '../widgets/app_toast.dart';
import '../widgets/common/common.dart';
import '../widgets/file_list_widgets.dart' show FigmaTokens;
import 'upgrade_screen.dart';

// ============================================================
// 个人中心 (MVVM - 薄 View)
// 状态: profile + preferences + billing + feedback + modals (在 ViewModel)
// UI-only: TextEditingController (对话弹窗临时输入)
//
// 对齐 Figma 1218:6774 (我的) 完整设计:
//   - 1218:10260 主页面
//   - 1218:10486 账号编辑
//   - 1218:11084 修改密码弹窗
//   - 1218:11056 永久删除账号弹窗
//   - 1218:11070 取消订阅弹窗
//   - 1218:10988 关于页 (含 APP 升级按钮 "检查更新" / "重启并更新")
//   - 1295:11302 最新版本提示弹窗
//   - 1295:11428 新功能更新内容弹窗
// ============================================================
class MeProfileScreen extends StatefulWidget {
  final String initialSubScreen;
  // 可选外部注入: 由 MainFrame 持有共享 VM, 保证 isPremiumUser 在侧边栏升级卡 /
  // MeProfile 会员卡 / UpgradeScreen 三处一致. 不传时本页面自管 VM, 保持向后兼容.
  final MeProfileViewModel? viewModel;
  const MeProfileScreen({
    super.key,
    this.initialSubScreen = 'me-01',
    this.viewModel,
  });

  @override
  State<MeProfileScreen> createState() => _MeProfileScreenState();
}

class _MeProfileScreenState extends State<MeProfileScreen> {
  late final MeProfileViewModel _viewModel;
  // 是否由本页面创建 VM (true=自管, false=外部注入, 不归本页面 dispose)
  bool _ownsViewModel = false;

  // UI-only: TextEditingControllers for input fields
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _feedbackTextController = TextEditingController();
  final TextEditingController _feedbackEmailController = TextEditingController();
  final TextEditingController _accountNicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      // 由外部 (MainFrame) 注入, 共享同一份 VM
      _viewModel = widget.viewModel!;
      _ownsViewModel = false;
    } else {
      // 向后兼容: 本页面自管 VM
      _viewModel = MeProfileViewModel(initialSubScreen: widget.initialSubScreen);
      _ownsViewModel = true;
    }
    _accountNicknameController.text = _viewModel.nickname;
    _newPasswordController.addListener(() {
      // Trigger rebuild for password strength bar
      setState(() {});
    });
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _feedbackTextController.dispose();
    _feedbackEmailController.dispose();
    _accountNicknameController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    AppToast.show(context, message);
  }

  void _showErrorToast(dynamic error) {
    if (error is ApiException) {
      final msg = AppToast.translateError(error.message);
      AppToast.show(context, msg);
    } else {
      AppToast.show(context, error.toString());
    }
  }

  void _navigate(String screenId) {
    _viewModel.activeSubScreen = screenId;
  }

  /// 打开升级订阅页面 (push 全屏 UpgradeScreen, 共享当前 VM)
  void _openUpgradeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UpgradeScreen(viewModel: _viewModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return _buildBody(context);
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        // 主内容区
        Positioned.fill(
          child: _buildActiveScreen(),
        ),
        // 模态弹窗层 (Figma 1218:6774 中的 4 个弹窗)
        if (_viewModel.activeModal != null)
          Positioned.fill(
            child: _buildModalOverlay(),
          ),
      ],
    );
  }

  // ============================================================
  // 路由切换
  // ============================================================
  Widget _buildActiveScreen() {
    switch (_viewModel.activeSubScreen) {
      case 'me-01':
        return _buildMainProfile();
      case 'me-02':
        return _buildAccountEditScreen();
      case 'me-05':
        // me-05 升级页已抽离为独立 UpgradeScreen, 此处不再渲染,
        // 兜底返回主页避免白屏 (由 push UpgradeScreen 处理实际跳转)
        return _buildMainProfile();
      case 'me-06':
        return _buildBillingHistoryScreen();
      case 'me-08':
        return _buildPreferenceSettingsScreen();
      case 'me-09':
        return _buildFeedbackFormScreen();
      case 'me-10':
        return _buildAboutAppScreen();
      case 'me-11':
        return _buildServerSwitcherScreen();
      default:
        return _buildMainProfile();
    }
  }

  // ============================================================
  // SCREEN 01: 我的主页 (Figma 1218:10260)
  // 1440x900 桌面布局, 240px 侧边栏 + 主区, 640px 居中内容
  //   - Content-Header: 24px Bold "我的" + 32x32 黑色圆形用户按钮
  //   - 会员卡 (640x99, 白底, 12px 圆角, 1px #ADADAD 描边)
  //   - Settings-List 1: 升级至专业版 / 账单
  //   - Settings-List 2: 通用设置 / 帮助与反馈 / 关于 (新版本徽标)
  // ============================================================
  Widget _buildMainProfile() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
            children: [
              // Content-Header (Figma 1218:10319) - 640x74, y=43
              _buildContentHeader(),
              const SizedBox(height: 24),

              // 会员卡 (Figma 1218:10325) - 640x99
              _buildMembershipCard(),
              const SizedBox(height: 24),

              // Settings-List 1 (Figma 1218:10334) - 2 行
              _buildSettingsListColumn([
                _SettingsRowItem(
                  label: '升级至专业版',
                  onTap: () => _navigate('me-05'),
                ),
                _SettingsRowItem(
                  label: '账单',
                  onTap: () => _navigate('me-06'),
                ),
              ]),
              const SizedBox(height: 16),

              // Settings-List 2 (Figma 1218:10350) - 4 行
              //   通用设置 / 帮助与反馈 / 关于 / 服务器环境
              _buildSettingsListColumn([
                _SettingsRowItem(
                  label: '通用设置',
                  onTap: () => _navigate('me-08'),
                ),
                _SettingsRowItem(
                  label: '帮助与反馈',
                  onTap: () => _navigate('me-09'),
                ),
                _SettingsRowItem(
                  label: '关于',
                  badge: '新版本',
                  onTap: () => _navigate('me-10'),
                ),
                _SettingsRowItem(
                  label: '服务器环境',
                  // 右侧显示当前活动 profile 名 (无营销文案, 干净)
                  rightText: context.watch<ServerConfigService>().active?.name,
                  onTap: () => _navigate('me-11'),
                ),
              ]),
              const SizedBox(height: 32),

              // 退出登录按钮 (主页面快捷入口, 与 me-02 账号编辑页底部按钮同效)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSignOutButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Content-Header: 左侧标题 24px Bold #262626, 右侧 32x32 黑色圆形用户按钮
  Widget _buildContentHeader() {
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 标题 "我的" 24px Bold
          const Positioned(
            left: 0,
            top: 17,
            child: Text(
              '我的',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: FigmaTokens.primary,
                height: 1.0,
              ),
            ),
          ),
          // 32x32 黑色圆形按钮 (Figma 1218:10321)
          Positioned(
            right: 0,
            top: 16,
            child: GestureDetector(
              onTap: () => _navigate('me-02'),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: FigmaTokens.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(5),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 会员卡 (Figma 1218:10325) - 640x99, 白底, 12px 圆角, 1px #ADADAD 描边
  Widget _buildMembershipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFADADAD), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧: 标题 + 进度条 + 提示
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _viewModel.isPremiumUser ? 'Talix Pro 专业版' : 'Talix 基础版',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: FigmaTokens.primary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                // 进度条 (320 宽度, 4px 高, 220/800 = 27.5% 填充)
                Container(
                  width: 320,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FigmaTokens.iconPlaceholder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _viewModel.isPremiumUser ? 1.0 : 0.275,
                    child: Container(
                      decoration: BoxDecoration(
                        color: FigmaTokens.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _viewModel.isPremiumUser ? '专业级 AI 会员 • 无限次极速转写' : '剩余220 / 800 分钟',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaTokens.textMuted,
                    height: 1.0,
                    letterSpacing: 0.0084,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 右侧: 160x64 黑色按钮
          GestureDetector(
            onTap: _openUpgradeScreen,
            child: Container(
              width: 160,
              height: 64,
              decoration: BoxDecoration(
                color: FigmaTokens.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '免费试用\n升级版',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.4,
                    letterSpacing: 0.0046,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Settings-List 列容器 (Figma 1218:10334/10350)
  /// 内部行 (Figma 1218:10335 Row): padding 10 16, gap 12, fill bg, line 分隔
  Widget _buildSettingsListColumn(List<_SettingsRowItem> rows) {
    return Container(
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              _buildSettingsRow(rows[i]),
              if (i < rows.length - 1)
                Container(
                  margin: const EdgeInsets.only(left: 16),
                  height: 1,
                  color: FigmaTokens.border,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow(_SettingsRowItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: FigmaTokens.primary,
                  height: 1.0,
                ),
              ),
            ),
            if (item.rightText != null) ...[
              Text(
                item.rightText!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: FigmaTokens.textMuted,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (item.badge != null) ...[
              Text(
                item.badge!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: FigmaTokens.textSecondary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: FigmaTokens.textFaint,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCREEN 02: 账号编辑 (Figma 1218:10486)
  //   - 顶部 Content-Header: 返回 + 标题 "账号编辑"
  //   - 80x80 黑色圆形头像 (x=800, y=122, 居中)
  //   - Settings-List: 昵称 (Jay + edit icon) / 登录账号 / 修改密码 / 删除账号
  //   - 底部 640x48 黑色 "退出登录" 按钮
  // ============================================================
  Widget _buildAccountEditScreen() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Stack(
            children: [
              // 主列
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
                children: [
                  // Content-Header: 返回 + 标题
                  _buildSubScreenHeader(
                    title: '账号编辑',
                    onBack: () => _navigate('me-01'),
                  ),
                  const SizedBox(height: 32),

                  // 头像 (80x80, 居中, Figma 1218:10588)
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: FigmaTokens.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settings-List
                  _buildAccountEditSettingsList(),
                  const SizedBox(height: 48),

                  // 退出登录按钮 (640x48 黑色, 12px 圆角, Figma 1218:10592)
                  _buildSignOutButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubScreenHeader({required String title, required VoidCallback onBack}) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          // 返回箭头 (16x16 区域)
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: FigmaTokens.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: FigmaTokens.primary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountEditSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Row 1: 昵称 (Jay + edit icon)
            _buildAccountEditRow(
              label: '昵称',
              rightWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _viewModel.nickname.isEmpty ? '未设置' : _viewModel.nickname,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: FigmaTokens.textSecondary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: FigmaTokens.textFaint,
                  ),
                ],
              ),
              onTap: () => _editNickname(),
            ),
            _buildAccountEditDivider(),
            // Row 2: 登录账号
            _buildAccountEditRow(
              label: '登录账号',
              rightWidget: Text(
                _viewModel.email.isEmpty ? '未登录' : _viewModel.email,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: FigmaTokens.textSecondary,
                  height: 1.0,
                ),
              ),
            ),
            _buildAccountEditDivider(),
            // Row 3: 修改密码
            _buildAccountEditRow(
              label: '修改密码',
              rightWidget: const Icon(
                Icons.chevron_right_rounded,
                color: FigmaTokens.textFaint,
                size: 16,
              ),
              onTap: () => _viewModel.openChangePasswordModal(),
            ),
            _buildAccountEditDivider(),
            // Row 4: 删除账号
            _buildAccountEditRow(
              label: '删除账号',
              rightWidget: const Icon(
                Icons.chevron_right_rounded,
                color: FigmaTokens.textFaint,
                size: 16,
              ),
              onTap: () => _viewModel.openDeleteAccountModal(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountEditRow({
    required String label,
    required Widget rightWidget,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: FigmaTokens.primary,
                  height: 1.0,
                ),
              ),
            ),
            rightWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildAccountEditDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: 1,
      color: FigmaTokens.border,
    );
  }

  /// 编辑昵称对话框
  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _viewModel.nickname);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入新昵称',
            border: OutlineInputBorder(),
          ),
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TalixButton(
            label: '保存',
            size: TalixButtonSize.small,
            expand: false,
            backgroundColor: FigmaTokens.primary,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await _viewModel.updateNickname(result);
      if (!mounted) return;
      _showToast('昵称修改成功');
    } catch (e) {
      if (!mounted) return;
      _showErrorToast(e);
    }
  }

  Widget _buildSignOutButton() {
    return TalixButton(
      label: '退出登录',
      variant: TalixButtonVariant.dark,
      height: 48,
      borderRadius: 12,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      backgroundColor: FigmaTokens.primary,
      onPressed: () async {
        final auth = context.read<AuthViewModel>();
        // 先 toast: AppToast 用 rootOverlay, 提前插入才能在路由切换后仍可见。
        // 一旦切回 LoginScreen, MainFrame 下的 MeProfileScreen 会被卸载,
        // mounted 变 false, 之后再调 _showToast 就没有效果了。
        _showToast('已退出登录');
        // 1) 调后端 /auth/logout 并清空本地 token/userId
        //    (AuthViewModel.logout 内部已 try/catch, 后端失败也会清本地)
        // 2) 用 rootNavigatorKey pushAndRemoveUntil 强制跳到 LoginScreen —
        //    与改密/删号一致的兜底, 不单纯依赖 AuthGate 响应 notifyListeners
        await logoutAndGoToLogin(auth);
        _viewModel.logout(); // 还原本地 VM 的 profile / 弹窗状态
      },
    );
  }

  // me-05 升级订阅页已抽离为独立 screens/upgrade_screen.dart
  // 入口: MainFrame 侧边栏升级按钮 + MeProfileScreen 升级至专业版行 + 会员卡免费试用按钮
  // 状态: 共享 MeProfileViewModel, 三处入口的 isPremiumUser 状态自动同步

  // ============================================================
  // SCREEN 06: 我的账单 (me-06) - 保留, 触发取消订阅弹窗
  // ============================================================
  Widget _buildBillingHistoryScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 18),
          onPressed: () => _navigate('me-01'),
        ),
        title: const Text('我的账单', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前订阅周期', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Talia 专业版 - 月度连续订阅', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                          const SizedBox(height: 4),
                          Text(
                            _viewModel.isPremiumUser
                                ? _viewModel.isAutoRenew
                                    ? '下期自动续费扣费日：2026-08-15 (金额: \$18.99/月)'
                                    : '订阅已取消自动续费。会员权益将持续至：2026-08-15'
                                : '当前暂无激活的连续包月订阅（基础普通版）',
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_viewModel.isPremiumUser && _viewModel.isAutoRenew)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (_viewModel.isPremiumUser && _viewModel.isAutoRenew) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _viewModel.openCancelSubscriptionModal(),
                      child: const Text('取消自动续费', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildCategoryTitle('历史发票及账单详情'),
          const SizedBox(height: 8),
          _buildLegacySettingsContainer(
            _viewModel.billingHistory.map((invoice) {
              return ListTile(
                onTap: () => _showToast('🧾 已生成并下载 ${invoice.date} 的发票账单 (${invoice.amount}) 电子档至手机'),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card, size: 16, color: Colors.grey),
                ),
                title: Text(invoice.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                subtitle: Text('账期结算日：${invoice.date}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(invoice.amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87)),
                        const Text('已扣款成功', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.download_rounded, size: 16, color: Colors.grey),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCREEN 08: 常规设置 (me-08) - 保留
  // ============================================================
  Widget _buildPreferenceSettingsScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 18),
          onPressed: () => _navigate('me-01'),
        ),
        title: const Text('常规与偏好设置', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          _buildCategoryTitle('AI 偏好设置'),
          const SizedBox(height: 8),
          _buildLegacySettingsContainer([
            ListTile(
              onTap: () => _showPreferenceSelector('选择默认纪要大纲模板', _viewModel.preferences.template, _viewModel.templates, (val) {
                _viewModel.updateTemplate(val);
                _showToast('已将默认纪要模板更改为: $val');
              }),
              leading: const Icon(Icons.schedule_rounded, color: Colors.grey),
              title: const Text('默认纪要模板', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_viewModel.preferences.template, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
            ListTile(
              onTap: () => _showPreferenceSelector('选择默认录制降噪语言', _viewModel.preferences.audioLang, _viewModel.audioLangs, (val) {
                _viewModel.updateAudioLang(val);
                _showToast('已将音频默认录制语言更改为: $val');
              }),
              leading: const Icon(Icons.public_rounded, color: Colors.grey),
              title: const Text('默认录制语言', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_viewModel.preferences.audioLang, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
            ListTile(
              onTap: () => _showPreferenceSelector('选择 AI 核心大模型', _viewModel.preferences.aiModel, _viewModel.aiModels, (val) {
                _viewModel.updateAiModel(val);
                _showToast('已将底层 AI 模型更改为: $val');
              }),
              leading: const Icon(Icons.auto_awesome_rounded, color: Colors.grey),
              title: const Text('默认底层 AI 模型', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_viewModel.preferences.aiModel, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
            ListTile(
              onTap: () => _showPreferenceSelector('选择智能互译目标语言', _viewModel.preferences.translationLang, _viewModel.translationLangs, (val) {
                _viewModel.updateTranslationLang(val);
                _showToast('已将转写翻译语言更改为: $val');
              }),
              leading: const Icon(Icons.translate_rounded, color: Colors.grey),
              title: const Text('翻译目标语言', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_viewModel.preferences.translationLang, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildCategoryTitle('伴侣软件系统设置'),
          const SizedBox(height: 8),
          _buildLegacySettingsContainer([
            SwitchListTile(
              value: _viewModel.preferences.onlyWifiUpload,
              onChanged: (val) {
                _viewModel.toggleOnlyWifiUpload();
              },
              title: const Text('仅在 Wi-Fi 下自动同步录音', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('关闭后可在移动网络下上传，注意流量消耗', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              activeThumbColor: const Color(0xFF10B981),
            ),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
            ListTile(
              onTap: () => _showToast('🎤 正在加载离线端侧语音解析包，目前已下载：中文离线包 120MB'),
              title: const Text('端侧语音解析包', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('管理离线下的音频人声高精定位解析', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('已下载 120MB', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF9FAFB)),
            ListTile(
              onTap: () {
                _showToast('🧹 正在扫描本地冗余碎片...');
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (!mounted) return;
                  _viewModel.clearCache();
                  _showToast('🧹 伴侣应用系统内缓存、大纲日志碎片已被完全清理释放！');
                });
              },
              title: const Text('清理本地临时存储缓存', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('物理擦除播放器音频大图缓存、AI生成草稿', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_viewModel.preferences.appCacheSize, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ============================================================
  // SCREEN 09: 意见反馈 (me-09) - 保留
  // ============================================================
  Widget _buildFeedbackFormScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 18),
          onPressed: () => _navigate('me-01'),
        ),
        title: const Text('意见与反馈建议', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          const Text(
            '您的反馈是 Talix 硬件伴侣不断自我进化的源动力，我们将于24小时内处理完毕。',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('反馈分类', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _viewModel.feedbackCategories.map((cat) {
              final isSel = _viewModel.feedbackCategory == cat;
              return InkWell(
                onTap: () {
                  _viewModel.feedbackCategory = cat;
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF18181B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel ? const Color(0xFF18181B) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('反馈描述', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _feedbackTextController,
                  maxLines: 4,
                  maxLength: 500,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text(
                    '$currentLength / $maxLength',
                    style: const TextStyle(fontSize: 9, color: Colors.black26, fontFamily: 'monospace'),
                  ),
                  decoration: const InputDecoration(
                    hintText: '请尽可能详细描述您遇到的故障场景、操作过程或对AI提问效果的建议...',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.black26),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('上传故障截图 (可选)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _showToast('📎 正在打开手机相册选择截图...');
              Future.delayed(const Duration(milliseconds: 600), () {
                if (!mounted) return;
                _viewModel.addUploadedFile('screenshot_${DateTime.now().millisecondsSinceEpoch % 1000}.png');
                _showToast('📎 成功添加 1 张截图');
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5, style: BorderStyle.solid),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: Colors.black26, size: 36),
                  SizedBox(height: 8),
                  Text('点击上传或拖放图片至此处', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('格式支持 PNG, JPG, JPEG (最多 3 张)', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
          ),
          if (_viewModel.uploadedFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _viewModel.uploadedFiles.map((fname) {
                return Chip(
                  label: Text(fname, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFFF3F4F6),
                  deleteIcon: const Icon(Icons.close, size: 12),
                  onDeleted: () {
                    _viewModel.removeUploadedFile(fname);
                    _showToast('🗑️ 已移除截图');
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          const Text('您的联系方式 (电子邮箱)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackEmailController,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: '请输入邮箱，方便我们将进度答复您（选填）',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          TalixButton(
            label: _feedbackTextController.text.trim().length < 10 ? '请填写至少 10 个字的反馈描述' : '提交反馈建议',
            variant: TalixButtonVariant.dark,
            height: 48,
            borderRadius: 16,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            backgroundColor: const Color(0xFF18181B),
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.white,
            onPressed: _feedbackTextController.text.trim().length < 10
                ? null
                : () {
                    _showToast('🚀 反馈封包提交中，正在同步本地日志...');
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (!mounted) return;
                      _showToast('❤️ 反馈提交成功！我们的技术服务人员正在紧张排查，非常感谢您的协助！');
                      _feedbackTextController.clear();
                      _feedbackEmailController.clear();
                      for (final fname in List<String>.from(_viewModel.uploadedFiles)) {
                        _viewModel.removeUploadedFile(fname);
                      }
                      _navigate('me-01');
                    });
                  },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCREEN 10: 关于 (me-10) - Figma 1218:10988
  // 1440x900 桌面布局, 240px 侧边栏 + 主区, 640px 居中内容
  //   - Content-Header: "我的 > 关于" (面包屑)
  //   - 中央: 160x160 产品 logo (16px 圆角) + "Talix AI Note" 24px Bold
  //           + "Current Version: 1.1.45" 14px
  //   - "检查更新" / "重启并更新" 按钮 (12px 32px padding, #111827 fill, 6px radius)
  //   - 底部: "用户协议  隐私政策" 12px Center #000000
  //         + "Copyright@2026 TALIX. All Rights Reserved." 12px Center #A1A1A1
  //   - 弹窗层: 点击"检查更新" → 'latest' (1295:11302) | 'available' (1295:11428)
  // ============================================================
  Widget _buildAboutAppScreen() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Content-Header (Figma 1218:11047) - "我的 > 关于" 面包屑
          _buildAboutContentHeader(),
          // 主区 (居中, 自适应高度)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      // 中央内容区 (logo + 标题 + 版本 + 按钮)
                      _buildAboutCenter(),
                      const Spacer(),
                      // 底部链接 (Figma 1295:11268 "用户协议  隐私政策")
                      const Center(
                        child: Text(
                          '用户协议  隐私政策',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: FigmaTokens.primary,
                            height: 15 / 12,
                            letterSpacing: 0.0046,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // 版权信息 (Figma 1218:11055)
                      const Center(
                        child: Text(
                          'Copyright@2026 TALIX. All Rights Reserved.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: FigmaTokens.textMuted,
                            height: 15 / 12,
                            letterSpacing: 0.0046,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Content-Header (Figma 1218:11047): 面包屑 "我的 > 关于"
  Widget _buildAboutContentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 8),
      child: Row(
        children: [
          // "我的" 16px #262626 (可点击返回主页面)
          GestureDetector(
            onTap: () => _navigate('me-01'),
            behavior: HitTestBehavior.opaque,
            child: const Text(
              '我的',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: FigmaTokens.primary,
                height: 1.0,
              ),
            ),
          ),
          // 分隔符 SVG (Figma 1218:11049 - 8.49x8.49 黑色右箭头)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: FigmaTokens.primary,
            ),
          ),
          // 当前页 "关于" 16px #262626
          const Text(
            '关于',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: FigmaTokens.primary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// 关于页面中央内容 (Figma 1218:11052/11053 + 1218:11054 + 1295:11269/11270)
  Widget _buildAboutCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 160x160 产品 logo (Figma 1218:11054, 16px 圆角)
        // 注: 实际生产中应使用 imageRef 资源; 此处使用渐变占位
        _buildAppLogo(),
        const SizedBox(height: 22),
        // 标题 "Talix AI Note" 24px Bold #262626 (Figma 1218:11052)
        const Text(
          'Talix AI Note',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: FigmaTokens.primary,
            height: 1.0,
            letterSpacing: 0.0035,
          ),
        ),
        const SizedBox(height: 8),
        // "Current Version: 1.1.45" 14px Regular #666666 (Figma 1218:11053)
        Text(
          'Current Version: ${_viewModel.currentVersion}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: FigmaTokens.textTertiary,
            height: 1.0,
            letterSpacing: 0.0119,
          ),
        ),
        const SizedBox(height: 46),
        // 升级按钮 (Figma 1295:11269 1218:10988 "检查更新" / 1295:11318 "重启并更新")
        _buildUpdateButton(),
      ],
    );
  }

  /// APP Logo 占位 (160x160, 16px 圆角)
  /// 实际生产中可替换为 `Image.asset('assets/images/talix_app_logo.png', fit: BoxFit.cover)`
  /// 设计资源 1218:11054 (imageRef 2c6a01b0d6f3226ee82dc568785387c414a78f3c) 在
  /// Figma 文件中, 当前以品牌渐变 + 闪光图标作为视觉占位, 保证整体观感与设计一致.
  Widget _buildAppLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09090B), Color(0xFF022C22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF34D399),
          size: 72,
        ),
      ),
    );
  }

  /// 升级按钮 (Figma 1218:10988 "检查更新" / 1295:11318 "重启并更新")
  /// 状态机:
  ///   - idle: "检查更新" (黑色)
  ///   - checking: "检查更新..." (黑色, 禁用, 显示 loading)
  ///   - available: "重启并更新" (黑色)
  ///   - latest: "检查更新" (黑色, 检查完毕, 但本次结果是最新)
  Widget _buildUpdateButton() {
    final state = _viewModel.updateState;
    final isChecking = state == 'checking';
    final isAvailable = state == 'available';

    final String label = isChecking
        ? '检查中…'
        : isAvailable
            ? '重启并更新'
            : '检查更新';

    return TalixButton(
      // isChecking 时用 loading 转圈, 底色保持深色 (disabled* 覆盖)。
      label: label,
      variant: TalixButtonVariant.dark,
      loading: isChecking,
      width: isAvailable ? 160 : 128,
      height: 44,
      borderRadius: 6,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      backgroundColor: const Color(0xFF111827),
      disabledBackgroundColor: const Color(0xFF111827),
      disabledForegroundColor: Colors.white,
      onPressed: () {
        if (isAvailable) {
          // 重启并更新 (Figma 1295:11318)
          _showToast('🔄 正在退出应用并启动更新安装器…');
          _viewModel.restartAndUpdate().then((_) {
            if (mounted) {
              _showToast('✅ 已完成更新，Talix 已升级到最新版本。');
            }
          });
        } else {
          // 检查更新 (Figma 1218:10988)
          _viewModel.checkForUpdate();
        }
      },
    );
  }

  // ============================================================
  // 模态弹窗层 (Figma 1218:6774 系列)
  // 通用规范: backdrop rgba(0,0,0,0.5) + 480px modal-card (8px radius, 白底, 0 4 4 rgba(0,0,0,0.25) 阴影)
  // ============================================================
  Widget _buildModalOverlay() {
    return Stack(
      children: [
        // 背景遮罩 (Figma EL-656445ac)
        Positioned.fill(
          child: GestureDetector(
            onTap: _viewModel.closeModal,
            child: Container(color: const Color(0x80000000)),
          ),
        ),
        // 弹窗卡片
        Center(
          child: _buildActiveModal(),
        ),
      ],
    );
  }

  Widget _buildActiveModal() {
    switch (_viewModel.activeModal) {
      case 'changePassword':
        return _buildChangePasswordModal();
      case 'deleteAccount':
        return _buildDeleteAccountModal();
      case 'cancelSubscription':
        return _buildCancelSubscriptionModal();
      case 'latestVersion':
        return _buildLatestVersionModal();
      case 'newFeatures':
        return _buildNewFeaturesModal();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 通用弹窗卡片容器 (Figma EL-8bbdcf4f / 直接 modal-card)
  Widget _buildModalCard({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return Container(
      width: 480,
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000), // rgba(0,0,0,0.25)
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏 (Figma EL-96a7c2e1): 标题居中 + 右侧关闭 X
          SizedBox(
            height: 49.28,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: FigmaTokens.primary,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: GestureDetector(
                    onTap: _viewModel.closeModal,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: FigmaTokens.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容区
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
            child: content,
          ),
          // 底部操作栏
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: actions,
            ),
          ),
        ],
      ),
    );
  }

  // 弹窗通用按钮
  Widget _buildModalCancelButton(String label, VoidCallback onPressed) {
    return _ModalSecondaryButton(label: label, onPressed: onPressed);
  }

  Widget _buildModalPrimaryButton(String label, VoidCallback onPressed) {
    return _ModalPrimaryButton(label: label, onPressed: onPressed);
  }

  // 弹窗通用 Input-Control (Figma 1218:11103 Input-Control)
  // 400x44, 白底, 1px #D1D1D1 描边, 8px 圆角, padding 0 12
  Widget _buildModalInputField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required bool showPassword,
    required VoidCallback onTogglePassword,
  }) {
    return Container(
      width: 400,
      height: 44,
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FigmaTokens.borderStrong, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 锁图标占位 (Figma EL-f652840d) - 16x16 #666666
          const SizedBox(
            width: 16,
            height: 16,
            child: Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: FigmaTokens.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: FigmaTokens.primary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: FigmaTokens.textFaint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 眼睛图标
          GestureDetector(
            onTap: onTogglePassword,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 16,
              height: 16,
              child: Icon(
                showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 16,
                color: FigmaTokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODAL 1: 修改密码 (Figma 1218:11084, 1218:11086 modal-card 480x442)
  // 3 Input-Control: 旧密码 / 新密码 / 再次输入
  // 取消 + 修改 按钮
  // ============================================================
  Widget _buildChangePasswordModal() {
    return _buildModalCard(
      title: '修改密码',
      content: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          children: [
            _buildModalInputField(
              controller: _oldPasswordController,
              hint: '请输入旧密码',
              obscure: !_viewModel.showOldPassword,
              showPassword: _viewModel.showOldPassword,
              onTogglePassword: () => _viewModel.showOldPassword = !_viewModel.showOldPassword,
            ),
            const SizedBox(height: 16),
            _buildModalInputField(
              controller: _newPasswordController,
              hint: '请输入新密码',
              obscure: !_viewModel.showNewPassword,
              showPassword: _viewModel.showNewPassword,
              onTogglePassword: () => _viewModel.showNewPassword = !_viewModel.showNewPassword,
            ),
            const SizedBox(height: 16),
            _buildModalInputField(
              controller: _confirmPasswordController,
              hint: '再次输入密码',
              obscure: !_viewModel.showConfirmPassword,
              showPassword: _viewModel.showConfirmPassword,
              onTogglePassword: () => _viewModel.showConfirmPassword = !_viewModel.showConfirmPassword,
            ),
          ],
        ),
      ),
      actions: [
        _buildModalCancelButton('取消', () {
          _oldPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _viewModel.closeModal();
        }),
        const SizedBox(width: 12),
        _buildModalPrimaryButton('修改', () async {
          if (_oldPasswordController.text.isEmpty) {
            _showToast('请输入旧密码');
            return;
          }
          if (_newPasswordController.text.length < 8) {
            _showToast('新密码至少8位');
            return;
          }
          if (_newPasswordController.text != _confirmPasswordController.text) {
            _showToast('两次输入的密码不一致');
            return;
          }
          try {
            await _viewModel.updatePassword(
              oldPassword: _oldPasswordController.text,
              newPassword: _newPasswordController.text,
            );
            _oldPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            _viewModel.closeModal();
            // 先 toast 再 logout: 确保提示在路由切换前被插入到 rootOverlay,
            // 否则 MeProfileScreen 随 MainFrame 一起被卸载, mounted 会变 false,
            // toast 就看不到了
            if (!mounted) return;
            _showToast('密码修改成功，请重新登录');
            // 后端在改密成功后会立刻作废旧 accessToken (再次请求会触发
            // "Token has been invalidated due to password change" 401)。
            // 这里走 forceLogoutAndGoToLogin: 内部既调 forceLogout 清本地态
            // (触发 AuthGate rebuild), 又用 rootNavigatorKey pushAndRemoveUntil
            // 兜底强制切到 LoginScreen。Windows 桌面端 _DesktopWindowShell
            // 包裹下 AuthGate 偶发不响应 notify, 必须有兜底导航才稳。
            final auth = context.read<AuthViewModel>();
            await forceLogoutAndGoToLogin(auth);
            _viewModel.logout();
          } catch (e) {
            if (!mounted) return;
            _showErrorToast(e);
          }
        }),
      ],
    );
  }

  // ============================================================
  // MODAL 2: 永久删除账号 (Figma 1218:11056, modal-card 480x348)
  // 描述: "删除账号不可逆..." + **!请先解绑所有设备** 警告
  // 取消 + 永久删除 按钮
  // ============================================================
  Widget _buildDeleteAccountModal() {
    return _buildModalCard(
      title: '永久删除账号',
      content: Padding(
        padding: const EdgeInsets.only(top: 36),
        child: SizedBox(
          width: 400,
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FigmaTokens.primary,
                height: 24 / 14,
              ),
              children: [
                TextSpan(text: '删除账号不可逆，请谨慎操作。删除后：\n您的个人信息，以及与账号关联的所有数据将永久删除，且无法恢复。\n同时，您账号下的会员权益，相关增值服务将立即失效，并且不予退款。\n'),
                TextSpan(
                  text: '!请先解绑所有设备',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE11D48), // rose-600
                    height: 24 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        _buildModalCancelButton('取消', _viewModel.closeModal),
        const SizedBox(width: 12),
        _buildModalPrimaryButton('永久删除', () async {
          try {
            await _viewModel.deleteAccount();
            // 先 toast 再 logout: 同样的原因, 一旦切回 LoginScreen,
            // MainFrame 下的 MeProfileScreen 会被卸载, mounted 变 false,
            // 此后调用 context 的 _showToast 会失效。
            // AppToast 使用 rootOverlay, 即使页面切换也会保留, 所以提前插入。
            if (!mounted) return;
            _showToast('账号已永久删除');
            // 账号已删除, 旧 token 在后端已无意义。走 forceLogoutAndGoToLogin
            // 兜底强切到 LoginScreen (与改密一致)。
            final auth = context.read<AuthViewModel>();
            await forceLogoutAndGoToLogin(auth);
            _viewModel.logout();
          } catch (e) {
            if (!mounted) return;
            _showErrorToast(e);
          }
        }),
      ],
    );
  }

  // ============================================================
  // MODAL 3: 取消订阅 (Figma 1218:11070, modal-card 480 auto)
  // 描述: "取消自动续费后，当前周期权益不受影响..."
  // 取消 + 取消订阅 按钮
  // ============================================================
  Widget _buildCancelSubscriptionModal() {
    return _buildModalCard(
      title: '取消订阅',
      content: const Padding(
        padding: EdgeInsets.only(top: 36),
        child: SizedBox(
          width: 400,
          child: Text(
            '取消自动续费后，当前周期权益不受影响，可继续使用至到期日。到期后将不再扣费，账户将自动降级为免费版。',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: FigmaTokens.primary,
              height: 24 / 14,
            ),
          ),
        ),
      ),
      actions: [
        _buildModalCancelButton('取消', _viewModel.closeModal),
        const SizedBox(width: 12),
        _buildModalPrimaryButton('取消订阅', () {
          _viewModel.isAutoRenew = false;
          _showToast('✅ 已成功取消连续订阅自动扣款。本期 Pro 权益保留至 2026-08-15 结束。');
          _viewModel.closeModal();
        }),
      ],
    );
  }

  // ============================================================
  // MODAL 4: 最新版本提示 (Figma 1295:11302, modal-card 480x260.56)
  // 描述: "您的 Talix 已是最新版本" 14px Regular #262626
  // 单一右侧 "知道了" 按钮 (Figma 1295:11313, 119 宽, fill #18181B, 圆角 6)
  // 标题 18px Bold #18181B (Figma 1295:11306)
  // ============================================================
  Widget _buildLatestVersionModal() {
    return Container(
      width: 480,
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏 (Figma 1295:11305): "最新版本" 18px Bold #18181B + 关闭 X
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    '最新版本',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FigmaTokens.primary,
                      height: 1.0,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _viewModel.closeModal,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: FigmaTokens.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容 (Figma 1295:11315): "您的Talix已是最新版本"
          const Padding(
            padding: EdgeInsets.fromLTRB(40, 16, 40, 0),
            child: Text(
              '您的Talix已是最新版本',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: FigmaTokens.primary,
                height: 20 / 14,
                letterSpacing: 0.0119,
              ),
            ),
          ),
          // 操作栏 (Figma 1295:11310): 右对齐 "知道了" 按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ModalPrimaryButton(
                  label: '知道了',
                  width: 119,
                  onPressed: _viewModel.closeModal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODAL 5: 新功能 (Figma 1295:11428, modal-card 480x434)
  //   - 标题 "新功能" 18px Bold #18181B (Figma 1295:11435)
  //   - 内容 (Figma 1295:11439):
  //       "版本信息 v1.0.0" 16px Semi Bold #262626 (Figma 1295:11440)
  //       "  1. 新功能：新增的功能特性\n  2. 新功能：新增的功能特性\n  3. 修复：已修复的Bug列表"
  //         14px Regular #666666, 24px line height (Figma 1295:11441)
  //   - 底部居中 "知道了" 按钮 (Figma 1295:11431/11432): 244x40, #18181B, 6px radius
  // ============================================================
  Widget _buildNewFeaturesModal() {
    return Container(
      width: 480,
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏: "新功能" + 关闭 X
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    '新功能',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FigmaTokens.primary,
                      height: 1.0,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _viewModel.closeModal,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: FigmaTokens.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 内容区 (Figma 1295:11439): 版本信息 + 列表
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 18, 40, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 版本信息 (Figma 1295:11440)
                Text(
                  '版本信息 ${_viewModel.updateTargetVersion}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FigmaTokens.primary,
                    height: 1.0,
                    letterSpacing: 0.0094,
                  ),
                ),
                const SizedBox(height: 8),
                // 更新内容 (Figma 1295:11441)
                Text(
                  _viewModel.updateChangelog.map((s) => '  $s').join('\n'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaTokens.textTertiary,
                    height: 24 / 14,
                    letterSpacing: 0.0119,
                  ),
                ),
              ],
            ),
          ),
          // 底部居中 "知道了" 按钮 (Figma 1295:11431/11432)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
            child: Center(
              child: TalixButton(
                label: '知道了',
                width: 244,
                height: 40,
                borderRadius: 6,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                backgroundColor: FigmaTokens.primary,
                onPressed: _viewModel.closeModal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 旧版偏好选择器 (保留)
  // ============================================================
  void _showPreferenceSelector(
    String title,
    String currentValue,
    List<String> options,
    Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        '关闭',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFF3F4F6)),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option == currentValue;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            onSelected(option);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF9FAFB) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                    color: isSelected ? const Color(0xFF111827) : Colors.black54,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, color: Color(0xFF111827), size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SCREEN 11: 服务器环境切换 (me-11)
  //   列表显示所有内置 + 自定义 profile, 当前活动项带 ✓ 标识
  //   点击行 → 弹确认 → 写入 SharedPreferences → notifyListeners
  //   (ApiClient / AuthViewModel 同时监听并自动同步 baseUrl 与登录态)
  // ============================================================
  Widget _buildServerSwitcherScreen() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
            children: [
              _buildSubScreenHeader(
                title: '服务器环境',
                onBack: () => _navigate('me-01'),
              ),
              const SizedBox(height: 16),
              // 当前活动 profile 的 baseUrl 提示 + 来源角标
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ServerConfigService>(
                  builder: (context, cfg, _) {
                    final active = cfg.active;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            active == null
                                ? '尚未选择环境'
                                : '当前: ${active.name}  ·  ${active.baseUrl}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: FigmaTokens.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (active != null &&
                            cfg.activeSource ==
                                ActiveServerSource.override) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFFFFD591)),
                            ),
                            child: const Text(
                              '配置文件覆盖',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFAD6800),
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 列表
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ServerConfigService>(
                  builder: (context, cfg, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: FigmaTokens.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            for (int i = 0; i < cfg.profiles.length; i++) ...[
                              _buildServerProfileTile(cfg, cfg.profiles[i]),
                              if (i < cfg.profiles.length - 1)
                                Container(
                                  margin: const EdgeInsets.only(left: 16),
                                  height: 1,
                                  color: FigmaTokens.border,
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 提示: 切换后会被强制登出,以及配置文件覆盖说明
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ServerConfigService>(
                  builder: (context, cfg, _) {
                    final hints = <String>[
                      '切换服务器后会清空当前登录态,需重新登录。',
                    ];
                    if (cfg.activeSource == ActiveServerSource.override) {
                      hints.add(
                        '当前服务器由 assets/config/active_server.json 强制指定,UI 切换仅对本次会话生效。',
                      );
                    } else {
                      hints.add(
                        '编辑 assets/config/active_server.json 可在启动时强制切换服务器。',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final h in hints) ...[
                          Text(
                            h,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: FigmaTokens.textFaint,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerProfileTile(ServerConfigService cfg, ServerProfile p) {
    final isActive = cfg.active?.id == p.id;
    return InkWell(
      onTap: isActive
          ? null
          : () => _confirmAndSwitchServer(cfg, p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 小圆点
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? FigmaTokens.primary
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: FigmaTokens.primary,
                      height: 1.0,
                    ),
                  ),
                  if (p.description != null && p.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.description!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: FigmaTokens.textMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check_rounded,
                  color: FigmaTokens.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndSwitchServer(
    ServerConfigService cfg,
    ServerProfile target,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('切换服务器环境'),
        content: Text('确认切换到「${target.name}」(${target.baseUrl})?\n当前登录态将被清空,需要重新登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('切换'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await cfg.setActive(target.id);
    // AuthViewModel 与 ApiClient 已订阅 ServerConfigService, 此处不需要再手动清状态
    if (mounted) _showToast('已切换到 ${target.name}');
  }

  // ============================================================
  // 旧版 helpers (保留, 仅给 me-08/me-09/me-10 用)
  // ============================================================
  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLegacySettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ============================================================
// 行定义 (用于 Settings-List)
// ============================================================
class _SettingsRowItem {
  final String label;
  final String? badge;
  final String? rightText;
  final VoidCallback onTap;

  const _SettingsRowItem({
    required this.label,
    required this.onTap,
    this.badge,
    this.rightText,
  });
}

// ============================================================
// 弹窗按钮 (Figma 1218:11065 取消 / 1218:11067 主操作)
//   - 取消: 1px #D1D1D1 描边, 6px 圆角, 119 宽, 白底, 文字 #262626
//   - 主操作: fill #262626, 6px 圆角, 119 宽, 白字
// ============================================================
class _ModalSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ModalSecondaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TalixButton(
      label: label,
      variant: TalixButtonVariant.neutralOutline,
      width: 119,
      height: 40,
      borderRadius: 6,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      backgroundColor: FigmaTokens.surfaceWhite,
      foregroundColor: FigmaTokens.primary,
      borderColor: FigmaTokens.borderStrong,
      onPressed: onPressed,
    );
  }
}

class _ModalPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;

  const _ModalPrimaryButton({
    required this.label,
    required this.onPressed,
    this.width = 119,
  });

  @override
  Widget build(BuildContext context) {
    return TalixButton(
      label: label,
      width: width,
      height: 40,
      borderRadius: 6,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      backgroundColor: FigmaTokens.primary,
      onPressed: onPressed,
    );
  }
}

// 升级订阅 helper widgets (BenefitColumn / PlanCheckColumn / PlanBulletRow /
// ComparisonCheckCell / CheckMarkPainter) 已迁出至 screens/upgrade_screen.dart
// 并重命名为 public (去掉下划线前缀), 此处不再保留.
