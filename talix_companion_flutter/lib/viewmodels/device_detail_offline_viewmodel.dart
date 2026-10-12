import '../data/device_item.dart';

// ============================================================
// 设备详情 (离线) ViewModel (MVVM)
// 状态: 设备基础信息 (从传入的 [DeviceItem] 派生,无 fake 数据)
// ============================================================
class DeviceDetailOfflineViewModel {
  final String deviceName;
  final String deviceSerial;
  final String firmwareVersion;

  DeviceDetailOfflineViewModel({
    required this.deviceName,
    required this.deviceSerial,
    required this.firmwareVersion,
  });

  /// 工厂:从 [DeviceItem] 派生 (推荐用法 — 设备列表点击离线设备时调用)
  factory DeviceDetailOfflineViewModel.fromDevice(DeviceItem device) {
    return DeviceDetailOfflineViewModel(
      deviceName: device.name,
      deviceSerial: device.serialNumber,
      // 固件版本由设备列表接口返回的字段 (如未来加 firmwareVersion 字段) 决定;
      // 当前 DeviceItem 没有该字段,先用空串,后续可由 device/list 扩展返回
      firmwareVersion: '',
    );
  }
}
