import 'package:flutter/material.dart';

/// 窗口宽度档。布局只看逻辑像素，不看设备类型。
///
/// large 从 1194 起：11 英寸 iPad 横屏是 1194，任务要求这一档用主从栏。
enum WindowWidth { compact, medium, expanded, large, extraLarge }

/// 窗口高度档。只影响纵向密度，不单独决定导航形态。
enum WindowHeight { short, regular, tall }

/// 由内容区宽高得到的布局档位。
class WindowMetrics {
  const WindowMetrics(this.width, this.height);

  factory WindowMetrics.fromSize(Size size) => WindowMetrics(
        widthClass(size.width),
        heightClass(size.height),
      );

  final WindowWidth width;
  final WindowHeight height;

  bool get usesRail => width != WindowWidth.compact && !isShort;

  bool get usesMasterDetail =>
      (width == WindowWidth.large || width == WindowWidth.extraLarge) &&
      !isShort;

  bool get isShort => height == WindowHeight.short;

  /// 矮窗口（手机横屏）用底部导航，避免侧栏在高度不足时溢出。
  bool get usesBottomNav => !usesRail && !usesMasterDetail;

  @override
  bool operator ==(Object other) =>
      other is WindowMetrics && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

WindowWidth widthClass(double width) {
  if (width < 600) return WindowWidth.compact;
  if (width < 840) return WindowWidth.medium;
  if (width < 1194) return WindowWidth.expanded;
  if (width < 1600) return WindowWidth.large;
  return WindowWidth.extraLarge;
}

WindowHeight heightClass(double height) {
  if (height < 500) return WindowHeight.short;
  // 390×844 要算 tall，1280×800 与 1194×834 仍是 regular。
  if (height < 844) return WindowHeight.regular;
  return WindowHeight.tall;
}

/// 壳层把内容区档位传给子页面。播放页等壳外路由自行用 [WindowMetrics.fromSize]。
class WindowMetricsScope extends InheritedWidget {
  const WindowMetricsScope({
    required this.metrics,
    required super.child,
    super.key,
  });

  final WindowMetrics metrics;

  static WindowMetrics? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WindowMetricsScope>()?.metrics;

  @override
  bool updateShouldNotify(WindowMetricsScope oldWidget) =>
      metrics != oldWidget.metrics;
}
