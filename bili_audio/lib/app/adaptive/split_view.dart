import 'package:flutter/material.dart';

import '../widgets/region_surface.dart';

/// 主从栏分隔。比例是左栏占可用宽度的份额，限制在 0.4–0.75。
class SplitView extends StatefulWidget {
  const SplitView({
    required this.ratio,
    required this.onRatioEnd,
    required this.first,
    required this.second,
    super.key,
  });

  final double ratio;
  final ValueChanged<double> onRatioEnd;
  final Widget first;
  final Widget second;

  static double clampRatio(double ratio) => ratio.clamp(0.4, 0.75);

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final ratio = SplitView.clampRatio(_dragging ?? widget.ratio);
    return LayoutBuilder(
      builder: (context, constraints) {
        const handleWidth = 12.0;
        final available = constraints.maxWidth;
        if (available <= 0) return const SizedBox.shrink();
        final firstWidth = available * ratio;
        final handleLeft = (firstWidth - handleWidth / 2).clamp(
          0.0,
          (available - handleWidth).clamp(0.0, double.infinity),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                SizedBox(width: firstWidth, child: widget.first),
                Expanded(
                  child: RegionSurface(
                    edge: RegionEdge.leading,
                    child: widget.second,
                  ),
                ),
              ],
            ),
            Positioned(
              left: handleLeft,
              top: 0,
              bottom: 0,
              width: handleWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  key: const Key('split-handle'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    final next = firstWidth + details.delta.dx;
                    setState(
                      () => _dragging = SplitView.clampRatio(next / available),
                    );
                  },
                  onHorizontalDragEnd: (_) {
                    final settled = SplitView.clampRatio(
                      _dragging ?? widget.ratio,
                    );
                    setState(() => _dragging = null);
                    widget.onRatioEnd(settled);
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
