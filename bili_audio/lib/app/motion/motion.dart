import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// 页面切换、状态替换和列表入场共用的时长。
///
/// 系统开启「减少动态效果」时，过渡时长为零，列表不再错峰入场。
abstract final class Motion {
  static const swap = Duration(milliseconds: 260);
  static const page = Duration(milliseconds: 320);
  static const pageReverse = Duration(milliseconds: 240);
  static const item = Duration(milliseconds: 280);
  static const stagger = Duration(milliseconds: 32);

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// 底栏三个分页的切换方向。新页从这一侧进入，旧页向反方向让出。
final tabMotion = TabMotion();

final class TabMotion {
  int index = 0;
  double travel = 0.045;
  bool primed = false;

  void reset() {
    index = 0;
    travel = 0.045;
    primed = false;
  }

  void consume(int next) {
    if (next == index) return;
    travel = next >= index ? 0.045 : -0.045;
    index = next;
  }
}

/// 壳层分页。第一次出现不播动画，避免启动时闪一下。
Page<void> shellTabPage({
  required BuildContext context,
  required LocalKey pageKey,
  required String path,
  required int tabIndex,
  required Widget child,
}) {
  final opening = !tabMotion.primed;
  tabMotion.primed = true;
  tabMotion.consume(tabIndex);
  final reduced = Motion.reduced(context);
  return CustomTransitionPage<void>(
    key: pageKey,
    name: path,
    child: child,
    transitionDuration: opening || reduced ? Duration.zero : Motion.page,
    reverseTransitionDuration: reduced ? Duration.zero : Motion.pageReverse,
    transitionsBuilder: (context, animation, secondary, child) {
      return TabTransition(animation: animation, child: child);
    },
  );
}

/// 全屏页。播放页自下而上，其余页横向淡入。
///
/// iOS / macOS 的横向页用系统滑动，保留边缘返回。
Page<void> pushMotionPage({
  required BuildContext context,
  required LocalKey pageKey,
  required String name,
  required Widget child,
  bool vertical = false,
}) {
  if (Motion.reduced(context)) {
    return NoTransitionPage<void>(key: pageKey, name: name, child: child);
  }
  final platform = Theme.of(context).platform;
  if (!vertical &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS)) {
    return CupertinoPage<void>(key: pageKey, name: name, child: child);
  }
  final begin = vertical ? const Offset(0, 0.08) : const Offset(0.06, 0);
  return CustomTransitionPage<void>(
    key: pageKey,
    name: name,
    opaque: false,
    fullscreenDialog: vertical,
    transitionDuration: Motion.page,
    reverseTransitionDuration: Motion.pageReverse,
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      return PushTransition(animation: animation, begin: begin, child: child);
    },
  );
}

/// 底栏切换：旧页先淡出并让开，新页再淡入。中间露出的是壳层底色。
class TabTransition extends StatelessWidget {
  const TabTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final leaving =
            animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;
        final travel = tabMotion.travel;
        final double opacity;
        final double dx;
        if (leaving) {
          final progress = Curves.easeOut.transform(
            _interval(1 - animation.value, 0, 0.35),
          );
          opacity = 1 - progress;
          dx = -travel * progress;
        } else {
          final progress = Curves.easeOutCubic.transform(
            _interval(animation.value, 0.28, 1),
          );
          opacity = progress;
          dx = travel * (1 - progress);
        }
        return ClipRect(
          child: IgnorePointer(
            ignoring: opacity < 1,
            child: Opacity(
              opacity: opacity,
              child: FractionalTranslation(
                translation: Offset(dx, 0),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// 压入的全屏页：淡入并带一小段位移，返回时沿原路退出。
class PushTransition extends StatelessWidget {
  const PushTransition({
    super.key,
    required this.animation,
    required this.begin,
    required this.child,
  });

  final Animation<double> animation;
  final Offset begin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final leaving =
            animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;
        final t = (leaving ? Curves.easeInCubic : Curves.easeOutCubic)
            .transform(animation.value);
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(begin.dx * (1 - t), begin.dy * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 加载、空、出错、有数据之间的淡入替换。
class MotionSwap extends StatelessWidget {
  const MotionSwap({super.key, required this.swapKey, required this.child});

  final Object swapKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : Motion.swap,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - animation.value)),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      child: KeyedSubtree(key: ValueKey<Object>(swapKey), child: child),
    );
  }
}

/// 包住列表。只有出现后很短时间内构建的前几项会入场，
/// 滚出再滚回、或加载更多，都不再重播。
class ListEntranceScope extends StatefulWidget {
  const ListEntranceScope({super.key, required this.child});

  final Widget child;

  @override
  State<ListEntranceScope> createState() => _ListEntranceScopeState();
}

class _ListEntranceScopeState extends State<ListEntranceScope> {
  late final Duration opened = SchedulerBinding.instance.currentFrameTimeStamp;

  @override
  Widget build(BuildContext context) {
    return _EntranceClock(opened: opened, child: widget.child);
  }
}

class _EntranceClock extends InheritedWidget {
  const _EntranceClock({required this.opened, required super.child});

  final Duration opened;

  static Duration? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_EntranceClock>()?.opened;
  }

  @override
  bool updateShouldNotify(_EntranceClock oldWidget) =>
      opened != oldWidget.opened;
}

class ListEntrance extends StatefulWidget {
  const ListEntrance({super.key, required this.index, required this.child});

  static const animatedCount = 8;
  static const window = Duration(milliseconds: 500);

  final int index;
  final Widget child;

  @override
  State<ListEntrance> createState() => _ListEntranceState();
}

class _ListEntranceState extends State<ListEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.item,
  );
  var _delay = 0.0;
  var _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final opened = _EntranceClock.maybeOf(context);
    final fresh =
        opened != null &&
        SchedulerBinding.instance.currentFrameTimeStamp - opened <
            ListEntrance.window;
    final animate =
        fresh &&
        !Motion.reduced(context) &&
        widget.index >= 0 &&
        widget.index < ListEntrance.animatedCount;
    if (!animate) {
      _controller.value = 1;
      return;
    }
    final delay = Motion.stagger * widget.index;
    final total = Motion.item + delay;
    _delay = delay.inMilliseconds / total.inMilliseconds;
    _controller.duration = total;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value == 1 && !_controller.isAnimating) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          _interval(_controller.value, _delay, 1),
        );
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(0, 0.22 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 列表加载时的扫光骨架。
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 8, this.leading = 56});

  final int count;
  final double leading;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width) => Container(
      width: width,
      height: 12,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (_, i) => ListTile(
          leading: Container(width: leading, height: leading, color: color),
          title: bar(i.isEven ? 180 : 140),
          subtitle: bar(100),
        ),
      ),
    );
  }
}

class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.lerp(base, scheme.onSurface, 0.08) ?? base;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + 2.4 * t, -0.2),
              end: Alignment(-0.2 + 2.4 * t, 0.2),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

double _interval(double t, double start, double end) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return (t - start) / (end - start);
}
