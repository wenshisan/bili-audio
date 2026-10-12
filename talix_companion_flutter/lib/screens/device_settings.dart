import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../viewmodels/device_model.dart';
import '../viewmodels/device_settings_viewmodel.dart';
import '../widgets/common/common.dart';
import '../widgets/device_info_widgets.dart';
import '../widgets/recording_bar_widgets.dart';
import 'binding_screens.dart';
import 'firmware_update.dart';
import 'recordings_feed.dart';

// ============================================================
// 设备详情 / 设置 (MVVM - 薄 View)
// 状态: 录音模拟 (在 ViewModel) + 设备信息 (Provider)
//
// PC 布局对齐 Figma「Talix AI Device UI」:
//   669:5665  已连接 / 未录音  — 标题 + 开始录音按钮 + 5 张信息卡
//   669:6574  录音中          — 按钮换成录音状态栏
//   669:5853  下拉展开        — 「录音忘关提醒」选项菜单
//
// 度量: 内容区 800 宽居中 (左右各 199 留白), 卡片间距 16,
//       标题 24px 距顶 48, 卡片区距顶 112。
// ============================================================
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  late final DeviceSettingsViewModel _viewModel;

  bool _isEndDialogOpen = false; // 跟踪结束对话框是否已通过 showDialog 打开

  @override
  void initState() {
    super.initState();
    _viewModel = DeviceSettingsViewModel();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  /// 监听 ViewModel 变化: 当 isEndDialogVisible 变为 true 时弹出对话框
  /// 使用 Flutter 的 showDialog (基于 Overlay 系统), 保证对话框**真正悬浮于界面之上**,
  /// 不会挤压/影响设备详情页的布局
  void _onViewModelChanged() {
    if (_viewModel.isEndDialogVisible && !_isEndDialogOpen) {
      _openEndDialog();
    } else if (!_viewModel.isEndDialogVisible && _isEndDialogOpen) {
      _closeEndDialog();
    }
  }

  void _openEndDialog() {
    if (!mounted) return;
    _isEndDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: true, // 点击背景关闭
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useRootNavigator: true, // 使用根 Navigator, 确保覆盖整个 app
      builder: (dialogContext) => _buildEndDialogContent(dialogContext),
    ).then((_) {
      // 对话框被关闭 (任何方式: X/继续/结束/点击背景/Navigator.pop)
      // _isEndDialogOpen 可能已经在 _closeEndDialog 里被置为 false, 这里再做一次幂等保护
      _isEndDialogOpen = false;
      // 同步 ViewModel 状态: 如果用户是按"结束"则状态已被 confirmEndRecording 处理;
      // 其他关闭方式 (X/继续/背景) 则需要把 isEndDialogVisible 重置为 false
      if (_viewModel.isEndDialogVisible) {
        _viewModel.hideEndDialog();
      }
    });
  }

  void _closeEndDialog() {
    if (_isEndDialogOpen && mounted) {
      // 先标记为已关闭, 防止 _onViewModelChanged 在 Navigator.pop 完成前重复触发
      _isEndDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPcMode = MediaQuery.of(context).size.width >= 750;
    final model = Provider.of<DeviceModel>(context);

    if (isPcMode) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => _buildPcLayout(context, model),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('设备设置', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _buildMobileLayout(context, model);
        },
      ),
    );
  }

  // ============================================================
  // PC 端布局 (Figma 669:5665 / 669:6574 / 669:5853)
  // 结构 (800 宽内容区居中):
  //   1. 返回按钮 (仅 pushed 进入时)
  //   2. Header Row: 设备名 24px (左) + 开始录音按钮 / 录音状态栏 (右)
  //   3. 信息卡: 设备名称 / 序列号 / 电池电量 / 存储空间 / 录音时长 / 固件版本
  //   4. 录音设置卡: 录音模式 / 录音忘关提醒
  //   5. 指示灯卡 / 文件管理卡 / 解绑并重置卡
  // ============================================================
  static const double _contentWidth = 800;

  Widget _buildPcLayout(BuildContext context, DeviceModel model) {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: _contentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 返回按钮 (从设备列表 pushed 进入时才有, 桌面端无 AppBar)
              if (Navigator.canPop(context)) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBackButton(context),
                ),
              ],

              // Header: 设备名 (左) ⟷ 录音按钮 / 状态栏 (右)
              // Figma: 标题距内容区顶 48, 按钮 56 高与标题基线区共处一行
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      model.deviceName,
                      style: DeviceInfoText.pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildRecordingControl(context, model),
                ],
              ),
              const SizedBox(height: 44),

              // ── 信息卡 (Figma 669:5805) ──────────────────
              _buildDeviceInfoCard(context, model),
              const SizedBox(height: 16),

              // ── 录音设置卡 (Figma 669:5750) ──────────────
              _buildRecordingSettingsCard(context, model),
              const SizedBox(height: 16),

              // ── 指示灯 (Figma 669:5767) ──────────────────
              DeviceInfoCard(
                children: [
                  DeviceInfoRow(
                    label: '指示灯',
                    subtitle: '关闭此功能后，录音卡上的指示灯将不再显示录音状态',
                    trailing: TalixSwitch.compact(
                      value: model.indicatorLight,
                      onChanged: model.toggleIndicator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 文件管理 (Figma 669:5778) ────────────────
              DeviceInfoCard(
                children: [
                  DeviceInfoRow(
                    label: '文件管理',
                    subtitle: '管理录音卡及手机内的录音文件',
                    trailing: const DeviceRowChevron(),
                    onTap: () => _openFileManager(context, model),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 解绑并重置 (Figma 669:5789) ──────────────
              DeviceInfoCard(
                children: [
                  DeviceInfoRow(
                    label: '解绑并重置',
                    isDanger: true,
                    onTap: () => _triggerUnbind(context, model),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// 右上角录音控件: 未录音显示开始按钮, 录音中显示状态栏 (Figma 669:6635)。
  ///
  /// 按钮右侧 caret 展开录音模式选择 (与「录音模式」行共用一份选项)。
  Widget _buildRecordingControl(BuildContext context, DeviceModel model) {
    if (_viewModel.isRecording) {
      return RecordingStatusBar(
        elapsedText: _viewModel.formatTimeLong(_viewModel.recordingTime),
        fileName: _viewModel.recordingFileName,
        isPaused: _viewModel.isPaused,
        onTogglePause: _viewModel.togglePause,
        onStop: _viewModel.showEndDialog,
        onMark: () => _showMarkToast(context),
        onCaretTap: null,
      );
    }

    return DeviceAnchoredMenu<String>(
      options: _modeOptions,
      selected: model.recordingMode,
      onSelected: (mode) {
        model.setRecordingMode(mode);
        _viewModel.startRecording();
      },
      anchorBuilder: (context, toggle) => StartRecordingButton(
        onTap: _viewModel.startRecording,
        onCaretTap: toggle,
      ),
    );
  }

  /// 信息卡 6 行 (Figma 669:5806 ~ 5852)
  Widget _buildDeviceInfoCard(BuildContext context, DeviceModel model) {
    return DeviceInfoCard(
      children: [
        // 设备名称 — 右侧 24×24 编辑图标
        DeviceInfoRow(
          label: '设备名称',
          onTap: () => _showRenameDialog(context, model),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(model.deviceName, style: DeviceInfoText.rowValue),
              const SizedBox(width: 2),
              SvgPicture.asset(
                'assets/images/ic_edit_name.svg',
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),
        // 序列号 — 只读
        DeviceInfoRow(
          label: '序列号',
          trailing: DeviceRowValue(value: model.displaySN),
        ),
        // 电池电量 — 充电时右侧带「充电中」徽标
        DeviceInfoRow(
          label: '电池电量',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(model.batteryText, style: DeviceInfoText.rowValue),
              if (model.isCharging) ...[
                const SizedBox(width: 8),
                const DeviceStatusPill.charging(),
              ],
            ],
          ),
        ),
        // 存储空间 — 进文件管理
        DeviceInfoRow(
          label: '存储空间',
          trailing: DeviceRowValue(value: model.storageText, showChevron: true),
          onTap: () => _openFileManager(context, model),
        ),
        // 录音时长 — 进文件管理
        DeviceInfoRow(
          label: '录音时长',
          trailing:
              DeviceRowValue(value: model.recordingHoursText, showChevron: true),
          onTap: () => _openFileManager(context, model),
        ),
        // 固件版本 — 有新版本时带「可升级」徽标, 点击进固件升级页
        DeviceInfoRow(
          label: '固件版本',
          onTap: () => _openFirmwareUpdate(context, model),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(model.firmwareVersion, style: DeviceInfoText.rowValue),
              if (model.firmwareUpdatable) ...[
                const SizedBox(width: 8),
                const DeviceStatusPill.updatable(),
              ],
              const SizedBox(width: 8),
              const DeviceRowChevron(),
            ],
          ),
        ),
      ],
    );
  }

  /// 录音设置卡 (Figma 669:5750): 录音模式 48 + 录音忘关提醒 64
  Widget _buildRecordingSettingsCard(BuildContext context, DeviceModel model) {
    return DeviceInfoCard(
      children: [
        DeviceSelectRow<String>(
          label: '录音模式',
          options: _modeOptions,
          selected: model.recordingMode,
          onSelected: model.setRecordingMode,
        ),
        DeviceSelectRow<String>(
          label: '录音忘关提醒',
          subtitle: '录音达到设定时长前进行提醒',
          options: _forgetOptions,
          selected: model.forgetReminder,
          onSelected: model.setForgetReminder,
        ),
      ],
    );
  }

  /// 录音模式选项 (与移动端 bottom sheet 的四个模式一致)
  static const List<DeviceMenuOption<String>> _modeOptions = [
    DeviceMenuOption(value: 'general', label: '通用模式'),
    DeviceMenuOption(value: 'meeting', label: '会议模式'),
    DeviceMenuOption(value: 'interview', label: '面对面模式'),
    DeviceMenuOption(value: 'backup', label: '无损原声'),
  ];

  /// 录音忘关提醒选项 (Figma 669:5993)
  static const List<DeviceMenuOption<String>> _forgetOptions = [
    DeviceMenuOption(value: 'unlimited', label: '不限制'),
    DeviceMenuOption(value: '8h', label: '8小时'),
    DeviceMenuOption(value: '12h', label: '12小时'),
    DeviceMenuOption(value: '24h', label: '24小时'),
  ];

  void _openFileManager(BuildContext context, DeviceModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordingsFeedScreen(
          // 按当前设备的真实 SN 过滤文件列表, 面包屑显示该设备名
          deviceSN: model.deviceSN.isEmpty ? null : model.deviceSN,
          deviceName: model.deviceName,
        ),
      ),
    );
  }

  void _openFirmwareUpdate(BuildContext context, DeviceModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FirmwareUpdateScreen(
          currentBattery: model.batteryLevel,
          deviceSN: model.displaySN,
        ),
      ),
    );
  }

  void _triggerUnbind(BuildContext context, DeviceModel model) {
    UnbindingHandler.triggerUnbindFlow(context, true, () async {
      await model.unbindDevice(deviceSN: model.deviceSN);
    });
  }

  void _showMarkToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已在当前位置添加标记'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, size: 14, color: AppColors.textPrimary),
              SizedBox(width: 4),
              Text('返回', style: DeviceInfoText.rowLabel),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 结束录音确认对话框内容 (Figma 1218:6596)
  // 由 showDialog 渲染 (基于 Flutter Overlay 系统), 真正悬浮于界面之上,
  // **不会挤压/影响设备详情页的布局**
  // 480x260.56 modal-card, 8px radius, boxShadow 0 4 4 rgba(0,0,0,0.25)
  // 背景半透明 rgba(0,0,0,0.5) 由 showDialog 的 barrierColor 提供
  // 标题 "结束录音" 18px Bold #18181B + 右上角关闭 X
  // 内容 "录音结束后将自动保存" 14px Regular #6B7280, 2em 行高
  // 底部居中按钮: "继续" (white border #D1D5DB) + "结束" (fill #18181B), 间距 12px
  //
  // 关键行为约束 (用户要求):
  // - X 按钮 / "继续" 按钮 / 点击背景: **只关闭对话框, 不停止录音**
  // - 唯一停止录音的入口: 底部 "结束" 按钮 → confirmEndRecording → stopRecording
  // ============================================================
  Widget _buildEndDialogContent(BuildContext context) {
    return Center(
      // 关键: Dialog 的 Material 在 widget tree 中的位置不一定能被 InkWell 找到,
      // 这里显式包一层 Material(type: transparency) 提供 Material ancestor,
      // 既不改变视觉 (透明), 又能让 InkWell/Tooltip 正常渲染
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 480,
          height: 260.56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 标题 + 关闭 X
              Positioned(
                top: 40,
                left: 40,
                right: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '结束录音',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    InkWell(
                      onTap: _viewModel.hideEndDialog,
                      borderRadius: BorderRadius.circular(2),
                      child: const Tooltip(
                        message: '关闭',
                        child: SizedBox(
                          width: 15.56,
                          height: 15.56,
                          child: Icon(Icons.close, size: 12, color: Color(0xFF000000)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 内容
              const Positioned(
                top: 85,
                left: 40,
                child: Text(
                  '录音结束后将自动保存',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 2.0,
                  ),
                ),
              ),

              // 底部按钮
              Positioned(
                top: 183.56,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "继续" 按钮: 仅关闭对话框, 不停止录音
                      _buildDialogButton(
                        label: '继续',
                        isPrimary: false,
                        onTap: _viewModel.hideEndDialog,
                      ),
                      const SizedBox(width: 12),
                      // "结束" 按钮: 唯一停止录音的入口
                      _buildDialogButton(
                        label: '结束',
                        isPrimary: true,
                        onTap: () => _confirmEndRecording(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 结束对话框中的按钮
  Widget _buildDialogButton({
    required String label,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: isPrimary
                ? null
                : Border.all(color: const Color(0xFFD1D5DB), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isPrimary ? Colors.white : const Color(0xFF18181B),
            ),
          ),
        ),
      ),
    );
  }

  // 点击"结束"按钮的逻辑: 停止录音 + 收起对话框 + 显示提示
  void _confirmEndRecording(BuildContext context) {
    _viewModel.confirmEndRecording();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('录音已保存在卡内，请至文件管理中查看及同步！'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // 移动端布局
  // ============================================================
  Widget _buildMobileLayout(BuildContext context, DeviceModel model) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // 3D渲染卡片展示区域
        _buildDevice3DCard(model),
        const SizedBox(height: 20),

        // 设备基础设置分组
        _buildSectionTitle('基本控制'),
        _buildSettingGroup([
          ListTile(
            title: const Text('设备重命名', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(model.deviceName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () => _showRenameDialog(context, model),
          ),
          ListTile(
            title: const Text('设备指示灯', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('开启或关闭硬件录音状态指示灯', style: TextStyle(fontSize: 10, color: Colors.grey)),
            trailing: TalixSwitch(
              value: model.indicatorLight,
              onChanged: (val) => model.toggleIndicator(val),
            ),
          ),
        ]),

        const SizedBox(height: 20),
        _buildSectionTitle('降噪录音预设'),
        _buildSettingGroup([
          ListTile(
            title: const Text('多声道录音模式', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getModeLabel(model.recordingMode), style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () => _showRecordingModeSelector(context, model),
          ),
          ListTile(
            title: const Text('防忘关自动提醒', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getForgetLabel(model.forgetReminder), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            onTap: () => _showForgetReminderSelector(context, model),
          ),
        ]),

        const SizedBox(height: 32),

        // 解绑按钮
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TalixButton(
              label: '解除绑定并清除数据',
              variant: TalixButtonVariant.dangerOutline,
              height: 48,
              borderRadius: 12,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              onPressed: () {
                bool simulatedUnsynced = true;
                UnbindingHandler.triggerUnbindFlow(context, simulatedUnsynced, () async {
                  await model.unbindDevice(deviceSN: model.deviceSN);
                });
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDevice3DCard(DeviceModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade800, Colors.black87],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                  SizedBox(height: 12),
                  Icon(Icons.mic, color: Colors.white24, size: 24),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.deviceName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('SN: T-2026-F981X', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.battery_4_bar, size: 16, color: model.batteryLevel < 0.3 ? Colors.red : Colors.green),
                    const SizedBox(width: 4),
                    Text('${(model.batteryLevel * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    const CircleAvatar(radius: 3, backgroundColor: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('固件版本 v1.0.1', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSettingGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'general': return '通用模式';
      case 'meeting': return '会议模式';
      case 'interview': return '面对面模式';
      case 'backup': return '无损原声';
      default: return '通用模式';
    }
  }

  String _getForgetLabel(String d) {
    switch (d) {
      case 'unlimited': return '不限制';
      case '8h': return '8小时';
      case '12h': return '12小时';
      case '24h': return '24小时';
      default: return '不限制';
    }
  }

  void _showRenameDialog(BuildContext context, DeviceModel model) {
    final controller = TextEditingController(text: model.deviceName);
    showDialog(
      context: context,
      builder: (context) {
        return CustomRenameDialog(controller: controller, model: model);
      },
    );
  }

  void _showRecordingModeSelector(BuildContext context, DeviceModel model) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('多声道智能降噪模式', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              _buildRadioOption(context, model, 'general', '通用模式', '适用于大部分日常沟通、随想备忘。'),
              _buildRadioOption(context, model, 'meeting', '会议模式', '增强四周声音拾取，高保真智能定位。'),
              _buildRadioOption(context, model, 'interview', '面对面模式', '指向性阵列降噪，滤除背景噪音。'),
              _buildRadioOption(context, model, 'backup', '无损原声', '提供不带软件降噪的无损PCM原音输出。'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioOption(BuildContext context, DeviceModel model, String key, String title, String desc) {
    final isSelected = model.recordingMode == key;
    return InkWell(
      onTap: () {
        model.setRecordingMode(key);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF10B981) : Colors.black87)),
                  Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: Color(0xFF10B981), size: 20)
          ],
        ),
      ),
    );
  }

  void _showForgetReminderSelector(BuildContext context, DeviceModel model) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('防止录音忘关设定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              ListTile(title: const Text('不限制自动关闭'), trailing: model.forgetReminder == 'unlimited' ? const Icon(Icons.check, color: Color(0xFF10B981)) : null, onTap: () { model.setForgetReminder('unlimited'); Navigator.pop(context); }),
              ListTile(title: const Text('连续运行8小时后关机提示'), trailing: model.forgetReminder == '8h' ? const Icon(Icons.check, color: Color(0xFF10B981)) : null, onTap: () { model.setForgetReminder('8h'); Navigator.pop(context); }),
              ListTile(title: const Text('连续运行12小时后关机提示'), trailing: model.forgetReminder == '12h' ? const Icon(Icons.check, color: Color(0xFF10B981)) : null, onTap: () { model.setForgetReminder('12h'); Navigator.pop(context); }),
              ListTile(title: const Text('连续运行24小时后关机提示'), trailing: model.forgetReminder == '24h' ? const Icon(Icons.check, color: Color(0xFF10B981)) : null, onTap: () { model.setForgetReminder('24h'); Navigator.pop(context); }),
            ],
          ),
        );
      },
    );
  }
}

class CustomRenameDialog extends StatefulWidget {
  final TextEditingController controller;
  final DeviceModel model;

  const CustomRenameDialog({super.key, required this.controller, required this.model});

  @override
  State<CustomRenameDialog> createState() => _CustomRenameDialogState();
}

class _CustomRenameDialogState extends State<CustomRenameDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('设备重命名', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: widget.controller,
        maxLength: 15,
        decoration: const InputDecoration(
          hintText: '请输入设备名称',
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Colors.grey)),
        ),
        TalixButton(
          label: '确定',
          size: TalixButtonSize.small,
          expand: false,
          onPressed: () {
            if (widget.controller.text.trim().isNotEmpty) {
              widget.model.updateDeviceName(widget.controller.text.trim());
            }
            Navigator.pop(context);
          },
        )
      ],
    );
  }
}

class BlinkingDot extends StatefulWidget {
  const BlinkingDot({super.key});

  @override
  State<BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const CircleAvatar(
        radius: 4,
        backgroundColor: Colors.red,
      ),
    );
  }
}
