import 'package:flutter/material.dart';
import '../viewmodels/me_profile_viewmodel.dart';
import '../widgets/common/common.dart';
import '../widgets/file_list_widgets.dart' show FigmaTokens, showFileListToast;

// ============================================================
// UpgradeScreen - 全屏升级订阅页面
// 入口:
//   - MainFrame 侧边栏底部 _buildUpgradeCard 的"升级"胶囊按钮
//   - MeProfileScreen "升级至专业版" 设置行
//   - MeProfileScreen 会员卡右侧 "免费试用升级版" 按钮
// 数据: 共享 MeProfileViewModel 实例,保证 isPremiumUser 状态在
//       MainFrame 升级卡 / MeProfile 会员卡 / 当前页 三处一致
// 返回: Navigator.pop (无论用户取消还是购买成功,均返回 push 此页的页面)
// 对齐 Figma design node 1218:10594 (升级订阅页面)
// ============================================================
class UpgradeScreen extends StatefulWidget {
  final MeProfileViewModel viewModel;
  const UpgradeScreen({super.key, required this.viewModel});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  void _showToast(String message) {
    showFileListToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  // ============================================================
  // SCREEN: 升级订阅 (Upgrade) - Figma 1218:10594
  //   - 标题 "升级解锁更多AI能力" (20px #262626)
  //   - 两个并排套餐卡 314x152: 专业版 (8px 圆角 #DCDCDC 边框) / 卓越版 (16px 圆角 #919191 边框)
  //   - 方案对比表 640x384: 权益 + 专业版 + 卓越版
  //   - 两个付费方式卡 314x50: 年付 (黑边框) / 月付 (灰边框)
  //   - 购买按钮 640x48 (黑底白字)
  // ============================================================
  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('升级订阅', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // 标题 20px
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '升级解锁更多AI能力',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: FigmaTokens.primary,
                height: 1.3,
              ),
            ),
          ),
          // 两个并排套餐卡 (314x152 each, 16px gap)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildPlanCard(
                    key: 'premium',
                    title: '专业版',
                    price: '\$18.99 /月',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlanCard(
                    key: 'ultimate',
                    title: '卓越版',
                    price: '\$29.99 /月',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 方案对比 标签 (右上对齐, 16px)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '方案对比',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: FigmaTokens.primary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // 对比表
          _buildComparisonTable(),
          const SizedBox(height: 24),
          // 付费方式
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildBillingCycleOption(
                    key: 'yearly',
                    label: '年付',
                    price: '\$299.99 /月',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBillingCycleOption(
                    key: 'monthly',
                    label: '月付',
                    price: '\$29.99 /月',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 购买按钮
          _buildPurchaseButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 套餐卡 314x152
  // Figma 1218:10658 (专业版 8px 圆角 #DCDCDC) / 1218:10666 (卓越版 16px 圆角 #919191)
  // 选中态: 2px 黑色边框
  Widget _buildPlanCard({
    required String key,
    required String title,
    required String price,
  }) {
    final vm = widget.viewModel;
    final bool isSelected = vm.selectedPlan == key;
    final double radius = key == 'premium' ? 8 : 16;
    final Color borderColor = isSelected
        ? const Color(0xFF000000)
        : (key == 'premium' ? const Color(0xFFDCDCDC) : const Color(0xFF919191));
    final double borderWidth = isSelected ? 2 : 1;

    return GestureDetector(
      onTap: () => vm.selectedPlan = key,
      child: Container(
        height: 152,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 第一行: 价格 (左) + 标题 (右)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
              ],
            ),
            // 3 个 bullet points
            const PlanBulletRow(text: '本地存储永久免费'),
            const PlanBulletRow(text: '转文本免费1200分钟/月'),
            const PlanBulletRow(text: '100+专业模版+高阶大模型'),
          ],
        ),
      ),
    );
  }

  // 方案对比表 640x384
  // Figma 1218:10674 - 3 列: 权益(99) / 专业版(57) / 卓越版(57)
  // 7 个权益项目, 14px Inter 行高 48px
  Widget _buildComparisonTable() {
    return const SizedBox(
      height: 384,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左列: 权益 (99 wide)
          SizedBox(
            width: 99,
            child: BenefitColumn(),
          ),
          // 中间 spacer (用 Expanded 替代 Spacer, 更稳定)
          Expanded(child: SizedBox()),
          // 右列: 专业版 + 卓越版 (右对齐, 16px gap)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 57, child: PlanCheckColumn(planLabel: '专业版')),
              SizedBox(width: 16),
              SizedBox(width: 57, child: PlanCheckColumn(planLabel: '卓越版')),
            ],
          ),
        ],
      ),
    );
  }

  // 付费方式卡 314x50
  // Figma 1218:10693 (年付 黑边框) / 1218:10696 (月付 灰边框)
  Widget _buildBillingCycleOption({
    required String key,
    required String label,
    required String price,
  }) {
    final vm = widget.viewModel;
    final bool isSelected = vm.selectedBillingCycle == key;
    final Color borderColor = isSelected
        ? const Color(0xFF000000)
        : const Color(0xFFDCDCDC);
    return GestureDetector(
      onTap: () => vm.selectedBillingCycle = key,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
                height: 13.5 / 16,
                letterSpacing: 0.0104,
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF000000),
                height: 13.5 / 14,
                letterSpacing: 0.0119,
                textBaseline: TextBaseline.alphabetic,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  // 购买按钮 640x48
  // Figma 1218:10699 黑底 12px 圆角 "购买" 14px Semi Bold #FFF
  Widget _buildPurchaseButton() {
    return TalixButton(
      label: '购买',
      variant: TalixButtonVariant.dark,
      height: 48,
      borderRadius: 12,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      backgroundColor: FigmaTokens.primary,
      onPressed: () {
        final vm = widget.viewModel;
        final plan = vm.selectedPlan;
        final cycle = vm.selectedBillingCycle;
        final planLabel = plan == 'premium' ? '专业版' : '卓越版';
        final cycleLabel = cycle == 'yearly' ? '年付' : '月付';
        _showToast('💳 正在加载安全收银台，拟购买 【$planLabel · $cycleLabel】 套餐...');
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          vm.isPremiumUser = true;
          _showToast('🎉 订阅成功！尊贵的 Pro 专业版权益已全面接入您的账号。');
          Navigator.pop(context);
        });
      },
    );
  }
}

