import 'package:flutter/foundation.dart';

import '../services/api/device_api.dart';
import '../utils/app_logger.dart';

// ============================================================
// DeviceModel (全局设备状态, MVVM)
// 状态: deviceName, isBound, indicatorLight, recordingMode,
//       forgetReminder, batteryLevel, deviceSN, deviceToken
// 业务方: device_list, device_settings, device_detail_offline,
//         recordings_feed, main_frame, binding_screens 等
//
// 绑定流程: 真实硬件就绪前使用假设备 SN (talix2026A0008),
// 调用 /sl/app/recording-device/add 调试服务端接口
// ============================================================
class DeviceModel extends ChangeNotifier {
  String _deviceName = "Talix AI Note";
  bool _isBound = false;
  bool _indicatorLight = true;
  String _recordingMode = "general"; // general, meeting, interview, backup
  String _forgetReminder = "unlimited"; // unlimited, 8h, 12h, 24h
  double _batteryLevel = 0.80; // 80%
  bool _isCharging = true; // 「充电中」徽标 (Figma 669:5828)

  // 硬件上报信息 (Figma 669:5805 信息卡)
  // 真实数值由 /sl/app/recording-device/report-info 上报后回填,
  // 硬件联调前用设计稿示例值占位。
  String _firmwareVersion = 'v1.0.1';
  bool _firmwareUpdatable = true; // 「可升级」徽标 (Figma 669:5849)
  double _storageUsedGB = 3;
  double _storageTotalGB = 64;
  int _recordedHours = 10;
  int _recordableHours = 300;

  // 绑定后服务端下发的标识
  String _deviceSN = ''; // 当前绑定设备的 SN
  String _deviceToken = ''; // 服务端鉴权 token, 用于后续指令

  String get deviceName => _deviceName;
  bool get isBound => _isBound;
  bool get indicatorLight => _indicatorLight;
  String get recordingMode => _recordingMode;
  String get forgetReminder => _forgetReminder;
  double get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  String get firmwareVersion => _firmwareVersion;
  bool get firmwareUpdatable => _firmwareUpdatable;
  double get storageUsedGB => _storageUsedGB;
  double get storageTotalGB => _storageTotalGB;
  int get recordedHours => _recordedHours;
  int get recordableHours => _recordableHours;
  String get deviceSN => _deviceSN;
  String get deviceToken => _deviceToken;

  /// 电量百分比文案 — 「80%」
  String get batteryText => '${(_batteryLevel * 100).round()}%';

  /// 存储用量文案 — 「3/64 GB」
  String get storageText =>
      '${_trimNumber(_storageUsedGB)}/${_trimNumber(_storageTotalGB)} GB';

  /// 录音时长文案 — 「10/300 H」
  String get recordingHoursText => '$_recordedHours/$_recordableHours H';

  /// 存储用量占比 0~1 (设备储存卡进度条)
  double get storageRatio => _storageTotalGB <= 0
      ? 0
      : (_storageUsedGB / _storageTotalGB).clamp(0.0, 1.0);

  /// 上屏用序列号。未绑定 (无 SN) 时回落到设计稿示例值。
  String get displaySN => _deviceSN.isNotEmpty ? _deviceSN : 'T-2025-7F2A';

  /// 3.0 →「3」, 3.6 → 「3.6」
  static String _trimNumber(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  void updateDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  void setBound(bool state) {
    _isBound = state;
    notifyListeners();
  }

  void toggleIndicator(bool value) {
    _indicatorLight = value;
    notifyListeners();
  }

  void setRecordingMode(String mode) {
    _recordingMode = mode;
    notifyListeners();
  }

  void setForgetReminder(String duration) {
    _forgetReminder = duration;
    notifyListeners();
  }

  void setBattery(double level, {bool? charging}) {
    _batteryLevel = level;
    if (charging != null) _isCharging = charging;
    notifyListeners();
  }

  /// 硬件信息上报回填 (report-info / 蓝牙握手后调用)。
  /// 只覆盖显式传入的字段, 其余保持原值。
  void updateHardwareInfo({
    String? firmwareVersion,
    bool? firmwareUpdatable,
    double? storageUsedGB,
    double? storageTotalGB,
    int? recordedHours,
    int? recordableHours,
  }) {
    if (firmwareVersion != null) _firmwareVersion = firmwareVersion;
    if (firmwareUpdatable != null) _firmwareUpdatable = firmwareUpdatable;
    if (storageUsedGB != null) _storageUsedGB = storageUsedGB;
    if (storageTotalGB != null) _storageTotalGB = storageTotalGB;
    if (recordedHours != null) _recordedHours = recordedHours;
    if (recordableHours != null) _recordableHours = recordableHours;
    notifyListeners();
  }

  /// 调用服务端绑定接口 (POST /sl/app/recording-device/add)
  ///
  /// 成功: 把 SN + deviceToken 写入本模型, 翻转 isBound=true, 同步设备名
  /// 失败: 抛异常, 调用方应 catch 并展示错误 UI
  Future<void> bindDevice({
    required String deviceSN,
    required String deviceName,
  }) async {
    final token = await DeviceApi.instance.addDevice(
      deviceSN: deviceSN,
      deviceName: deviceName,
    );
    _deviceSN = deviceSN;
    _deviceToken = token;
    _deviceName = deviceName;
    _isBound = true;
    AppLogger.i('device bound: $deviceSN, token=${token.length > 8 ? '${token.substring(0, 8)}...' : token}', 'device');
    notifyListeners();
  }

  /// 解绑: 清空 SN / token / isBound
  void clearBinding() {
    _deviceSN = '';
    _deviceToken = '';
    _isBound = false;
    notifyListeners();
  }

  /// 解绑 (真实接口): 调用 POST /sl/app/recording-device/remove 移除设备,
  /// 成功后再清空本地 SN / token / isBound。
  /// 失败会向上抛异常, 调用方应 catch 并保留本地状态以允许用户重试。
  Future<void> unbindDevice({required String deviceSN}) async {
    await DeviceApi.instance.removeDevice(deviceSN: deviceSN);
    _deviceSN = '';
    _deviceToken = '';
    _isBound = false;
    AppLogger.i('device unbound: $deviceSN', 'device');
    notifyListeners();
  }
}
