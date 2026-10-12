import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'data/device_item.dart';
import 'screens/device_settings.dart';
import 'screens/recycle_bin_screen.dart';
import 'screens/device_list.dart';
import 'screens/me_profile_screen.dart';
import 'screens/ask_ai_screen.dart';
import 'screens/binding_screens.dart';
import 'screens/recordings_feed.dart';
import 'screens/device_detail_offline.dart';
import 'screens/upgrade_screen.dart';
import 'viewmodels/me_profile_viewmodel.dart';
import 'viewmodels/device_list_viewmodel.dart';

// ============================================================
// MainFrame - 应用主框架 (侧边栏 + 主区)
// 入口点: MaterialApp.home = MainFrame
// 登录流程: LoginScreen 登录成功后 pushReplacement 到 MainFrame
// 退出流程: me_profile_screen 的退出登录 pushAndRemoveUntil 跳到 LoginScreen
// ============================================================
class MainFrame extends StatefulWidget {
  const MainFrame({super.key});

  @override
  MainFrameState createState() => MainFrameState();
}

class MainFrameState extends State<MainFrame> {
  int _currentIndex = 0; // 默认进入文件列表页面 (RecordingsFeedScreen, 真实接口数据)
  int _previousIndex = 0; // 上一个 tab 索引, 用于支持文件管理页"返回上一级"
  String _fileFilter = 'all'; // 'all', 'trash', 或某真实设备的 serialNumber
  bool _isFilesExpanded = true; // 文件 category 纵向展开状态 (默认展开)
  bool _isDevicesExpanded = true; // 设备 category 纵向展开状态 (默认展开)

  /// 侧边栏「设备」分组当前选中的设备 SN。
  ///
  /// 点击设备项时在主区就地渲染设备详情页 (Figma 669:5665 已连接 / 669:6303 离线),
  /// 而不是 push 新路由 — 与设计稿里设备项高亮 + 右侧显示详情的行为一致。
  String? _selectedDeviceSN;

  // 侧边栏固定宽度 (Figma LeftBar 669:860)
  static const double _sidebarWidth = 240;

  // 持有 MeProfileViewModel, 注入 MeProfileScreen + UpgradeScreen,
  // 保证 isPremiumUser 状态在侧边栏升级卡 / MeProfile 会员卡 / 升级页 三处一致
  late final MeProfileViewModel _profileViewModel;

  // 持有 DeviceListViewModel, 供左侧导航栏"设备"子菜单渲染真实设备列表
  late final DeviceListViewModel _deviceViewModel;

  @override
  void initState() {
    super.initState();
    _profileViewModel = MeProfileViewModel();
    _deviceViewModel = DeviceListViewModel();
    _deviceViewModel.refresh();
  }

  @override
  void dispose() {
    _profileViewModel.dispose();
    _deviceViewModel.dispose();
    super.dispose();
  }

