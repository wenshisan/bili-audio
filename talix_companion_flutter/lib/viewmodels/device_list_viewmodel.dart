import '../data/device_item.dart';
import '../services/api/device_api.dart';
import '../utils/app_logger.dart';
import '../utils/safe_change_notifier.dart';

// ============================================================
// 设备列表 ViewModel (MVVM)
// 状态: 设备列表 (从 DeviceApi 真实接口拉取)
//
// 继承 SafeChangeNotifier: 构造时启动 refresh() → 用户快速返回屏幕 →
// State.dispose() 触发 ViewModel.dispose() → in-flight 网络请求完成后
// finally 块调 notifyListeners() 被基类 no-op,避免 "used after disposed" 闪退。
// ============================================================
class DeviceListViewModel extends SafeChangeNotifier {
  final DeviceApi _api = DeviceApi.instance;

  final List<DeviceItem> _devices = [];
  List<DeviceItem> get devices => List.unmodifiable(_devices);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  DeviceListViewModel() {
    refresh();
  }

  /// 从后端拉取设备列表
  ///
  /// 加载流程:
  /// 1. 设 loading=true 通知 UI 转圈
  /// 2. 调用 DeviceApi.getDeviceList() (GET /sl/app/recording-device/list,
  ///    Authorization 由 ApiClient 拦截器自动注入,后端按当前账号过滤)
  /// 3. 成功 → 替换列表 + 清 error
  /// 4. 失败 → 保留旧列表,设置 error 让 UI 提示
  ///
  /// 调用时机: 屏幕首次 initState / 当前账号变更 / 绑定/解绑设备后 /
  /// 下拉刷新。refresh() 内有 `_loading` 互斥锁, 并发触发安全。
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.getDeviceList();
      _devices
        ..clear()
        ..addAll(list);
    } catch (e, st) {
      AppLogger.e('device list load failed', 'device-list', e, st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 清空列表 + loading/error 状态 (用户登出时调用, 防止下一个用户看到上一个用户的数据)
  void clear() {
    _devices.clear();
    _error = null;
    _loading = false;
    notifyListeners();
  }

  /// 删除设备 (解绑)
  Future<void> removeDevice(String deviceSN) async {
    try {
      await _api.removeDevice(deviceSN: deviceSN);
      _devices.removeWhere((d) => d.serialNumber == deviceSN);
      notifyListeners();
    } catch (e, st) {
      AppLogger.e('device remove failed: $deviceSN', 'device-list', e, st);
      rethrow;
    }
  }

  /// 重命名设备
  Future<void> renameDevice({
    required String deviceSN,
    required String newName,
  }) async {
    try {
      await _api.updateDeviceName(deviceSN: deviceSN, deviceName: newName);
      final idx = _devices.indexWhere((d) => d.serialNumber == deviceSN);
      if (idx >= 0) {
        // DeviceItem 没有 copyWith,name 是 final,这里重建 (不会丢失 serialNumber/token 等)
        final old = _devices[idx];
        _devices[idx] = DeviceItem(
          id: old.id,
          name: newName,
          serialNumber: old.serialNumber,
          deviceToken: old.deviceToken,
          connected: old.connected,
          productLine: old.productLine,
        );
      }
      notifyListeners();
    } catch (e, st) {
      AppLogger.e('device rename failed: $deviceSN', 'device-list', e, st);
      rethrow;
    }
  }
}
