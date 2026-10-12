import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Figma 规范开关。
///
/// 设计稿没有单独画开关组件, 这里按 iOS 标准尺寸 (51x31) 实现,
/// 把选中态颜色对齐 Figma 主色 [AppColors.primary], 替换掉旧代码里
/// 各处不一致的 `activeColor` (曾出现 #1E293B 和 #10B981 两种)。
///
/// 用 [AnimatedContainer] + [AnimatedAlign] 自绘, 而不是包装 Material
/// [Switch], 因为后者的 `activeTrackColor` 在不同 Flutter 版本上会叠加
/// 一层默认透明度, 拿不到精确的品牌色。
class TalixSwitch extends StatelessWidget {
  /// 当前开关状态。
  final bool value;

  /// 状态切换回调。传 null 视为禁用。
  final ValueChanged<bool>? onChanged;

  /// 打开时的轨道颜色。
  final Color activeColor;

  /// 轨道宽度。默认 iOS 标准 51; 设备信息页 (Figma 669:5776) 传 48。
  final double width;

  /// 轨道高度。默认 iOS 标准 31; 设备信息页传 24。
  final double height;

  const TalixSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = AppColors.primary,
    this.width = 51,
    this.height = 31,
  });

  /// Figma 设备信息页规格 (48×24 轨道 + 20×20 滑块)。
  const TalixSwitch.compact({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = AppColors.primary,
  })  : width = 48,
        height = 24;

  bool get _enabled => onChanged != null;

  /// 滑块直径 = 轨道高度 - 上下各 2px 内边距。
  double get _thumbSize => height - 4;

  @override
  Widget build(BuildContext context) {
    final trackColor = value
        ? (_enabled ? activeColor : AppColors.neutralFill)
        : AppColors.neutralFill;

    return Semantics(
      toggled: value,
      enabled: _enabled,
      child: GestureDetector(
        onTap: _enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: width,
          height: height,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox(
              width: _thumbSize,
              height: _thumbSize,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
