import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/safe_change_notifier.dart';

// ============================================================
// 设备绑定 ViewModel (MVVM)
// 状态机: 搜索中 (searching) / 未找到 (notFound) / 发现 (found)
// 严格对应 Figma 节点:
//   - searching  → 1218:4070 "正在搜索附近设备..."
//   - notFound   → 1218:4039 "未找到附近设备"
//   - found      → 1218:4097 "发现附近设备" (设备卡片 + 连接按钮)
//
// 当前使用假设备数据 (无真实硬件, SN 写死为 "talix2026A0008")
// 用于在没接硬件时调试服务端绑定接口 (/sl/app/recording-device/add)
// 真实硬件就绪后, SN 改为从蓝牙扫描结果传入, 见 _connect() 调用方
// ============================================================
enum AddDeviceState {
  /// 搜索中 (Figma 1218:4070)
  searching,

  /// 未找到附近设备 (Figma 1218:4039) — 提供 "重新扫描" 与 "手动添加设备"
  notFound,

  /// 已发现附近设备 (Figma 1218:4097) — 提供 "连接" 按钮
  found,
}

// 继承 SafeChangeNotifier: simulateScanInDebug() 用 2 秒定时器模拟扫描 →
// 用户 2 秒内就点返回 → State.dispose() 触发 ViewModel.dispose() → 定时器
// 回调再调 notifyListeners() → 抛 "used after being disposed"。
// 基类负责 disposed 后静默 no-op, 本类另外在 dispose() 里取消定时器。
class BindingViewModel extends SafeChangeNotifier {
  AddDeviceState _state = AddDeviceState.searching;
  AddDeviceState get state => _state;

  /// 模拟扫描的定时器句柄。dispose() 与重新扫描时都要先取消, 避免叠加。
  Timer? _scanTimer;

  // ===== 假设备数据 (无真实硬件时使用) =====
  // TODO(硬件就绪后删除): 改为从蓝牙扫描结果动态注入
  static const String _fakeDeviceName = 'Talix AI Note 假设备';
  static const String _fakeDeviceSerial = 'talix2026A0008';

  /// 当前"发现"状态显示的设备名 (无真实硬件时 = 假设备名)
  final String _deviceName = _fakeDeviceName;
  String get deviceName => _deviceName;

  /// 当前"发现"状态显示的设备 SN (无真实硬件时 = 假设备 SN)
  final String _deviceSerial = _fakeDeviceSerial;
  String get deviceSerial => _deviceSerial;

  /// 模拟扫描设备: 仅在 debug 模式下生效
  /// - auto=true (默认): 2 秒后自动切换到 [nextResult] 指定的页面状态 (默认 found)
  /// - auto=false: 立即切换到 [nextResult] 指定的页面状态
  void simulateScanInDebug({
    bool auto = true,
    AddDeviceState nextResult = AddDeviceState.found,
  }) {
    if (!kDebugMode || !auto) {
      if (!auto) _setState(nextResult);
      return;
    }
    // 反复点"重新扫描"会叠加定时器, 先取消上一个。
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 2), () {
      _scanTimer = null;
      if (isDisposed) return;
      if (_state == AddDeviceState.searching) {
        _setState(nextResult);
      }
    });
  }

  /// 重新扫描 (用户在 1218:4039 未找到页点击"重新扫描"链接时调用)
  void retryScan() {
    _setState(AddDeviceState.searching);
    simulateScanInDebug();
  }

  /// 用户点击"手动添加设备"时调用,跳过搜索直接标记为 found
  void markDeviceFound() {
    _setState(AddDeviceState.found);
  }

  /// 模拟未找到 (debug 辅助: 通过调试菜单触发 1218:4039 页面状态)
  void markDeviceNotFound() {
    _setState(AddDeviceState.notFound);
  }

  void _setState(AddDeviceState newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }

  /// 重置到初始 searching 状态 (debug 辅助)
  void reset() {
    _setState(AddDeviceState.searching);
  }

  @override
  void dispose() {
    // 先释放定时器再调 super, 否则回调仍可能在 disposed 之后跑一次。
    _scanTimer?.cancel();
    _scanTimer = null;
    super.dispose();
  }
}
