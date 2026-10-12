import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/device_model.dart';
import '../viewmodels/device_list_viewmodel.dart';
import '../data/device_item.dart';
import '../theme/app_colors.dart';
import '../widgets/common/common.dart';
import 'binding_screens.dart';
import 'device_detail_offline.dart';
import 'device_settings.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  late final DeviceListViewModel _viewModel;

  // 监听 AuthViewModel / DeviceModel,保证设备列表与"当前账号"严格一致:
  //   - 账号切换: 登入 → 拉新账号的设备; 登出 → 清空列表
  //   - 绑定/解绑: 重新拉取 (新设备出现 / 已解绑设备消失)
  bool _prevLoggedIn = false;
  bool _prevBound = false;

  @override
  void initState() {
    super.initState();
    _viewModel = DeviceListViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider.of(listen: true) 会在 didChangeDependencies 框架内部为这两个
    // ChangeNotifier 注册依赖;任一发出 notifyListeners() 时,本方法会被
    // Flutter 自动重新调用,这里就能 diff 状态触发刷新。
    final auth = Provider.of<AuthViewModel>(context);
    final device = Provider.of<DeviceModel>(context);

    final loggedInChanged = auth.isLoggedIn != _prevLoggedIn;
    final boundChanged = device.isBound != _prevBound;
    _prevLoggedIn = auth.isLoggedIn;
    _prevBound = device.isBound;

    if (loggedInChanged) {
      if (auth.isLoggedIn) {
        // 登入(或 bootstrap 恢复登录)→ 重新拉当前账号的设备列表
        _viewModel.refresh();
      } else {
        // 登出 → 立刻清空,避免下一个用户短暂看到上一个用户的设备
        _viewModel.clear();
      }
    } else if (boundChanged && auth.isLoggedIn) {
      // 已登录但绑定状态变化 (绑定新设备 / 解绑) → 重新拉取
      _viewModel.refresh();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceModel = Provider.of<DeviceModel>(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return _build(context, deviceModel, _viewModel.devices);
      },
    );
  }

  Widget _build(BuildContext context, DeviceModel deviceModel,
      List<DeviceItem> devices) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TALIX',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 22,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          // 1. Coat hanger button
          IconButton(
            icon: const Icon(Icons.checkroom_outlined, color: Colors.black87, size: 22),
            tooltip: '个性化',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('个性化皮肤暂未开放')),
              );
            },
          ),
          // 2. Chat bubble with red badge dot
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black87, size: 22),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: '设备反馈',
            onPressed: () => _showFeedbackDialog(context),
          ),
          // 3. Circle green '+' with floating PopupMenuButton
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'add') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDeviceSearchPage()),
                );
              } else if (value == 'scan') {
                _showScanDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text('添加设备', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Colors.black54, size: 18),
                    SizedBox(width: 8),
                    Text('扫一扫', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: !_viewModel.loading && _viewModel.devices.isEmpty
          ? _buildEmptyHomeState(context)
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My product',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Devices Bento Grid (2 columns)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.92,
                      ),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final dev = devices[index];
                        return _buildDeviceCard(context, dev);
                      },
                    ),

                    const SizedBox(height: 28),

                    // User Manual & Onboarding Section
                    _buildOnboardingCard(context),

                    const SizedBox(height: 16),

                    // Help & Resource Center Section
                    _buildHelpSection(context),
                  ],
                ),
              ),
            ),
    );
  }

  // Beautiful empty home state exactly matching screenshot
  Widget _buildEmptyHomeState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating Paper & Green Open Box Custom Drawing
            const EmptyBoxIllustration(),
            const SizedBox(height: 24),
            // Text caption
            const Text(
              'Add devices to enable smart living',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            // + Add button (rounded capsule)
            TalixButton(
              label: 'Add',
              icon: Icons.add,
              expand: false,
              height: 44,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDeviceSearchPage()),
                );
              },
            ),
            const SizedBox(height: 60), // Push slightly upward
          ],
        ),
      ),
    );
  }

  void _showScanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('扫一扫', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 80, color: Color(0xFF10B981)),
            SizedBox(height: 12),
            Text('扫描产品包装或说明书上的二维码以绑定设备。', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, DeviceItem dev) {
    final isTalix = dev.id == 'talix_note';
    final isPower = dev.id == 'zeta_power';

    return GestureDetector(
      onTap: () {
        if (dev.connected) {
          if (isTalix) {
            // 已连接设备: 先进入设备详情 / 设置页 (Figma 1218:4679 设备列表 → 设备详情),
            // 文件管理入口在 DeviceSettingsScreen 内部, 避免从设备直接跳到文件管理
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeviceSettingsScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${dev.name} 已连接，状态良好。'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        } else {
          // If unconnected, navigate to the Offline Device Details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceDetailOfflineScreen(device: dev),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dev.connected ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dev.connected ? const Color(0xFFE5E7EB) : Colors.transparent,
            width: 1,
          ),
          boxShadow: dev.connected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row 1: Connection Badge & Bluetooth icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dev.connected
                        ? const Color(0xFFE6F7F0)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dev.connected ? '已连接' : '未连接',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: dev.connected
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Icon(
                  dev.connected ? Icons.bluetooth : Icons.bluetooth_disabled,
                  size: 14,
                  color: dev.connected ? Colors.blue : Colors.grey,
                ),
              ],
            ),

            // Row 2: Center Device Icon representation
            Center(
              child: isTalix
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(width: 28, height: 2, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(vertical: 1)),
                              Container(width: 28, height: 2, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(vertical: 1)),
                              Container(width: 18, height: 2, color: Colors.grey.shade400, margin: const EdgeInsets.symmetric(vertical: 1)),
                            ],
                          ),
                        ),
                        if (dev.connected)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    )
                  : isPower
                      ? Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('ZETA', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            ],
                          ),
                        )
                      : Opacity(
                          opacity: 0.4,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.headphones, color: Colors.grey, size: 24),
                          ),
                        ),
            ),

            // Row 3: Name & SN info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dev.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dev.serialNumber,
                  style: const TextStyle(
                    fontSize: 8,
                    fontFamily: 'monospace',
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '新手指引',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '快速了解如何使用您的 AI Note 硬件录音与AI整理',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showOnboardingOverlay(context),
            child: const Text(
              '查看 >',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '帮助与支持',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildHelpRow(
            icon: Icons.bluetooth_audio,
            title: '设备蓝牙连接异常排查',
            onTap: () => _showHelpDetail(context, '蓝牙排查', '请确保:\n1. 您的 Talix 硬件在手机 1 米范围内，且处于开机状态。\n2. 手机蓝牙开关已开启，且未被其他App占用。\n3. 如果搜索失败，可长按设备录音键3秒重置蓝牙广播状态。'),
          ),
          const Divider(height: 20, color: Color(0xFFF3F4F6)),
          _buildHelpRow(
            icon: Icons.cloud_done,
            title: '双声道降噪与AI总结原理',
            onTap: () => _showHelpDetail(context, '算法与总结', '本设备搭载四麦克风智能阵列，支持多声道指向性噪声消除技术。\n通用降噪: 适合日常绝大部分面对面记录。\n全向会议: 开启四周无损声场拾音，智能定位扬声器。\n面对面访谈: 特殊角度算法隔离背后嘈杂人声。\n无损原声: 跳过降噪滤波器输出完整的PCM广播级原音。'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('设备反馈', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '在使用 Talix 智能录音硬件中遇到什么问题吗？我们的极客团队将立刻排查。',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '描述您碰到的蓝牙或录音问题...',
                  hintStyle: const TextStyle(fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            TalixButton(
              label: '提交',
              size: TalixButtonSize.small,
              expand: false,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('感谢您的反馈！我们的硬件极客小组会尽快回访。'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showHelpDetail(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: Text(content, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5)),
          actions: [
            TalixButton(
              label: '我知道了',
              variant: TalixButtonVariant.dark,
              size: TalixButtonSize.small,
              expand: false,
              fontSize: 11,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showOnboardingOverlay(BuildContext context) {
    // Interactive step-by-step Onboarding Tutorial Overlay (Perfect clone of screen bind-08)
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'onboarding',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setStateOverlay) {
            int currentStep = 1;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // White highlight mock card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      '极客新手指引 (Step $currentStep/3)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                  onPressed: () => Navigator.pop(context),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (currentStep == 1) ...[
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mic, size: 48, color: Color(0xFF10B981)),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '第1步: 硬件一键开机录音',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '长按硬件侧面录音键，LED 指示灯变为呼吸绿光即代表已开启本地硬件级降噪录音，全程无需手机参与。',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                              ),
                            ] else if (currentStep == 2) ...[
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.sync, size: 48, color: Colors.blue),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '第2步: 手机极速蓝牙同步',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '当您靠近手机时，Talix App 会自动建立高速低功耗蓝牙连接通道，将您设备中的音频碎片同步至 App。',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                              ),
                            ] else ...[
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.psychology, size: 48, color: Colors.amber),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '第3步: AI 智能总结与问答',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '在文件页面使用 AI 智能提问，可一键总结冗长的录音。您不仅能查阅详细的时间戳转写，还能直接在提问框与您的录音进行深入问答。',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (currentStep > 1)
                                  TalixButton(
                                    label: '上一步',
                                    variant: TalixButtonVariant.neutralOutline,
                                    size: TalixButtonSize.small,
                                    expand: false,
                                    borderRadius: 12,
                                    fontSize: 11,
                                    onPressed: () {
                                      setStateOverlay(() {
                                        currentStep--;
                                      });
                                    },
                                  )
                                else
                                  const SizedBox.shrink(),
                                TalixButton(
                                  label: currentStep == 3 ? '完成指引' : '下一步',
                                  size: TalixButtonSize.small,
                                  expand: false,
                                  borderRadius: 12,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  onPressed: () {
                                    if (currentStep < 3) {
                                      setStateOverlay(() {
                                        currentStep++;
                                      });
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class EmptyBoxIllustration extends StatelessWidget {
  const EmptyBoxIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Oval Shadow
          Positioned(
            bottom: 25,
            child: Container(
              width: 120,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: const BorderRadius.all(Radius.elliptical(60, 5)),
              ),
            ),
          ),
          // Isometric Box Drawing
          CustomPaint(
            size: const Size(110, 110),
            painter: IsometricBoxPainter(),
          ),
        ],
      ),
    );
  }
}

class IsometricBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 5);
    final w = size.width * 0.45; // half width
    final h = size.height * 0.28; // height of front panels

    final paintFrontLeft = Paint()
      ..color = const Color(0xFF5DF298) // bright neon mint green
      ..style = PaintingStyle.fill;

    final paintFrontRight = Paint()
      ..color = const Color(0xFF10B981) // emerald green
      ..style = PaintingStyle.fill;

    final paintInside = Paint()
      ..color = const Color(0xFFE6F7F0) // extremely light mint green
      ..style = PaintingStyle.fill;

    final paintFlapLeft = Paint()
      ..color = const Color(0xFF96F8C1) // soft green flap
      ..style = PaintingStyle.fill;

    final paintFlapRight = Paint()
      ..color = const Color(0xFF3BE18E) // mid green flap
      ..style = PaintingStyle.fill;

    // 1. Draw front left panel
    final pathLeft = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - w, center.dy + w * 0.4)
      ..lineTo(center.dx - w, center.dy + w * 0.4 + h)
      ..lineTo(center.dx, center.dy + h)
      ..close();
    canvas.drawPath(pathLeft, paintFrontLeft);

    // 2. Draw front right panel
    final pathRight = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx + w, center.dy + w * 0.4)
      ..lineTo(center.dx + w, center.dy + w * 0.4 + h)
      ..lineTo(center.dx, center.dy + h)
      ..close();
    canvas.drawPath(pathRight, paintFrontRight);

    // 3. Draw inside top area
    final pathInside = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx - w, center.dy - w * 0.1)
      ..lineTo(center.dx, center.dy - w * 0.4)
      ..lineTo(center.dx + w, center.dy - w * 0.1)
      ..close();
    canvas.drawPath(pathInside, paintInside);

    // 4. Draw open flaps
    // Left flap
    final pathFlapLeft = Path()
      ..moveTo(center.dx - w, center.dy + w * 0.4)
      ..lineTo(center.dx - w - 12, center.dy + w * 0.2)
      ..lineTo(center.dx - w / 2 - 8, center.dy - w * 0.1)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathFlapLeft, paintFlapLeft);

    // Right flap
    final pathFlapRight = Path()
      ..moveTo(center.dx + w, center.dy + w * 0.4)
      ..lineTo(center.dx + w + 12, center.dy + w * 0.2)
      ..lineTo(center.dx + w / 2 + 8, center.dy - w * 0.1)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathFlapRight, paintFlapRight);

    // Back flap
    final pathFlapBack = Path()
      ..moveTo(center.dx - w, center.dy - w * 0.1)
      ..lineTo(center.dx - w * 0.4, center.dy - w * 0.5)
      ..lineTo(center.dx + w * 0.4, center.dy - w * 0.5)
      ..lineTo(center.dx + w, center.dy - w * 0.1)
      ..close();
    canvas.drawPath(pathFlapBack, paintFlapRight);

    // 5. Draw floating sheets of paper above the box
    final paintFloatingPaper = Paint()
      ..color = const Color(0xFF9DF5CA)
      ..style = PaintingStyle.fill;
    
    final pathPaper1 = Path()
      ..moveTo(center.dx - 10, center.dy - w * 0.6)
      ..lineTo(center.dx - 30, center.dy - w * 0.7)
      ..lineTo(center.dx - 12, center.dy - w * 0.9)
      ..lineTo(center.dx + 10, center.dy - w * 0.8)
      ..close();
    canvas.drawPath(pathPaper1, paintFloatingPaper);

    // 6. Draw dotted curve showing paper floating up
    final paintDotted = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final dashPath = Path()
      ..moveTo(center.dx, center.dy - w * 0.2)
      ..quadraticBezierTo(center.dx + 25, center.dy - w * 0.4, center.dx + 5, center.dy - w * 0.65);
    
    canvas.drawPath(dashPath, paintDotted);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
