import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Figma 选择列表行。
///
/// 对应设计稿 17/19/20/21 四个选择页里反复出现的行结构:
/// 左侧标题 (+ 可选副标题), 右侧任意 trailing (勾选标记 / 复选框 / 格式标签),
/// 底部 1px 分隔线。
///
/// 垂直度量来自 Figma 实测 (三种行高都能对上):
///   上边距 24 + 内容 + 间距 23 + 分隔线 1
///   → 纯标题 64, 标题+单行副标题 88, 标题+两行副标题 120
///
/// ```dart
/// TalixOptionRow(
///   title: 'GPT-5.5',
///   subtitle: '适合深度讨论与复杂推理',
///   trailing: TalixRadio<String>(
///     value: 'gpt',
///     groupValue: _selected,
///     onChanged: (v) => setState(() => _selected = v),
///   ),
///   onTap: () => setState(() => _selected = 'gpt'),
/// )
/// ```
class TalixOptionRow extends StatelessWidget {
  /// 主标题。
  final String title;

  /// 副标题, 可选。传 null 时行高收缩为纯标题布局。
  final String? subtitle;

  /// 副标题是否可能换行。
  ///
  /// Figma 里单行副标题用紧凑行高 (14), 换行的用 22。默认 false,
  /// 长文案传 true 以获得正确的行间距。
  final bool subtitleWraps;

  /// 右侧控件, 通常是 TalixRadio / TalixCheckbox / [TalixRowValueLabel]。
  final Widget? trailing;

  /// 整行点击回调。
  final VoidCallback? onTap;

  /// 是否绘制底部分隔线。列表最后一行通常传 false。
  final bool showDivider;

  /// 水平内边距。Figma 为 24。
  final double horizontalPadding;

  const TalixOptionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWraps = false,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.horizontalPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // 不加这行时 Column 会吃掉父级给的全部高度, 行高失控。
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.itemLabel),
                    if (subtitle != null) ...[
                      // 24 + 16 (标题) + 10 + 14 (副标题) + 23 + 1 = 88, 对上 Figma。
                      const SizedBox(height: 10),
                      Text(
                        subtitle!,
                        style: subtitleWraps
                            ? AppTypography.captionMultiline
                            : AppTypography.caption,
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
          const SizedBox(height: 23),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(onTap: onTap, child: content);
  }
}

/// 导出页右侧的「格式 + 箭头」组合, 如 `MP3 >` / `TXT >`。
///
/// Figma: 14px/400 #999999 文字 + 2px 间距 + 16x16 箭头。
class TalixRowValueLabel extends StatelessWidget {
  /// 显示的值, 如 `MP3`。
  final String value;

  const TalixRowValueLabel({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: AppTypography.caption),
        const SizedBox(width: 2),
        const Icon(
          Icons.chevron_right,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}
