import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

// ============================================================
// 设备信息页组件套件
//
// 对齐 Figma「Talix AI Device UI」(file DvVN6Ib1WkEfJBfmkU4oMR):
//   669:5665  设备详情 — 已连接 / 未录音
//   669:6574  设备详情 — 录音中 (状态栏)
//   669:5853  设备详情 — 录音忘关提醒下拉展开
//   669:6303  设备详情 — 设备离线 (精简信息 + 禁用录音按钮)
//
// 页面度量 (三张图一致):
//   内容区 800 宽居中, 卡片 1px #E0E0E0 描边 + 4px 圆角, 卡片间距 16
//   纯信息行 48 高 / 带副标题行 64 高, 水平内边距 16
// ============================================================

/// 设备页统一字号。Figma 全部为 Segoe UI, 字距 0.0046em ≈ 14×0.0046。
class DeviceInfoText {
  const DeviceInfoText._();

  static const String _family = 'Segoe UI';

  /// 页面主标题。24px — 「TALIX AI NOTE」
  static const TextStyle pageTitle = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 24 * 0.0027,
    color: AppColors.textPrimary,
  );

  /// 行标题。14px #333333 — 「设备名称」「电池电量」
  static const TextStyle rowLabel = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 14 * 0.0046,
    color: AppColors.textPrimary,
  );

  /// 行取值。14px #999999 — 「T-2025-7F2A」「80%」
  static const TextStyle rowValue = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 14 * 0.0046,
    color: AppColors.textSecondary,
  );

  /// 行副标题。12px #999999 — 「录音达到设定时长前进行提醒」
  static const TextStyle rowSubtitle = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 12 * 0.0054,
    color: AppColors.textSecondary,
  );

  /// 破坏性行标题。14px #EE3939 — 「解绑并重置」
  static const TextStyle rowDanger = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 14 * 0.0046,
    color: AppColors.dangerText,
  );

  /// 录音按钮文字。14px Semibold #FFFFFF
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 14 * 0.0046,
    color: AppColors.textOnPrimary,
  );
}

/// 设备信息卡容器 (Figma 669:5805 / 5750 / 5767 …)。
///
/// 白底 + 1px #E0E0E0 描边 + 4px 圆角。子行自行控制高度与内边距。
class DeviceInfoCard extends StatelessWidget {
  final List<Widget> children;

  const DeviceInfoCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// 信息行 (Figma 669:5806 「设备名称」/ 669:5767 「指示灯」)。
///
/// 无副标题 → 48 高; 有副标题 → 64 高 (标题 + 8px 间距 + 副标题)。
/// 右侧 [trailing] 由调用方组合 (取值文字 / 徽标 / 箭头 / 开关)。
class DeviceInfoRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 标题用危险色 (「解绑并重置」)。
  final bool isDanger;

  const DeviceInfoRow({
    super.key,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      height: subtitle == null ? 48 : 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: isDanger
                      ? DeviceInfoText.rowDanger
                      : DeviceInfoText.rowLabel,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: DeviceInfoText.rowSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: row,
      ),
    );
  }
}

/// 行右侧「取值 + 箭头」(Figma 669:5833 「3/64 GB ›」)。
///
/// Figma: 14px #999999 文字 + 2px 间距 + 16×16 箭头框。
class DeviceRowValue extends StatelessWidget {
  final String value;

  /// 是否显示右箭头 (可进入下级页 / 可展开下拉)。
  final bool showChevron;

  const DeviceRowValue({
    super.key,
    required this.value,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: DeviceInfoText.rowValue),
        if (showChevron) ...[
          const SizedBox(width: 2),
          const DeviceRowChevron(),
        ],
      ],
    );
  }
}

/// 16×16 右向箭头 (Figma 669:5756 → 内含 8.49×8.49 描边图标)。
///
/// 导出的 SVG 是下向 caret, 逆时针转 90° 得到右向。
class DeviceRowChevron extends StatelessWidget {
  const DeviceRowChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: RotatedBox(
          quarterTurns: 3,
          child: SvgPicture.asset(
            'assets/images/ic_chevron_right.svg',
            width: 10,
            height: 6,
          ),
        ),
      ),
    );
  }
}

