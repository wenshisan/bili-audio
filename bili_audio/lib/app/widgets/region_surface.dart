import 'package:flutter/material.dart';

/// 阴影落在相邻区域的哪一侧。
enum RegionEdge {
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

/// 功能区与画布同色，只在交界投一层浅阴影。
class RegionSurface extends StatelessWidget {
  /// 创建一块功能区表面。
  const RegionSurface({
    required this.child,
    this.edge = RegionEdge.none,
    this.extent = 1,
    super.key,
  });

  /// 区域内的内容。
  final Widget child;

  /// 投向相邻区域的阴影方向。
  final RegionEdge edge;

  /// 阴影厚度，单位是逻辑像素。
  final double extent;

  @override
  Widget build(BuildContext context) {
    final body = ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
    if (edge == RegionEdge.none) return body;
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [_shade(context, edge, extent), body],
    );
  }
}

const _shadeColor = Color(0x29000000);

Widget _shade(BuildContext context, RegionEdge edge, double extent) {
  final leadingIsLeft = Directionality.of(context) == TextDirection.ltr;
  final side = switch (edge) {
    RegionEdge.leading => leadingIsLeft ? _Side.left : _Side.right,
    RegionEdge.trailing => leadingIsLeft ? _Side.right : _Side.left,
    RegionEdge.top => _Side.top,
    RegionEdge.bottom => _Side.bottom,
    RegionEdge.none => null,
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
          colors: [_shadeColor, _shadeColor.withValues(alpha: 0)],
        ),
      ),
    ),
  );
  return switch (side) {
    _Side.left => Positioned(
      left: -extent,
      width: extent,
      top: 0,
      bottom: 0,
      child: fade,
    ),
    _Side.right => Positioned(
      right: -extent,
      width: extent,
      top: 0,
      bottom: 0,
      child: fade,
    ),
    _Side.top => Positioned(
      top: -extent,
      height: extent,
      left: 0,
      right: 0,
      child: fade,
    ),
    _Side.bottom => Positioned(
      bottom: -extent,
      height: extent,
      left: 0,
      right: 0,
      child: fade,
    ),
    null => const SizedBox.shrink(),
  };
}

enum _Side { left, right, top, bottom }
