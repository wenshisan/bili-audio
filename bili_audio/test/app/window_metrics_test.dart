import 'package:bili_audio/app/adaptive/layout_settings.dart';
import 'package:bili_audio/app/adaptive/window_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('代表尺寸落入任务表中的宽高档', () {
    const cases = <(double, double, WindowWidth, WindowHeight)>[
      (390, 844, WindowWidth.compact, WindowHeight.tall),
      (844, 390, WindowWidth.expanded, WindowHeight.short),
      (600, 800, WindowWidth.medium, WindowHeight.regular),
      (768, 1024, WindowWidth.medium, WindowHeight.tall),
      (1194, 834, WindowWidth.large, WindowHeight.regular),
      (1280, 800, WindowWidth.large, WindowHeight.regular),
      (480, 800, WindowWidth.compact, WindowHeight.regular),
      (1920, 720, WindowWidth.extraLarge, WindowHeight.regular),
      (1280, 480, WindowWidth.large, WindowHeight.short),
    ];

    for (final (w, h, width, height) in cases) {
      final metrics = WindowMetrics.fromSize(Size(w, h));
      expect(metrics.width, width, reason: '$w×$h width');
      expect(metrics.height, height, reason: '$w×$h height');
    }
  });

  test('844×390 是 expanded + short，且不是主从栏', () {
    final metrics = WindowMetrics.fromSize(const Size(844, 390));
    expect(metrics.width, WindowWidth.expanded);
    expect(metrics.isShort, isTrue);
    expect(metrics.usesMasterDetail, isFalse);
    expect(metrics.usesBottomNav, isTrue);
  });

  test('车机布局只由开关或系统车载模式决定', () {
    expect(resolveCarLayout(CarLayoutMode.auto, false), isFalse);
    expect(resolveCarLayout(CarLayoutMode.auto, true), isTrue);
    expect(resolveCarLayout(CarLayoutMode.on, false), isTrue);
    expect(resolveCarLayout(CarLayoutMode.off, true), isFalse);
  });
}
