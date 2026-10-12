import 'package:flutter/material.dart';

/// Figma 设计令牌 — 颜色
///
/// 取自 Figma「Talix AI Device UI」(file DvVN6Ib1WkEfJBfmkU4oMR) 中
/// 17 选择列表 / 18 选择模版 / 19 分享选择列表 / 20 导出选择列表 / 21 选择倍速
/// 这几个 frame 的实测值。
///
/// 新代码引用这里的常量，不要再写颜色字面量。
class AppColors {
  const AppColors._();

  // ---------- 品牌色 ----------

  /// 主色。主 CTA 填充、选中态描边、对勾统一使用。
  ///
  /// 注意: 与旧代码里的 `#10B981` 不是同一个绿, Figma 这版更亮、偏黄绿。
  static const Color primary = Color(0xFF39D03D);

  /// 主色浅底。模版列表的图标底色 (ic_template1)。
  static const Color primarySurface = Color(0xFFE6F8ED);

  /// 蓝色浅底。部分模版图标底色 (咨询问答)。
  static const Color infoSurface = Color(0xFFEBF2FF);

  /// 危险色。解绑、删除、清除数据这类不可逆操作。
  ///
  /// 取 `Colors.redAccent` 的色值, 与替换前各屏幕的实际观感保持一致。
  static const Color danger = Color(0xFFFF5252);

  // ---------- 中性填充 ----------

  /// 次级按钮填充, 同时用作禁用态填充。Figma「复制链接」「取消」按钮。
  static const Color neutralFill = Color(0xFFCCCCCC);

  /// 页面背景。
  static const Color background = Color(0xFFF2F2F2);

  /// 卡片 / 列表容器背景。
  static const Color surface = Color(0xFFFFFFFF);

  // ---------- 文字 ----------

  /// 主文字。标题、列表项名称、次级按钮文字。
  static const Color textPrimary = Color(0xFF333333);

  /// 辅助文字。副标题、说明文案、格式标签 (MP3 / TXT / PNG)。
  static const Color textSecondary = Color(0xFF999999);

  /// 主色按钮上的文字。
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// iOS 状态栏时间文字。
  static const Color textStatusBar = Color(0xFF1E1B24);

  // ---------- 描边 / 分割线 ----------

  /// 列表项分割线。
  static const Color divider = Color(0xFFE7E7E7);

  /// 卡片内分割线。比 [divider] 略深一点。
  static const Color dividerCard = Color(0xFFE9E9EA);

  /// 未选中的圆形复选框描边。
  static const Color borderUnselected = Color(0xFF999999);

  // ---------- 设备信息页 (Figma 669:5665 / 5853 / 6303 / 6574) ----------

  /// 设备信息卡描边。1px + 4px 圆角。
  static const Color cardBorder = Color(0xFFE0E0E0);

  /// 「解绑并重置」这类破坏性行文字。比 [danger] 更暗、饱和度更低。
  static const Color dangerText = Color(0xFFEE3939);

  /// 「可升级」徽标文字, 配 [infoSurface] 底。
  static const Color infoText = Color(0xFF3D7FF8);

  /// 进度条底槽 (侧边栏套餐卡 / 设备储存卡)。
  static const Color progressTrack = Color(0xFFD9D9D9);

  /// 文件表格行分割线。
  static const Color tableDivider = Color(0xFFE9E9E9);
}
