import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'talix_check_mark.dart';

/// Figma 规范单选标记。
///
/// 设计稿里的单选不是 Material 那种同心圆 radio, 而是「选中项右侧显示一个
/// 裸的主色对勾, 未选中则什么都不显示」。见「17 选择列表」「21 选择倍速」:
/// 24x24 容器内一条 13x10 / 2px 的 #39D03D 折线, 没有外框。
///
/// 泛型 [T] 是选项值的类型, 用法对齐 Material [Radio]。
///
/// ```dart
/// TalixRadio<String>(
///   value: 'gpt-5.5',
///   groupValue: _model,
///   onChanged: (v) => setState(() => _model = v),
/// )
/// ```
class TalixRadio<T> extends StatelessWidget {
  /// 当前这一项代表的值。
  final T value;

  /// 整组当前选中的值。等于 [value] 时显示对勾。
  final T? groupValue;

  /// 选中回调。传 null 视为禁用。
  final ValueChanged<T>? onChanged;

  /// 点击热区尺寸。Figma 是 24x24。
  final double size;

  /// 对勾颜色。
  final Color activeColor;

  const TalixRadio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.size = 24,
    this.activeColor = AppColors.primary,
  });

  bool get _selected => value == groupValue;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: _selected,
      enabled: _enabled,
      child: GestureDetector(
        // 已选中时再点无意义, 但保持热区一致避免布局跳动。
        onTap: _enabled && !_selected ? () => onChanged!(value) : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: _selected
              ? Center(
                  child: TalixCheckMark(
                    color: _enabled ? activeColor : AppColors.neutralFill,
                    // Figma: 24 容器里放 13 宽的对勾。
                    width: size * 13 / 24,
                    strokeWidth: 2,
                  ),
                )
              // 未选中不画任何东西, 只占位保证行内对齐。
              : null,
        ),
      ),
    );
  }
}