/// 状态徽标 (Figma 669:5828 「充电中」/ 669:5849 「可升级」)。
///
/// padding 5/8, 24px 圆角, 14px 文字。
class DeviceStatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const DeviceStatusPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  /// 「充电中」— #E6F8ED 底 + #39D03D 字。
  const DeviceStatusPill.charging({super.key})
      : label = '充电中',
        background = AppColors.primarySurface,
        foreground = AppColors.primary;

  /// 「可升级」— #EBF2FF 底 + #3D7FF8 字。
  const DeviceStatusPill.updatable({super.key})
      : label = '可升级',
        background = AppColors.infoSurface,
        foreground = AppColors.infoText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: DeviceInfoText.rowValue.copyWith(color: foreground),
      ),
    );
  }
}

/// 下拉选项 (Figma 669:5993 「不限制 / 8小时 / 12小时 / 24小时」)。
class DeviceMenuOption<T> {
  final T value;
  final String label;

  const DeviceMenuOption({required this.value, required this.label});
}

/// 锚定下拉菜单 (Figma 669:5993 mune)。
///
/// 把 [anchorBuilder] 返回的控件作为锚点, 点击后在其下方浮出 312 宽的选项菜单
/// (白底 + 4px 圆角 + 双层阴影, 每项 48 高, 选中项右侧绿色对勾)。
/// 用 [OverlayPortal] 渲染, 菜单浮于页面之上, **不挤压卡片布局**。
///
/// 「录音模式」「录音忘关提醒」两行与「开始录音」按钮右侧 caret 共用本组件。
class DeviceAnchoredMenu<T> extends StatefulWidget {
  final List<DeviceMenuOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// 锚点构造器。[toggle] 用于展开/收起菜单。
  final Widget Function(BuildContext context, VoidCallback toggle) anchorBuilder;

  /// 菜单宽度。Figma 为 312。
  final double menuWidth;

  const DeviceAnchoredMenu({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.anchorBuilder,
    this.menuWidth = 312,
  });

  @override
  State<DeviceAnchoredMenu<T>> createState() => _DeviceAnchoredMenuState<T>();
}

class _DeviceAnchoredMenuState<T> extends State<DeviceAnchoredMenu<T>> {
  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return Stack(
            children: [
              // 点击菜单外区域收起
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _controller.hide,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                // 菜单右边缘与锚点右边缘对齐, 顶部贴在锚点下方 4px
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 4),
                child: _buildMenu(),
              ),
            ],
          );
        },
        child: widget.anchorBuilder(context, _controller.toggle),
      ),
    );
  }

  /// Figma 669:5993 mune: 312 宽, 4px 圆角, 项间距 4,
  /// 阴影 0 0 8 rgba(0,0,0,0.2) + 0 14 28 rgba(0,0,0,0.25)
  Widget _buildMenu() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: widget.menuWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < widget.options.length; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              _buildMenuItem(widget.options[i]),
            ],
          ],
        ),
      ),
    );
  }

  /// 单个选项: 48 高, 水平内边距 12, 选中时右侧 13×10 绿色对勾
  Widget _buildMenuItem(DeviceMenuOption<T> option) {
    final bool isSelected = option.value == widget.selected;
    return InkWell(
      onTap: () {
        _controller.hide();
        widget.onSelected(option.value);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(option.label, style: DeviceInfoText.rowLabel),
            ),
            if (isSelected)
              SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/ic_check_green.svg',
                    width: 13,
                    height: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 可展开下拉的信息行 (Figma 669:5853 「录音忘关提醒」展开态)。
///
/// 行本身与 [DeviceInfoRow] 一致, 右侧显示当前选中项 + 箭头;
/// 点击整行在行下方浮出 [DeviceAnchoredMenu]。
class DeviceSelectRow<T> extends StatelessWidget {
  final String label;
  final String? subtitle;
  final List<DeviceMenuOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const DeviceSelectRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  String get _selectedLabel => options
      .firstWhere((o) => o.value == selected, orElse: () => options.first)
      .label;

  @override
  Widget build(BuildContext context) {
    return DeviceAnchoredMenu<T>(
      options: options,
      selected: selected,
      onSelected: onSelected,
      anchorBuilder: (context, toggle) => DeviceInfoRow(
        label: label,
        subtitle: subtitle,
        onTap: toggle,
        trailing: DeviceRowValue(value: _selectedLabel, showChevron: true),
      ),
    );
  }
}
