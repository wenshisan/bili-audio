import '../../data/device_item.dart';
import 'base_api_service.dart';

/// 录音卡设备管理 API
///
/// 5 个端点 (来自 power接口需求.csv 第 1 / 2 类):
/// - POST   /sl/app/recording-device/add           绑定录音卡
/// - POST   /sl/app/recording-device/remove        解绑录音卡
/// - POST   /sl/app/recording-device/report-info   设备信息上报 (健康看板)
/// - GET    /sl/app/recording-device/list          查询设备列表
/// - POST   /sl/app/recording-device/update-name   设备重命名
class DeviceApi extends BaseApiService {
  DeviceApi._();
  static final DeviceApi instance = DeviceApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'device-api';

  /// POST /sl/app/recording-device/add
  /// 绑定录音卡, 返回后端下发的 deviceToken (后续指令鉴权用)
  Future<String> addDevice({
    required String deviceSN,
    required String deviceName,
  }) async {
    return post<String>(
      '/sl/app/recording-device/add',
      data: {
        'deviceSN': deviceSN,
        'deviceName': deviceName,
      },
      fromData: (raw) {
        if (raw is Map) {
          return (raw['deviceToken'] ?? '').toString();
        }
        return raw.toString();
      },
    );
  }

  /// POST /sl/app/recording-device/remove
  /// 设备解绑
  Future<void> removeDevice({required String deviceSN}) async {
    await post(
      '/sl/app/recording-device/remove',
      data: {'deviceSN': deviceSN},
    );
  }

  /// POST /sl/app/recording-device/report-info
  /// 设备信息上报 (健康看板):
  /// - deviceStatus: 1=正常 / 2=异常 / 3=低电 (具体枚举待联调确认)
  /// - deviceVersion: 当前固件版本
  /// - deviceStorage: 已用占比 0~1
  Future<void> reportDeviceInfo({
    required String deviceSN,
    required int deviceStatus,
    required String deviceVersion,
    required double deviceStorage,
  }) async {
    await post(
      '/sl/app/recording-device/report-info',
      data: {
        'deviceSN': deviceSN,
        'deviceStatus': deviceStatus,
        'deviceVersion': deviceVersion,
        'deviceStorage': deviceStorage,
      },
    );
  }

  /// GET /sl/app/recording-device/list
  /// 查询设备列表 — 返回 [DeviceItem] 列表
  Future<List<DeviceItem>> getDeviceList() async {
    return get<List<DeviceItem>>(
      '/sl/app/recording-device/list',
      fromData: (raw) {
        final list = (raw is List)
            ? raw
            : (raw is Map && raw['list'] is List ? raw['list'] as List : <dynamic>[]);
        return list
            .whereType<Map>()
            .map((e) => DeviceItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
  }

  /// POST /sl/app/recording-device/update-name
  /// 设备重命名
  Future<void> updateDeviceName({
    required String deviceSN,
    required String deviceName,
  }) async {
    await post(
      '/sl/app/recording-device/update-name',
      data: {
        'deviceSN': deviceSN,
        'deviceName': deviceName,
      },
    );
  }

  /// GET /sl/app/recording-device/firmware?deviceSN=xxx
  /// 查询设备固件升级信息 (CSV 注释:"复用已有接口",此处单独封装便于以后切换为
  /// 独立端点 /sl/app/firmware/get)
  Future<FirmwareInfo> getFirmwareInfo({required String deviceSN}) async {
    return get<FirmwareInfo>(
      '/sl/app/recording-device/firmware',
      query: {'deviceSN': deviceSN},
      fromData: (raw) => FirmwareInfo.fromJson(asMap(raw)),
    );
  }
}
