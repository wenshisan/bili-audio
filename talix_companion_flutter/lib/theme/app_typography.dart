import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Figma 设计令牌 — 字体
///
/// Figma 里所有文字的 letterSpacing 都是 0.06, 这里统一封装, 避免逐处手写。
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Inter';

  /// Figma 全局字距。
  static const double letterSpacing = 0.06;

  /// 区块标题。20px / Medium — 「通过链接分享」
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: letterSpacing,
    color: AppColors.textPrimary,
  );

  /// 导航栏标题。16px / Regular — 「分享」「选择AI模型」
  static const TextStyle navTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: letterSpacing,
    color: AppColors.textPrimary,
  );

  /// 列表项主文字 / 按钮文字。16px / Medium
  static const TextStyle itemLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: letterSpacing,
    color: AppColors.textPrimary,
  );

  /// 单行副标题。14px / Regular, 行高 = 字号 (紧凑)
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: letterSpacing,
    color: AppColors.textSecondary,
  );

  /// 多行说明文字。14px / Regular, 行高 22 (22/14)
  ///
  /// Figma 中换行的描述文案用这个, 单行的用 [caption]。
  static const TextStyle captionMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 22 / 14,
    letterSpacing: letterSpacing,
    color: AppColors.textSecondary,
  );
}
