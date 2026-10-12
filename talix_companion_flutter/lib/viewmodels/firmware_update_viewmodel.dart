import 'dart:async';
import '../data/device_item.dart';
import '../services/api/device_api.dart';
import '../utils/app_logger.dart';
import '../utils/safe_change_notifier.dart';

// ============================================================
// 固件升级 ViewModel (MVVM)
// 状态: status + progress + secondsLeft + timer
// status: 'ready' | 'upgrading' | 'success' | 'failure' | 'upToDate'
//
// 固件信息从 DeviceApi.getFirmwareInfo 真实拉取;加载失败时使用空版本,
// UI 显示"已是最新"状态(由 isUpToDate 判定)。
//
// 继承 SafeChangeNotifier: Timer.periodic 每秒调 notifyListeners() 推进度条,
// 用户离开屏幕 → State.dispose() → ViewModel.dispose() (取消 timer) →
// 偶发情况下 timer 已 schedule 的回调在 cancel 与 super.dispose 之间执行,
// 基类的 disposed 守护会让 notifyListeners() no-op,避免闪退。
// ============================================================
class FirmwareUpdateViewModel extends SafeChangeNotifier {
  final double currentBattery;
  final String deviceSN;
  final DeviceApi _api = DeviceApi.instance;

  String _status = 'ready';
  String get status => _status;

  double _progress = 0.0;
  double get progress => _progress;

  int _secondsLeft = 30;
  int get secondsLeft => _secondsLeft;

  Timer? _timer;

  /// 固件信息。初始为占位空值, [loadFirmware] 成功后填充。
  FirmwareInfo _firmware = const FirmwareInfo(
    version: '',
    packageSizeText: '',
    estimatedTimeText: '',
    releaseNotes: [],
    estimatedSeconds: 30,
  );
  FirmwareInfo get firmware => _firmware;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  FirmwareUpdateViewModel({
    required this.currentBattery,
    required this.deviceSN,
  }) {
    loadFirmware();
  }

  bool get isBatteryLow => currentBattery < 0.3;

  /// 拉取固件信息
  ///
  /// 拉取成功:更新 _firmware,若 version 与"已安装"版本一致则切到 upToDate
  /// 拉取失败:保持 ready 状态,_error 设置为错误消息
  /// (是否已是最新由调用方根据业务约定传入 currentInstalledVersion,
  ///  此处若 version 为空则不切换到 upToDate,以免误判)
  Future<void> loadFirmware() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final info = await _api.getFirmwareInfo(deviceSN: deviceSN);
      _firmware = info;
      _secondsLeft = info.estimatedSeconds;
      // 空版本:后端暂无可升级固件,切到 upToDate
      if (info.version.isEmpty) {
        _status = 'upToDate';
      }
    } catch (e, st) {
      AppLogger.e('firmware load failed: $deviceSN', 'firmware', e, st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void startUpgrade() {
    if (isBatteryLow) return;
    _status = 'upgrading';
    _progress = 0.0;
    _secondsLeft = _firmware.estimatedSeconds;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _progress += 1 / (_firmware.estimatedSeconds <= 0 ? 30 : _firmware.estimatedSeconds);
      _secondsLeft--;
      if (_progress >= 1.0) {
        _progress = 1.0;
        _status = 'success';
        _timer?.cancel();
      }
      notifyListeners();
    });
  }

  void retry() {
    _status = 'ready';
    _progress = 0.0;
    _secondsLeft = _firmware.estimatedSeconds;
    notifyListeners();
  }

  // 重试升级: 直接重新启动 (用于 failure -> 立即更新)
  void retryUpgrade() {
    startUpgrade();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
