import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// 按钮视觉变体。
enum TalixButtonVariant {
  /// 主 CTA。#39D03D 填充 + 白字。Figma「分享链接」「使用此模型」
  primary,

  /// 次级操作。#CCCCCC 填充 + #333333 字。Figma「复制链接」「取消」
  secondary,

  /// 描边按钮。透明底 + 主色描边与文字。
  outline,

  /// 纯文字按钮。无填充无描边。
  text,

  /// 深色实心。#1A1A1A 填充 + 白字。登录/绑定流程的主操作。
  dark,

  /// 中性描边。灰描边 + 灰字。对话框「取消」。
  neutralOutline,

  /// 危险实心。红底白字。确认删除 / 确认解绑。
  danger,

  /// 危险描边。白底红描边红字。入口处的解绑、清除数据。
  dangerOutline,
}

/// 按钮尺寸。
enum TalixButtonSize {
  /// 56 高。Figma 底部主操作按钮的标准尺寸。
  large,

  /// 44 高。表单内、对话框中使用。
  medium,

  /// 36 高。列表行内的紧凑操作。
  small,
}

/// Figma 规范按钮。
///
/// 取自 Figma「Talix AI Device UI」底部操作按钮:
/// 354x56, cornerRadius 56 (全圆角胶囊), 16px/Medium 文字, 无阴影。
///
/// ```dart
/// TalixButton(
///   label: '分享链接',
///   onPressed: _share,
/// )
///
/// TalixButton(
///   label: '取消',
///   variant: TalixButtonVariant.secondary,
///   onPressed: () => Navigator.pop(context),
/// )
/// ```
class TalixButton extends StatelessWidget {
  /// 按钮文字。
  final String label;

  /// 点击回调。传 null 视为禁用。
  final VoidCallback? onPressed;

  /// 视觉变体。
  final TalixButtonVariant variant;

  /// 尺寸。
  final TalixButtonSize size;

  /// 文字左侧图标。
  final IconData? icon;

  /// 是否撑满父容器宽度。默认 true, 符合 Figma 底部按钮的用法。
  ///
  /// 设为 false 时宽度由内容决定 (适合列表行内的小按钮)。
  final bool expand;

  /// 显式指定宽度。设置后忽略 [expand]。
  final double? width;

  /// 显示加载态。为 true 时禁用点击并显示转圈。
  final bool loading;

  /// 覆盖高度。不传时由 [size] 决定。
  final double? height;

  /// 覆盖圆角。不传时为全圆角胶囊 (高度的一半)。
  ///
  /// 登录页和部分对话框按钮在 Figma 里是 8 / 12 圆角, 用这个参数保持原样。
  final double? borderRadius;

  /// 覆盖字号。不传时由 [size] 决定。
  final double? fontSize;

  /// 覆盖字重。不传时用 [AppTypography.itemLabel] 的字重。
  final FontWeight? fontWeight;

  /// 覆盖填充色。
  ///
  /// 逃生舱: 文件列表/订阅这几屏的 Figma frame 用的是另一套令牌
  /// (`FigmaTokens.primary` = #262626, 与 [TalixButtonVariant.dark] 的
  /// #1A1A1A 不是同一个色)。设计稿合并之前先用这个参数保住原有观感,
  /// 新代码不要用。
  final Color? backgroundColor;

  /// 覆盖前景 (文字 + 图标) 色。同 [backgroundColor], 属于逃生舱。
  final Color? foregroundColor;

  /// 覆盖禁用态填充色。不传时禁用态统一降级到 [AppColors.neutralFill]。
  ///
  /// 「检查更新」按钮转圈时要保持深色底而不是变灰, 靠这个参数实现。
  final Color? disabledBackgroundColor;

  /// 覆盖禁用态前景色。
  final Color? disabledForegroundColor;

  /// 覆盖描边色。只对带描边的 variant 生效。
  final Color? borderColor;

