import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 表单和设置在宽窗口上居中，并不超过 [maxWidth]。
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({required this.child, this.maxWidth = 640, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(maxWidth, constraints.maxWidth);
        final height = constraints.maxHeight;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, height: height, child: child),
        );
      },
    );
  }
}
