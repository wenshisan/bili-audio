import 'dart:ui';
import 'package:flutter/material.dart';
import 'auth_assets.dart';

// ============================================================
// auth_card_scaffolding.dart
// 登录流程 + 设备添加流程共用的页面骨架
// Figma 669:4626 / 5229 / 5266 / 5298 / 5082 / 5122 / 5160 / 5196
//
// 背景: #F2F2F2 + 三个装饰光晕椭圆 (紫 + 两个薄荷绿)
// 卡片: 440×600, 24px 圆角, 白色, 1px #F1F5F9 描边,
//       boxShadow 0 16 40 rgba(15,23,42,0.03), padding 40
// 品牌区: Talix logo (160×34) + 标语 "Fashion Tech. Joy Every Moment."
// ============================================================

/// 完整页面骨架: Scaffold + 背景装饰 + 居中卡片。
///
/// [content] 卡片内品牌区下方的具体内容。
/// [overlay] 叠在卡片之上的额外元素 (如返回按钮、调试菜单), 需自行 Positioned。
class AuthCardScaffolding extends StatelessWidget {
  final Widget content;
  final List<Widget> overlay;

  const AuthCardScaffolding({
    super.key,
    required this.content,
    this.overlay = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          ...buildBackgroundDecorations(),
          Center(child: AuthCard(content: content)),
          ...overlay,
        ],
      ),
    );
  }
}

/// 背景装饰光晕（三个模糊椭圆）。
/// Figma: 紫 @ (306,0) 300px blur60 / 薄荷绿 @ (875,357) 663px blur40 /
///        薄荷绿 @ (-86,300) 271px blur40 opacity .6
List<Widget> buildBackgroundDecorations() {
  return [
    _glowCircle(
      left: 306,
      top: 0,
      size: 300,
      blurSigma: 60,
      colors: const [Color(0xFFEDE9FE), Color(0x66EDE9FE)],
    ),
    _glowCircle(
      left: 875,
      top: 357,
      size: 663,
      blurSigma: 40,
      colors: const [Color(0x4DCBFECD), Color(0xFFCBFECD)],
    ),
    _glowCircle(
      left: -86,
      top: 300,
      size: 271,
      blurSigma: 40,
      opacity: 0.6,
      colors: const [Color(0x4DCBFECD), Color(0xCCCBFECD)],
    ),
  ];
}

Widget _glowCircle({
  required double left,
  required double top,
  required double size,
  required List<Color> colors,
  required double blurSigma,
  double opacity = 1.0,
}) {
  return Positioned(
    left: left,
    top: top,
    child: Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 440×600 白色卡片 + 顶部品牌区。
/// Figma auth-card: 24px 圆角, 1px #F1F5F9 描边, padding 40, gap 40
class AuthCard extends StatelessWidget {
  final Widget content;

  const AuthCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A), // rgba(15,23,42,0.03)
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AuthBrandHeader(),
            const SizedBox(height: 40),
            content,
          ],
        ),
      ),
    );
  }
}

/// 品牌区: Talix logo (160×34) + 标语 "Fashion Tech. Joy Every Moment.", gap 12
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AuthTalixLogo(),
        SizedBox(height: 12),
        Text(
          'Fashion Tech. Joy Every Moment.',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF78FA7C),
            height: 18 / 14,
          ),
        ),
      ],
    );
  }
}
