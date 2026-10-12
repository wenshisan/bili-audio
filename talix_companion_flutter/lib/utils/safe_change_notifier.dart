import 'package:flutter/foundation.dart';

// ============================================================
// SafeChangeNotifier — 安全的 ChangeNotifier 基类
//
// 解决问题: ChangeNotifier 在 dispose() 之后再调 notifyListeners() 会抛
//   "A XXX was used after being disposed" 异常。
//
// 触发场景 (本项目踩过的坑):
//   1) 构造函数中调 `refresh()` 启动异步加载 → 用户快速返回上一页 →
//      State.dispose() 触发 ViewModel.dispose() → 异步 Future 完成后
//      在 finally 里调 `notifyListeners()` → 抛错
//   2) 调 `confirmDelete()` 后用户立刻返回 → await 网络回来后
//      `notifyListeners()` 抛错
//   3) `Future.delayed` 模拟的"AI 回答" 1.5 秒延迟 — 用户 1 秒就返回 →
//      回调里 `notifyListeners()` 抛错
//
// 解法:
//   1) 子类用 `notifyListeners()` 即可,基类会判断 disposed 状态
//   2) 子类的 dispose() 用 `@override`,记得 `super.dispose()` 末尾调用
//   3) 如果 ViewModel 持有 Timer / StreamSubscription / Future 句柄,
//      子类 dispose() 里要先释放,再 `super.dispose()`
//
// 不解决: 异步回调里对 ViewModel 字段的**赋值**。在 disposed 之后赋值
// 只是浪费 CPU,不会报错;但若赋值后再调 notifyListeners() 也不会有任何效果
// (listeners 已 detach)。所以 dispose 之后的写入是安全的,只是无用。
// ============================================================
abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  /// ViewModel 是否已 dispose (供子类在异步回调里做"早退"优化,可选)
  bool get isDisposed => _disposed;

  /// 覆盖 notifyListeners,disposed 后静默 no-op,避免 "used after disposed"
  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
