import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Figma 对勾图形。
///
/// Figma 里的 `Vector 12` 是一条 13x10 的折线 (stroke 2px, 无填充),
/// 不是 Material 的 `Icons.check`。这里用 CustomPainter 精确还原,
/// 让描边粗细和拐点位置跟设计稿一致。
class TalixCheckMark extends StatelessWidget {
  /// 对勾颜色。
  final Color color;

  /// 对勾宽度。高度按 10/13 比例自动推导。
  final double width;

  /// 描边粗细。
  final double strokeWidth;

  const TalixCheckMark({
    super.key,
    this.color = AppColors.primary,
    this.width = 13,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      // Figma 原始比例 13x10。
      height: width * 10 / 13,
      child: CustomPaint(
        painter: _CheckMarkPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _CheckMarkPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _CheckMarkPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 折线三个点按 13x10 归一化后映射到实际尺寸,
    // 这样换尺寸时形状不变形。
    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.45)
      ..lineTo(size.width * 0.36, size.height * 0.88)
      ..lineTo(size.width * 0.96, size.height * 0.12);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckMarkPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
