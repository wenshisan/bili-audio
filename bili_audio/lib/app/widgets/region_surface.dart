import 'package:flutter/material.dart';

/// 功能区相对主画布的明度。
enum RegionTone {
  /// 与脚手架相同的表面色。
  canvas,

  /// 比画布高一档，用于歌词、详情等次级内容。
  low,

  /// 导航、播放栏和标题栏用的更高一档。
  high,
}

/// 阴影落在相邻区域的哪一侧。
enum RegionShadow {
  /// 不投影。
  none,

  /// 盖住起始一侧的邻居。
  leading,

  /// 盖住结束一侧的邻居。
  trailing,

  /// 向上盖住上方的邻居。
  top,

  /// 向下盖住下方的邻居。
  bottom,
}

/// 用色差和单侧柔和阴影区分功能区，不画分割线。
class RegionSurface extends StatelessWidget {
  /// 创建一块功能区表面。
  const RegionSurface({
    required this.child,
    this.tone = RegionTone.low,
    this.shadow = RegionShadow.none,
    super.key,
  });

  /// 区域内的内容。
  final Widget child;

  /// 填充色档位。
  final RegionTone tone;

  /// 投向相邻区域的阴影方向。
  final RegionShadow shadow;

  /// 返回 [tone] 在 [scheme] 上的填充色。
  static Color colorOf(ColorScheme scheme, RegionTone tone) => switch (tone) {
    RegionTone.canvas => scheme.surface,
    RegionTone.low => scheme.surfaceContainerLow,
    RegionTone.high => scheme.surfaceContainer,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = ColoredBox(color: colorOf(scheme, tone), child: child);
    if (shadow == RegionShadow.none) return body;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [_shade(context, shadow, _shadeColor(scheme)), body],
    );
  }
}

const _shadeExtent = 18.0;

Color _shadeColor(ColorScheme scheme) {
  final alpha = scheme.brightness == Brightness.dark ? 0.55 : 0.18;
  return Colors.black.withValues(alpha: alpha);
}

Widget _shade(BuildContext context, RegionShadow edge, Color color) {
  final leadingIsLeft = Directionality.of(context) == TextDirection.ltr;
  final side = switch (edge) {
    RegionShadow.leading => leadingIsLeft ? _Side.left : _Side.right,
    RegionShadow.trailing => leadingIsLeft ? _Side.right : _Side.left,
    RegionShadow.top => _Side.top,
    RegionShadow.bottom => _Side.bottom,
    RegionShadow.none => null,
  };
  final fade = IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: switch (side) {
            _Side.left => Alignment.centerRight,
            _Side.right => Alignment.centerLeft,
            _Side.top => Alignment.bottomCenter,
            _Side.bottom => Alignment.topCenter,
            null => Alignment.center,
          },
          end: switch (side) {
            _Side.left => Alignment.centerLeft,
            _Side.right => Alignment.centerRight,
            _Side.top => Alignment.topCenter,
            _Side.bottom => Alignment.bottomCenter,
            null => Alignment.center,
          },
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
  return switch (side) {
    _Side.left => Positioned(
      left: -_shadeExtent,
      width: _shadeExtent,
      top: 0,
      bottom: 0,
      child: fade,
    ),
    _Side.right => Positioned(
      right: -_shadeExtent,
      width: _shadeExtent,
      top: 0,
      bottom: 0,
      child: fade,
    ),
    _Side.top => Positioned(
      top: -_shadeExtent,
      height: _shadeExtent,
      left: 0,
      right: 0,
      child: fade,
    ),
    _Side.bottom => Positioned(
      bottom: -_shadeExtent,
      height: _shadeExtent,
      left: 0,
      right: 0,
      child: fade,
    ),
    null => const SizedBox.shrink(),
  };
}

enum _Side { left, right, top, bottom }
