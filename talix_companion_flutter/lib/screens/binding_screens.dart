import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../viewmodels/device_model.dart';
import '../viewmodels/binding_viewmodel.dart';
import '../widgets/common/common.dart';
import 'auth/auth_card_scaffolding.dart';
import 'auth/auth_widgets.dart';

/// 01 绑定设备初始提示 (Legacy - 保留, 实际入口由 AddDeviceSearchPage 取代)
class BindingStartScreen extends StatelessWidget {
  const BindingStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TALIX',
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 28),
            onSelected: (val) {
              if (val == 'scan') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanQRPage()));
              } else if (val == 'search') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceSearchPage()));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.bluetooth, size: 18),
                    SizedBox(width: 8),
                    Text('添加设备', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 18),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Concentric pulse animation placeholder
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.widgets_outlined, size: 64, color: Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Add devices to enable smart living',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TalixButton(
                label: 'Add',
                icon: Icons.add,
                width: 200,
                height: 48,
                fontWeight: FontWeight.bold,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceSearchPage()));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// 02 扫码绑定设备 (Legacy - 保留, 暂不在本次更新范围)
class ScanQRPage extends StatefulWidget {
  const ScanQRPage({super.key});

  @override
  State<ScanQRPage> createState() => _ScanQRPageState();
}