  void setIndex(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  void setFileFilter(String filter) {
    setState(() {
      _fileFilter = filter;
    });
  }

  /// 切换文件 category 纵向展开/折叠
  void _toggleFilesExpanded() {
    setState(() {
      _isFilesExpanded = !_isFilesExpanded;
    });
  }

  /// 切换设备 category 纵向展开/折叠
  void _toggleDevicesExpanded() {
    setState(() {
      _isDevicesExpanded = !_isDevicesExpanded;
    });
  }

  /// 上一个 tab 索引 (暴露给子页面, 用于显示"返回"按钮)
  int get previousIndex => _previousIndex;

  /// 打开升级订阅页面 (push 全屏 UpgradeScreen)
  void _openUpgradeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UpgradeScreen(viewModel: _profileViewModel),
      ),
    );
  }

  List<Widget> _buildScreens() {
    // 左侧「文件」分组点击某真实设备时, _fileFilter 为该设备的 serialNumber;
    // 点击「全部」时为 'all', 点击「回收站」时为 'trash'。
    final String? filesDeviceSN =
        (_fileFilter == 'all' || _fileFilter == 'trash') ? null : _fileFilter;
    final String? filesDeviceName = filesDeviceSN == null
        ? null
        : _deviceViewModel.devices
            .where((d) => d.serialNumber == filesDeviceSN)
            .map((d) => d.name)
            .firstOrNull;
    return [
      // Index 0: 文件管理 (真实接口数据) 或 回收站 (按 _fileFilter 分流)
      _fileFilter == 'trash'
          ? const RecycleBinScreen()
          : RecordingsFeedScreen(
              key: ValueKey('recordings_feed_$_fileFilter'),
              deviceSN: filesDeviceSN,
              deviceName: filesDeviceName,
            ),
      AskAiScreen(onBack: () {
        setState(() {
          _currentIndex = 2; // Go back to RecordingsFeedScreen
        });
      }), // Index 1 (Ask AI)
      RecordingsFeedScreen(
        key: ValueKey('recordings_feed_home_${_fileFilter == 'trash' ? 'all' : _fileFilter}'),
        deviceSN: filesDeviceSN,
        deviceName: filesDeviceName,
      ), // Index 2 (设备文件管理 — 设备储存 / 主机储存列表)
      _buildDeviceDetailScreen(), // Index 3 (侧边栏选中设备的详情页)
      MeProfileScreen(viewModel: _profileViewModel), // Index 4 (我的 / 个人中心)
      const DeviceListScreen(), // Index 5 (我的设备 List)
      const DeviceSettingsScreen(), // Index 6 (Device Settings Screen)
    ];
  }

  /// Index 3: 侧边栏选中设备的详情页。
  ///
  /// 已连接 → [DeviceSettingsScreen] (Figma 669:5665, 完整信息 + 录音控件)
  /// 未连接 → [DeviceDetailOfflineScreen] (Figma 669:6303, 三行只读信息 + 解绑)
  Widget _buildDeviceDetailScreen() {
    final device = _selectedDevice;
    if (device == null) {
      // 尚未选中任何设备 (例如刚登录) → 占位空白, 侧边栏点击后立即替换
      return const SizedBox.shrink();
    }
    if (device.connected) {
      return DeviceSettingsScreen(key: ValueKey('device_settings_${device.id}'));
    }
    return DeviceDetailOfflineScreen(
      key: ValueKey('device_offline_${device.id}'),
      device: device,
    );
  }

  /// 当前选中的设备条目 (按 SN 在列表里查找)。
  DeviceItem? get _selectedDevice {
    final sn = _selectedDeviceSN;
    if (sn == null) return null;
    for (final d in _deviceViewModel.devices) {
      if (d.serialNumber == sn) return d;
    }
    return null;
  }

  // ── 侧边栏配色 (Figma 669:860) ────────────────────────────
  static const Color _navBg = Color(0xFFF2F2F2);
  static const Color _navBorder = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const Color _navText = Color(0xFF333333);
  static const Color _navActiveBg = Color(0xFFE9E9E9);
  static const Color _navActiveText = Color(0xFF39D03D);

  /// 分组标题 (Figma Header #727:8334 / #669:5713)
  ///
  /// 外层 40 高 + 水平 4 内边距, 内层水平 12 内边距, space-between:
  ///   左: caret 16×16 + 4px + 12px 标签 (点击切换展开/折叠)
  ///   右: 可选 24×24 操作图标 (「设备」分组的添加设备按钮, 独立点击目标)
  Widget _buildSectionHeader({
    required String label,
    required bool isExpanded,
    required VoidCallback onToggle,
    Widget? trailing,
  }) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            // caret + 标签: 独立点击目标, 只负责展开/折叠
            Expanded(
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.only(left: 12),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // caret: 展开向下, 折叠向右 (原图为向下箭头, 旋转 -90°)
                      AnimatedRotation(
                        turns: isExpanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: SvgPicture.asset(
                          'assets/images/ic_caret.svg',
                          width: 16,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _navText,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }

  /// 「设备」分组标题右侧的添加设备按钮 (Figma ic_add #669:5716)。
  ///
  /// 24×24, #E9E9E9 底 + 2px 圆角 + #333333 十字。点击进入添加设备页
  /// ([AddDeviceSearchPage]) — 与「我的设备」列表页的 ＋ 菜单同一目的地。
  Widget _buildAddDeviceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAddDevice,
        borderRadius: BorderRadius.circular(2),
        child: Tooltip(
          message: '添加新设备',
          child: SvgPicture.asset(
            'assets/images/ic_add.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }

  /// 打开添加设备页, 返回后刷新侧边栏设备列表。
  ///
  /// 绑定成功时 [AddDeviceSearchPage] 会 popUntil 到根路由, 这里的 await
  /// 随之结束; 用户按返回取消也会走到同一分支 — 两种情况都重新拉一次列表,
  /// 保证新绑定的设备立刻出现在「设备」分组里。
  Future<void> _openAddDevice() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDeviceSearchPage()),
    );
    if (!mounted) return;
    await _deviceViewModel.refresh();
  }

  /// 导航项 (Figma List #669:870 + Stack #669:871)
  /// 外层 40 高 + 水平 4 内边距; 内层 32 高, padding 4/16/4/32, 4px 圆角。
  /// 选中态: #E9E9E9 底 + 1px rgba(0,0,0,0.1) 描边 + 绿色 Semibold 文字。
  /// [trailingIconAsset] 设备项右侧的同步/断连状态图标 (24×24)。
  Widget _buildNavItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    String? trailingIconAsset,
  }) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 32,
            padding: const EdgeInsets.only(left: 32, right: 16, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: isActive ? _navActiveBg : Colors.transparent,
              border: isActive ? Border.all(color: _navBorder, width: 1) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? _navActiveText : _navText,
                      height: 20 / 14,
                    ),
                  ),
                ),
                if (trailingIconAsset != null) ...[
                  const SizedBox(width: 8),
                  SvgPicture.asset(trailingIconAsset, width: 24, height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 设备导航项: 复用 _buildNavItem, 右侧按连接状态显示同步/断连图标
  /// (Figma ic_auto sync #669:899 / ic_disconnect #669:905)
  Widget _buildDeviceNavItem({
    required String label,
    required bool isConnected,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return _buildNavItem(
      label: label,
      isActive: isActive,
      onTap: onTap,
      trailingIconAsset: isConnected
          ? 'assets/images/ic_auto_sync.svg'
          : 'assets/images/ic_disconnect.svg',
    );
  }

  /// 底部套餐卡 (Figma #669:921)
  /// 规格: 208px 宽, 14px "TALIX 基础版" + 12px "剩余220 / 800 分钟" #999999,
  ///       64×32 绿色 "升级" 按钮 (4px 圆角),
  ///       2px 进度条 #D9D9D9 底 + #39D03D 填充
  /// 联动: 升级成功后 (isPremiumUser=true) 切换为专业版样式, 进度条满格
  Widget _buildUpgradeCard() {
    return ListenableBuilder(
      listenable: _profileViewModel,
      builder: (context, _) {
        final bool isPro = _profileViewModel.isPremiumUser;
        // 基础版 220/800 分钟; Pro 版无限量 → 进度条满格
        const int usedMinutes = 220;
        const int totalMinutes = 800;
        final double ratio = isPro ? 1.0 : usedMinutes / totalMinutes;

        return SizedBox(
          width: 208,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 套餐名 + 剩余分钟 (左) ⟷ 绿色升级按钮 (右)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPro ? 'TALIX 专业版' : 'TALIX 基础版',
                          style: const TextStyle(
                            fontFamily: 'PingFang SC',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: _navText,
                            height: 1.0,
                            letterSpacing: 0.0046 * 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPro ? '无限次极速转写' : '剩余$usedMinutes / $totalMinutes 分钟',
                          style: const TextStyle(
                            fontFamily: 'PingFang SC',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF999999),
                            height: 1.0,
                            letterSpacing: 0.0054 * 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 64×32 绿色"升级"按钮 (Figma btn_send #669:926)
                  InkWell(
                    onTap: _openUpgradeScreen,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 64,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _navActiveText,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '升级',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 2px 进度条: #D9D9D9 底 + #39D03D 填充 (Figma #669:928)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 2,
                  color: const Color(0xFFD9D9D9),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: Container(color: _navActiveText),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 750;
        
        if (isWide) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: Row(
              children: [
                // Left Navigation Sidebar (matches Figma design node 1218:4288)
                // 使用 AnimatedContainer 平滑过渡展开/折叠宽度
                Container(
                  width: _sidebarWidth,
                  // Figma LeftBar #669:860: #F2F2F2 底 + 右侧 1px rgba(0,0,0,0.1) 分割线
                  decoration: const BoxDecoration(
                    color: _navBg,
                    border: Border(
                      right: BorderSide(color: _navBorder, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 顶部内边距 16 (Figma LeftBar padding)
                      const SizedBox(height: 16),

                      // ── 文件分组 (Figma Section #727:8331) ────────
                      // 标题与列表项同属一列, 无额外间距 (标题本身即 40 高 List 行)
                      _buildSectionHeader(
                        label: '文件',
                        isExpanded: _isFilesExpanded,
                        onToggle: _toggleFilesExpanded,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _isFilesExpanded
                            ? ListenableBuilder(
                                listenable: _deviceViewModel,
                                builder: (context, _) {
                                  final devices = _deviceViewModel.devices;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // 全部文件 (不过滤设备)
                                      _buildNavItem(
                                        label: '全部',
                                        isActive: _currentIndex == 0 &&
                                            _fileFilter == 'all',
                                        onTap: () {
                                          setState(() {
                                            _currentIndex = 0;
                                            _fileFilter = 'all';
                                          });
                                        },
                                      ),
                                      // 真实设备 (来自 /sl/app/recording-device/list)
                                      // 点击按 deviceSN 过滤文件列表
                                      ...devices.map((dev) {
                                        return _buildDeviceNavItem(
                                          label: dev.name,
                                          isConnected: dev.connected,
                                          isActive: _currentIndex == 0 &&
                                              _fileFilter ==
                                                  dev.serialNumber,
                                          onTap: () {
                                            setState(() {
                                              _currentIndex = 0;
                                              _fileFilter = dev.serialNumber;
                                            });
                                          },
                                        );
                                      }),
                                      if (_deviceViewModel.loading)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Center(
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (!_deviceViewModel.loading &&
                                          devices.isEmpty)
                                        _buildNavItem(
                                          label: '暂无设备文件',
                                          isActive: false,
                                          onTap: () {},
                                        ),
                                    ],
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 16),

                      // ── 设备分组 (Figma Section #669:5705) ────────
                      // 标题右侧带添加设备按钮 (ic_add #669:5716)
                      _buildSectionHeader(
                        label: '设备',
                        isExpanded: _isDevicesExpanded,
                        onToggle: _toggleDevicesExpanded,
                        trailing: _buildAddDeviceButton(),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _isDevicesExpanded
                            ? ListenableBuilder(
                                listenable: _deviceViewModel,
                                builder: (context, _) {
                                  if (_deviceViewModel.loading) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final devices = _deviceViewModel.devices;
                                  if (devices.isEmpty) {
                                    return _buildDeviceNavItem(
                                      label: '暂无设备',
                                      isConnected: false,
                                      isActive: false,
                                      onTap: () {},
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: devices.map((dev) {
                                      return _buildDeviceNavItem(
                                        label: dev.name,
                                        isConnected: dev.connected,
                                        isActive: _currentIndex == 3 &&
                                            _selectedDeviceSN ==
                                                dev.serialNumber,
                                        onTap: () {
                                          setState(() {
                                            _previousIndex = _currentIndex;
                                            _currentIndex = 3;
                                            _selectedDeviceSN =
                                                dev.serialNumber;
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 12),

                      // ── 独立导航项 (Figma #669:909 / 913 / 917) ───
                      _buildNavItem(
                        label: 'Ask AI',
                        isActive: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _buildNavItem(
                        label: '回收站',
                        isActive: _currentIndex == 0 && _fileFilter == 'trash',
                        onTap: () {
                          setState(() {
                            _currentIndex = 0;
                            _fileFilter = 'trash';
                          });
                        },
                      ),
                      _buildNavItem(
                        label: '我的',
                        isActive: _currentIndex == 4,
                        onTap: () => setState(() => _currentIndex = 4),
                      ),

                      const Spacer(),

                      // ── 底部套餐卡 (Figma #669:921), 底部留 32 ────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: _buildUpgradeCard(),
                      ),
                    ],
                  ),
                ),
                // Main Panel Area
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8F9FA),
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _buildScreens(),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile Portrait Layout
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex > 4 ? 5 : _currentIndex,
              children: _buildScreens(),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex == 0
                  ? 0
                  : _currentIndex == 1
                      ? 1
                      : _currentIndex == 4
                          ? 3
                          : 2, // Map index 2, 3, 5 to Bottom Tab 2 ('主页')
              selectedItemColor: const Color(0xFF10B981),
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              onTap: (index) {
                setState(() {
                  if (index == 0) {
                    _currentIndex = 0;
                    _fileFilter = 'all'; // Default to all files on tapping files tab
                  } else if (index == 1) {
                    _currentIndex = 1;
                  } else if (index == 2) {
                    _currentIndex = 5; // Go to device list
                  } else if (index == 3) {
                    _currentIndex = 4; // Go to profile
                  }
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_open_rounded),
                  label: '文件',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_outlined),
                  label: 'Ask AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: '主页',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: '我的',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
