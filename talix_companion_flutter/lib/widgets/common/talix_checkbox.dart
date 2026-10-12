import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'talix_check_mark.dart';

/// 复选框形状。
enum TalixCheckboxShape {
  /// 圆形。Figma 分享列表用的样式 (20x20, r=24)。
  circle,

  /// 圆角方形。Figma 文件列表 / 协议勾选用的样式 (16x16, r=4)。
  square,
}

/// Figma 规范复选框。
///
/// 两种形态都来自设计稿:
/// - [TalixCheckboxShape.circle] — 20x20, 选中时 #39D03D 实心 + 白色对勾,
///   未选中时 1px #999999 描边 + 透明底。见「19 分享选择列表」。
/// - [TalixCheckboxShape.square] — 16x16 圆角 4, 用于协议勾选和文件多选。
///
/// 相比 Material [Checkbox] 的好处: 没有默认的 48x48 点击区外扩和水波纹溢出,
/// 尺寸严格等于设计稿, 放进 Row 里不会把行高顶高。
class TalixCheckbox extends StatelessWidget {
  /// 是否选中。
  final bool value;

  /// 状态切换回调。传 null 视为禁用。
  final ValueChanged<bool>? onChanged;

  /// 形状。
  final TalixCheckboxShape shape;

  /// 方框尺寸。默认按 [shape] 取设计稿值 (圆形 20, 方形 16)。
  final double? size;

  /// 选中时的填充色。
  final Color activeColor;

  const TalixCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.shape = TalixCheckboxShape.circle,
    this.size,
    this.activeColor = AppColors.primary,
  });

  bool get _enabled => onChanged != null;

  double get _size =>
      size ?? (shape == TalixCheckboxShape.circle ? 20 : 16);

  @override
  Widget build(BuildContext context) {
    final fill = value
        ? (_enabled ? activeColor : AppColors.neutralFill)
        : Colors.transparent;

    // 选中时不需要描边 (实心块), 未选中时用灰边勾出轮廓。
    final border = value
        ? null
        : Border.all(
            color: _enabled
                ? AppColors.borderUnselected
                : AppColors.neutralFill,
            width: 1,
          );

    return Semantics(
      checked: value,
      enabled: _enabled,
      child: GestureDetector(
        onTap: _enabled ? () => onChanged!(!value) : null,
        // opaque 让整个方框区域都可点, 而不只是对勾的像素。
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _size,
          height: _size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: border,
              shape: shape == TalixCheckboxShape.circle
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius: shape == TalixCheckboxShape.square
                  ? BorderRadius.circular(4)
                  : null,
            ),
            child: value
                ? Center(
                    // 对勾占方框的 65%, 与 Figma 的 13/20 接近。
                    child: TalixCheckMark(
                      color: AppColors.textOnPrimary,
                      width: _size * 0.65,
                      strokeWidth: 1.5,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