class _ScanQRPageState extends State<ScanQRPage> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('扫码绑定设备', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    // 模拟扫码成功，直接进入添加设备搜索页
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AddDeviceSearchPage()));
                  },
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54, width: 2, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0, left: 0,
                          child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF10B981), width: 4), left: BorderSide(color: Color(0xFF10B981), width: 4)))),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF10B981), width: 4), right: BorderSide(color: Color(0xFF10B981), width: 4)))),
                        ),
                        Positioned(
                          bottom: 0, left: 0,
                          child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF10B981), width: 4), left: BorderSide(color: Color(0xFF10B981), width: 4)))),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF10B981), width: 4), right: BorderSide(color: Color(0xFF10B981), width: 4)))),
                        ),
                        AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, child) {
                            return Positioned(
                              top: 220 * _laserController.value,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '请对准产品包装盒或说明书上的二维码进行扫描',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================
// 05 添加设备搜索页 (Figma 669:5122 / 669:5160 / 669:5196)
//
// 设计规范 (复用 AuthCardScaffolding):
//   背景 #F2F2F2 + 三个装饰光晕, 居中 440×600 白卡 (24px 圆角)
//   品牌区 (Talix logo + 标语) → gap 40 → 标题 24px #333333
//   → gap 40 → 状态内容 → gap 40 → 绿色主按钮 (48 高, 4px 圆角)
//
// 3 个状态 (由 BindingViewModel.state 决定):
//   - searching → 脉冲同心圆 + 蓝牙图标 + "正在搜索附近设备" (无按钮)
//   - notFound  → 同心圆 + 感叹号图标 + "未找到附近设备" + "重新扫描" 按钮
//   - found     → 设备实拍图 80×152 + 设备名/序列号 + "连接" 按钮
//
// 同心圆规格 (Figma 669:5135):
//   外圈 120×120: rgba(57,208,61,0.05) 填充 + 1px #39D03D 虚线描边 (4,4)
//   中圈 100×100: rgba(57,208,61,0.1) 填充
//   圆心  72×72:  #39D03D 填充 + shadow 0 4 8 rgba(57,208,61,0.2) + 32px 白色图标
// ============================================================
class AddDeviceSearchPage extends StatefulWidget {
  const AddDeviceSearchPage({super.key});

  @override
  State<AddDeviceSearchPage> createState() => _AddDeviceSearchPageState();
}

class _AddDeviceSearchPageState extends State<AddDeviceSearchPage>
    with SingleTickerProviderStateMixin {
  late final BindingViewModel _bindingViewModel;

  /// 搜索状态下同心圆的呼吸脉冲动画
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bindingViewModel = BindingViewModel();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    // debug 模式下 2 秒后自动标记 found, 模拟快速找到设备
    _bindingViewModel.simulateScanInDebug();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bindingViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _bindingViewModel,
      builder: (context, _) => AuthCardScaffolding(
        content: _buildContent(context),
        overlay: [
          // 返回按钮 (卡片外, 页面左上角; y 避让 48 高标题栏)
          Positioned(
            left: 24,
            top: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: Color(0xFF333333),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // 调试菜单 (仅 debug 模式, 用于切换页面状态 / 触发模态)
          if (kDebugMode)
            Positioned(
              right: 24,
              top: 16,
              child: _DebugMenu(viewModel: _bindingViewModel),
            ),
        ],
      ),
    );
  }

  /// 卡片内容: 标题 → gap 40 → 状态内容 → gap 40 → 主按钮
  Widget _buildContent(BuildContext context) {
    final state = _bindingViewModel.state;
    final isFound = state == AddDeviceState.found;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题: found → "发现附近设备", 其余 → "添加设备"
        Center(child: AuthTitle(isFound ? '发现附近设备' : '添加设备')),
        const SizedBox(height: 40),
        // 状态内容
        isFound ? _buildFoundContent() : _buildScanContent(state),
        // 主按钮: searching 状态无按钮 (Figma 669:5144 为空 frame)
        if (state != AddDeviceState.searching) ...[
          const SizedBox(height: 40),
          _buildPrimaryButton(context, isFound),
        ],
      ],
    );
  }

  /// 搜索中 / 未找到 状态: 同心圆 + 状态文字 (Figma 669:5134 / 669:5172)
  Widget _buildScanContent(AddDeviceState state) {
    final isNotFound = state == AddDeviceState.notFound;
    return Column(
      children: [
        _buildPulseCircle(isNotFound: isNotFound),
        const SizedBox(height: 24),
        // 文字区 gap 12
        Column(
          children: [
            Text(
              isNotFound ? '未找到附近设备' : '正在搜索附近设备',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '请确保您的设备蓝牙已打开，且手机与设备在 1 米的范围内',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 同心圆 (Figma 669:5135): 外圈虚线 120 + 中圈 100 + 绿色圆心 72
  /// 搜索状态下外两圈做呼吸缩放, 未找到状态静止。
  Widget _buildPulseCircle({required bool isNotFound}) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          // 未找到状态静止 (scale=1); 搜索状态 0.92↔1.0 呼吸
          final t = isNotFound ? 1.0 : 0.92 + 0.08 * _pulseController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // 外圈 120: rgba(57,208,61,0.05) + 1px 绿色虚线描边
              Transform.scale(
                scale: t,
                child: const CustomPaint(
                  size: Size(120, 120),
                  painter: _DashedCirclePainter(
                    color: Color(0xFF39D03D),
                    fillColor: Color(0x0D39D03D), // rgba(57,208,61,0.05)
                    strokeWidth: 1,
                    dashLength: 4,
                    gapLength: 4,
                  ),
                ),
              ),
              // 中圈 100: rgba(57,208,61,0.1)
              Transform.scale(
                scale: t,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0x1A39D03D), // rgba(57,208,61,0.1)
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 圆心 72: #39D03D + 阴影 + 32px 白色图标
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF39D03D),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3339D03D), // rgba(57,208,61,0.2)
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  isNotFound
                      ? 'assets/images/icon_error.svg'
                      : 'assets/images/icon_bluetooth.svg',
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 发现状态: 设备实拍图 + 设备名/序列号 (Figma 669:5208)
  Widget _buildFoundContent() {
    return Column(
      children: [
        // 设备实拍图 80×152
        Image.asset(
          'assets/images/device_talix_note.png',
          width: 80,
          height: 152,
          fit: BoxFit.cover,
        ),
        const SizedBox(height: 24),
        // 设备名 + 序列号 gap 4
        Column(
          children: [
            Text(
              _bindingViewModel.deviceName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '序列号：${_bindingViewModel.deviceSerial}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 主按钮: 绿色 48 高 4px 圆角
  /// found → "连接" (触发绑定); notFound → "重新扫描" (重新搜索)
  Widget _buildPrimaryButton(BuildContext context, bool isFound) {
    final deviceModel = Provider.of<DeviceModel>(context, listen: false);
    return AuthPrimaryButton(
      label: isFound ? '连接' : '重新扫描',
      onPressed: () {
        if (isFound) {
          _connect(context, deviceModel);
        } else {
          _bindingViewModel.retryScan();
        }
      },
    );
  }

  /// 点击"连接": 调真实服务端绑定接口 (POST /sl/app/recording-device/add)
  /// 成功 → 翻转 isBound + 存 deviceToken, 弹出绑定成功模态
  /// 失败 → 弹 SnackBar 提示错误 (服务端未就绪 / SN 已存在等)
  Future<void> _connect(BuildContext context, DeviceModel deviceModel) async {
    final sn = _bindingViewModel.deviceSerial;
    final name = _bindingViewModel.deviceName;
    try {
      await deviceModel.bindDevice(deviceSN: sn, deviceName: name);
      if (!context.mounted) return;
      showBindSuccessModal(
        context,
        deviceName: name,
        onComplete: () {
          if (!context.mounted) return;
          // 关闭添加设备页, 回到根路由
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('绑定失败:$e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

/// 虚线圆形 CustomPainter
/// Figma 外圈: 1px #39D03D 虚线描边 (4,4) + rgba(57,208,61,0.05) 填充
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({
    required this.color,
    required this.fillColor,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final Color fillColor;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 填充
    canvas.drawCircle(center, radius, Paint()..color = fillColor);

    // 虚线描边
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const totalAngle = 2 * math.pi;
    final circumference = totalAngle * radius;
    final dashAngle = (dashLength / circumference) * totalAngle;
    final gapAngle = (gapLength / circumference) * totalAngle;
    final step = dashAngle + gapAngle;

    for (double angle = 0; angle < totalAngle; angle += step) {
      final endAngle = math.min(angle + dashAngle, totalAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle - math.pi / 2,
        endAngle - angle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth;
}

// ============================================================
// 蓝牙异常弹窗 (Figma 1218:3813)
//
// 设计规范:
//   背景遮罩 rgba(0,0,0,0.5)
//   卡片 480x260 白色 8px 圆角
//   标题 18px Bold #18181B + 右上 16x16 X 关闭
//   描述 14px #262626 line-height 20px
//   底部按钮 (右对齐, gap 12):
//     - 取消: 1px #D1D5DB 描边, 6px 圆角, padding 10 20
//     - 去开启: #18181B 填充, 6px 圆角, padding 10 20
// ============================================================
Future<void> showBluetoothErrorModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x80000000),
    builder: (dialogContext) => Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '蓝牙异常',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
                _CloseIcon(onTap: () => Navigator.pop(dialogContext)),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '蓝牙已关闭或不可用。请在系统设置中打开蓝牙。',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 20 / 14,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ModalButton(
                  label: '取消',
                  outlined: true,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(width: 12),
                _ModalButton(
                  label: '去开启',
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// 设备绑定成功弹窗 (Figma 1218:3869)
//
// 设计规范:
//   背景遮罩 rgba(0,0,0,0.5)
//   卡片 480x260 白色 8px 圆角
//   标题 18px Bold #18181B + 右上 16x16 X 关闭
//   描述 14px #262626 (设备名)
//   底部按钮 (右对齐): 开始使用 119 宽 #18181B 填充 6px 圆角
// ============================================================
Future<void> showBindSuccessModal(
  BuildContext context, {
  required String deviceName,
  required VoidCallback onComplete,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x80000000),
    builder: (dialogContext) => Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设备绑定成功',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
                _CloseIcon(
                  onTap: () {
                    Navigator.pop(dialogContext);
                    onComplete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              deviceName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 20 / 14,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ModalButton(
                  label: '开始使用',
                  width: 119,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onComplete();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================
// 内部组件: 模态按钮 (Figma 1218:3822/3824/3880)
// 高度 40, padding 10 20 (固定宽度模式下无水平 padding), 6px 圆角
// outlined=true: 1px #D1D5DB 描边 + 黑色文字
// outlined=false: #18181B 填充 + 白色文字
// ============================================================
class _ModalButton extends StatelessWidget {
  final String label;
  final bool outlined;
  final double? width;
  final VoidCallback onPressed;

  const _ModalButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      height: 40,
      width: width,
      padding: width == null
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
          : null,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(6),
        border: outlined ? Border.all(color: const Color(0xFFD1D5DB)) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: outlined ? const Color(0xFF18181B) : Colors.white,
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: btn,
      ),
    );
  }
}

/// 模态右上角关闭 X (Figma 1218:3818/3874, 16x16 黑色)
class _CloseIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 16, color: Colors.black),
        ),
      ),
    );
  }
}

/// 调试菜单 (仅 debug 模式下显示, 用于测试 3 种页面状态 + 模态)
class _DebugMenu extends StatelessWidget {
  final BindingViewModel viewModel;
  const _DebugMenu({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz,
        size: 20,
        color: Color(0xFF1A1A1A),
      ),
      tooltip: 'Debug Menu',
      onSelected: (value) {
        switch (value) {
          case 'notFound':
            viewModel.markDeviceNotFound();
            break;
          case 'bluetoothError':
            showBluetoothErrorModal(context);
            break;
          case 'reset':
            viewModel.reset();
            viewModel.simulateScanInDebug();
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'notFound',
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16),
              SizedBox(width: 8),
              Text('Simulate Not Found (1218:4039)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'bluetoothError',
          child: Row(
            children: [
              Icon(Icons.bluetooth_disabled, size: 16),
              SizedBox(width: 8),
              Text('Show BT Error Modal (1218:3813)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 16),
              SizedBox(width: 8),
              Text('Reset to Searching'),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 11-13 高危数据解绑提示工具类 (保留)
// ============================================================
class UnbindingHandler {
  static void triggerUnbindFlow(
    BuildContext context,
    bool hasUnsynced,
    Future<void> Function() onConfirm,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('解绑并清除数据', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              children: [
                const TextSpan(text: '解绑后将清除设备上的所有数据，该设备可重新绑定其他账号。\n\n'),
                if (hasUnsynced)
                  const TextSpan(
                    text: '发现Talix AI Note中还有未传输的录音。你确定要清除它们并解除绑定吗？',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TalixButton(
                    label: '取消',
                    variant: TalixButtonVariant.neutralOutline,
                    size: TalixButtonSize.small,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TalixButton(
                    label: '解除绑定',
                    variant: TalixButtonVariant.danger,
                    size: TalixButtonSize.small,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    onPressed: () async {
                      Navigator.pop(context); // close confirm dialog
                      try {
                        await onConfirm();
                        _showUnbindSuccess(context);
                      } catch (e) {
                        messenger?.showSnackBar(
                          SnackBar(
                            content: Text('解绑失败：$e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                )
              ],
            )
          ],
        );
      },
    );
  }

  static void _showUnbindSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.check_circle, size: 48, color: AppColors.primary),
          title: const Text('解除绑定成功', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          content: const Text('所有设置已还原为初始值，设备已解除绑定。', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          actions: [
            TalixButton(
              label: '知道了',
              variant: TalixButtonVariant.dark,
              height: 44,
              borderRadius: 12,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }
}
