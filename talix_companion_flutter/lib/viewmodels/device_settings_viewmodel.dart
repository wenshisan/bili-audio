import 'dart:async';
import 'package:flutter/foundation.dart';

// ============================================================
// 设备设置 ViewModel (MVVM)
// 状态: 录音模拟 + UI 显隐 (模式选择下拉 / 详情面板 / 结束确认对话框)
// ============================================================
class DeviceSettingsViewModel extends ChangeNotifier {
  // 录音模拟
  bool _isRecording = false;
  bool get isRecording => _isRecording;
  bool _isPaused = false;
  bool get isPaused => _isPaused;
  int _recordingTime = 0;
  int get recordingTime => _recordingTime;
  Timer? _recordingTimer;

  // UI 显隐状态
  // 模式选择下拉的显隐由 DeviceAnchoredMenu 自行持有 (OverlayPortal),
  // 这里只保留需要跨 widget 协调的结束确认对话框。
  bool _isEndDialogVisible = false; // 结束录音确认对话框
  bool get isEndDialogVisible => _isEndDialogVisible;

  // 设备名
  String _deviceName = 'Talix AI Note';
  String get deviceName => _deviceName;

  /// 本次录音的文件名 — 「新录音2026-07-17」(Figma 669:6646)。
  /// 录音开始时按当天日期生成, 结束后清空。
  String _recordingFileName = '';
  String get recordingFileName => _recordingFileName;

  void setDeviceName(String name) {
    _deviceName = name;
    notifyListeners();
  }

  void startRecording() {
    _isRecording = true;
    _isPaused = false;
    _recordingTime = 0;
    _recordingFileName = _buildRecordingFileName();
    notifyListeners();
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused) {
        _recordingTime++;
        notifyListeners();
      }
    });
  }

  void togglePause() {
    if (!_isRecording) return;
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void stopRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecording = false;
    _isPaused = false;
    _recordingFileName = '';
    notifyListeners();
  }

  /// 结束录音确认对话框 (对齐 Figma 1218:6594)
  void showEndDialog() {
    if (!_isRecording) return;
    _isEndDialogVisible = true;
    notifyListeners();
  }

  void hideEndDialog() {
    if (_isEndDialogVisible) {
      _isEndDialogVisible = false;
      notifyListeners();
    }
  }

  /// 点击结束对话框的"结束"按钮
  void confirmEndRecording() {
    stopRecording();
    _isEndDialogVisible = false;
    notifyListeners();
  }

  /// 「新录音2026-07-17」
  String _buildRecordingFileName() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '新录音${now.year}-$m-$d';
  }

  /// 格式化录音时长 mm:ss
  String formatTime(int secs) {
    final int m = secs ~/ 60;
    final int s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 格式化录音时长 hh:mm:ss (用于详情面板)
  String formatTimeLong(int secs) {
    final int h = secs ~/ 3600;
    final int m = (secs % 3600) ~/ 60;
    final int s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}