  const TalixButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = TalixButtonVariant.primary,
    this.size = TalixButtonSize.large,
    this.icon,
    this.expand = true,
    this.width,
    this.loading = false,
    this.height,
    this.borderRadius,
    this.fontSize,
    this.fontWeight,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.borderColor,
  });

  /// 是否可点击。加载中也视为不可点击。
  bool get _enabled => onPressed != null && !loading;

  double get _height =>
      height ??
      switch (size) {
        TalixButtonSize.large => 56,
        TalixButtonSize.medium => 44,
        TalixButtonSize.small => 36,
      };

  double get _fontSize =>
      fontSize ??
      switch (size) {
        TalixButtonSize.large => 16,
        TalixButtonSize.medium => 16,
        TalixButtonSize.small => 14,
      };

  /// 实际圆角。默认全圆角胶囊。
  double get _radius => borderRadius ?? _height / 2;

  /// 深色实心按钮填充。Figma 登录/绑定主按钮。
  static const Color _darkFill = Color(0xFF1A1A1A);

  /// 水平内边距。expand 为 true 时用不上, 但 false 时决定按钮宽度。
  double get _horizontalPadding => switch (size) {
        TalixButtonSize.large => 32,
        TalixButtonSize.medium => 24,
        TalixButtonSize.small => 16,
      };

  /// 填充色。禁用态统一降级到 [AppColors.neutralFill]。
  Color get _background {
    if (!_enabled) {
      if (disabledBackgroundColor != null) return disabledBackgroundColor!;
      return switch (variant) {
        // 描边和文字按钮禁用时保持透明, 只把前景色调淡。
        TalixButtonVariant.outline ||
        TalixButtonVariant.text ||
        TalixButtonVariant.neutralOutline ||
        TalixButtonVariant.dangerOutline =>
          Colors.transparent,
        _ => AppColors.neutralFill,
      };
    }
    if (backgroundColor != null) return backgroundColor!;
    return switch (variant) {
      TalixButtonVariant.primary => AppColors.primary,
      TalixButtonVariant.secondary => AppColors.neutralFill,
      TalixButtonVariant.dark => _darkFill,
      TalixButtonVariant.danger => AppColors.danger,
      // 危险描边按钮是白底 (不是透明), 否则叠在灰色页面背景上会发灰。
      TalixButtonVariant.dangerOutline => AppColors.surface,
      TalixButtonVariant.outline ||
      TalixButtonVariant.text ||
      TalixButtonVariant.neutralOutline =>
        Colors.transparent,
    };
  }

  /// 前景 (文字 + 图标) 色。
  Color get _foreground {
    if (!_enabled) {
      if (disabledForegroundColor != null) return disabledForegroundColor!;
      return switch (variant) {
        // 实心按钮禁用时文字用主文字色, 靠灰底表达禁用。
        TalixButtonVariant.primary ||
        TalixButtonVariant.secondary ||
        TalixButtonVariant.dark ||
        TalixButtonVariant.danger =>
          AppColors.textPrimary,
        _ => AppColors.textSecondary,
      };
    }
    if (foregroundColor != null) return foregroundColor!;
    return switch (variant) {
      TalixButtonVariant.primary ||
      TalixButtonVariant.dark ||
      TalixButtonVariant.danger =>
        AppColors.textOnPrimary,
      TalixButtonVariant.secondary => AppColors.textPrimary,
      TalixButtonVariant.neutralOutline => AppColors.textSecondary,
      TalixButtonVariant.dangerOutline => AppColors.danger,
      TalixButtonVariant.outline || TalixButtonVariant.text => AppColors.primary,
    };
  }

  BorderSide get _border {
    final Color? color = borderColor ??
        switch (variant) {
          TalixButtonVariant.outline => AppColors.primary,
          TalixButtonVariant.dangerOutline => AppColors.danger,
          TalixButtonVariant.neutralOutline => AppColors.divider,
          _ => null,
        };
    if (color == null) return BorderSide.none;
    return BorderSide(
      color: _enabled ? color : AppColors.neutralFill,
      width: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.itemLabel.copyWith(
      fontSize: _fontSize,
      fontWeight: fontWeight,
      color: _foreground,
    );

    final Widget content = loading
        ? SizedBox(
            width: _fontSize + 2,
            height: _fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _fontSize + 2, color: _foreground),
                const SizedBox(width: 6),
              ],
              // Flexible 防止长文案在窄容器里溢出。
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final button = SizedBox(
      width: width ?? (expand ? double.infinity : null),
      height: _height,
      child: Material(
        color: _background,
        // 默认 cornerRadius = 高度的一半, 即 Figma 的全圆角胶囊。
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(_radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: _border == BorderSide.none
                  ? null
                  : Border.fromBorderSide(_border),
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      child: ExcludeSemantics(child: button),
    );
  }
}