// ============================================================
// 公共 helper widgets (从 me_profile_screen.dart 迁出并重命名)
// ============================================================

// ============================================================
// 升级订阅 - 权益列 (Figma 1218:10675)
//   - 99 wide, 8 行 14px Inter 行高 48px
//   - 第 1 行加粗 700 (权益), 后续 400
// ============================================================
class BenefitColumn extends StatelessWidget {
  const BenefitColumn({super.key});

  static const _rowStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF000000),
    height: 48 / 14,
    letterSpacing: 0.0046,
  );
  static const _rowBoldStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Color(0xFF000000),
    height: 48 / 14,
    letterSpacing: 0.0046,
  );

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('权益', style: _rowBoldStyle),
        Text('每月转写分钟数', style: _rowStyle),
        Text('多模态输入', style: _rowStyle),
        Text('多维总结', style: _rowStyle),
        Text('Ask AI', style: _rowStyle),
        Text('自动生成', style: _rowStyle),
        Text('专业模版', style: _rowStyle),
        Text('可视化思维导图', style: _rowStyle),
      ],
    );
  }
}

// ============================================================
// 升级订阅 - 方案列 (Figma 1218:10676 / 10684)
//   - 57 wide, 8 行 (1 加粗标题 + 5 ✓ + 1 全量模版 + 1 ✓)
// ============================================================
class PlanCheckColumn extends StatelessWidget {
  final String planLabel;
  const PlanCheckColumn({super.key, required this.planLabel});

  static const _rowStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF000000),
    height: 48 / 14,
    letterSpacing: 0.0046,
  );
  static const _rowBoldStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Color(0xFF000000),
    height: 48 / 14,
    letterSpacing: 0.0046,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(planLabel, style: _rowBoldStyle, textAlign: TextAlign.center),
        const ComparisonCheckCell(),
        const ComparisonCheckCell(),
        const ComparisonCheckCell(),
        const ComparisonCheckCell(),
        const ComparisonCheckCell(),
        const Text('全量模版', style: _rowStyle, textAlign: TextAlign.center),
        const ComparisonCheckCell(),
      ],
    );
  }
}

// ============================================================
// 升级订阅 - 套餐卡 bullet 行 (Figma 1218:10660 价格卡内 3 项)
//   - 13.53x8 SVG ✓ + 11px Inter 文字 #404040 行高 24px
// ============================================================
class PlanBulletRow extends StatelessWidget {
  final String text;
  const PlanBulletRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 12,
            color: Color(0xFF000000),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF404040),
              fontWeight: FontWeight.w400,
              height: 24 / 11,
              letterSpacing: 0.0059,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 升级订阅 - 方案对比表 ✓ 单元格 (Figma 1218:10678-10683)
//   - 10x8 SVG ✓ 居中显示
// ============================================================
class ComparisonCheckCell extends StatelessWidget {
  const ComparisonCheckCell({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Center(
        child: SizedBox(
          width: 10,
          height: 8,
          child: CustomPaint(
            painter: CheckMarkPainter(),
          ),
        ),
      ),
    );
  }
}

// ✓ 标记绘制 (Figma 1218:10678 模板: 10x8, 1px stroke #000)
class CheckMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
