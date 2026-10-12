import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/device_item.dart';
import '../theme/app_colors.dart';
import '../viewmodels/device_model.dart';
import '../viewmodels/device_detail_offline_viewmodel.dart';
import '../widgets/device_info_widgets.dart';
import '../widgets/recording_bar_widgets.dart';
import 'binding_screens.dart';

// ============================================================
// 设备详情 — 离线 (Figma 669:6303)
//
// 与已连接态 (device_settings.dart) 同一版式, 差异:
//   - 信息卡只有 设备名称 / 序列号 / 固件版本 三行, 且都不可点
//     (离线读不到电量、存储、录音时长, 也不能改名或查固件更新)
//   - 「开始录音」按钮为 #CCCCCC 禁用态
//   - 没有录音设置 / 指示灯 / 文件管理卡, 只保留「解绑并重置」
// ============================================================
class DeviceDetailOfflineScreen extends StatelessWidget {
  final DeviceItem device;

  const DeviceDetailOfflineScreen({
    super.key,
    required this.device,
  });

  static const double _contentWidth = 800;

  @override
  Widget build(BuildContext context) {
    final viewModel = DeviceDetailOfflineViewModel.fromDevice(device);
    final model = Provider.of<DeviceModel>(context, listen: false);
    final bool isPcMode = MediaQuery.of(context).size.width >= 750;

    if (!isPcMode) {
      return _buildMobileLayout(context, viewModel, model);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: _contentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (Navigator.canPop(context)) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildBackButton(context),
                    ),
                  ],

                  // Header: 设备名 ⟷ 禁用的开始录音按钮 (Figma 669:6397)
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          viewModel.deviceName,
                          style: DeviceInfoText.pageTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // onTap 为 null → 灰底禁用态; 设备离线无法开始录音
                      const Tooltip(
                        message: '设备未连接，无法开始录音',
                        child: StartRecordingButton(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),

                  // 信息卡 (Figma 669:6406): 三行只读信息
                  DeviceInfoCard(
                    children: [
                      DeviceInfoRow(
                        label: '设备名称',
                        trailing: DeviceRowValue(value: viewModel.deviceName),
                      ),
                      DeviceInfoRow(
                        label: '序列号',
                        trailing: DeviceRowValue(value: viewModel.deviceSerial),
                      ),
                      DeviceInfoRow(
                        label: '固件版本',
                        trailing: DeviceRowValue(
                          value: viewModel.firmwareVersion.isEmpty
                              ? '--'
                              : viewModel.firmwareVersion,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 解绑并重置 (Figma 669:6390)
                  DeviceInfoCard(
                    children: [
                      DeviceInfoRow(
                        label: '解绑并重置',
                        isDanger: true,
                        onTap: () => _triggerUnbind(context, model),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios, size: 14, color: AppColors.textPrimary),
              SizedBox(width: 4),
              Text('返回', style: DeviceInfoText.rowLabel),
            ],
          ),
        ),
      ),
    );
  }

  /// 解绑并重置 — 与已连接态共用 [UnbindingHandler] 流程。
  /// 离线设备卡内没有未同步录音的判断依据, hasUnsynced 传 false。
  ///
  /// 走真实接口 [DeviceModel.unbindDevice] (POST /sl/app/recording-device/remove),
  /// 成功后清空本地 deviceSN/token/isBound 并发出 notifyListeners;
  /// 设备列表页监听到 isBound 变化会自动 refresh() 重新拉取, 该设备随即从列表消失。
  void _triggerUnbind(BuildContext context, DeviceModel model) {
    UnbindingHandler.triggerUnbindFlow(context, false, () async {
      await model.unbindDevice(deviceSN: device.serialNumber);
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  // ============================================================
  // 移动端布局: 同样的三行信息 + 解绑, 带 AppBar
  // ============================================================
  Widget _buildMobileLayout(
    BuildContext context,
    DeviceDetailOfflineViewModel viewModel,
    DeviceModel model,
  ) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: AppColors.textPrimary, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        centerTitle: true,
        title: Text(viewModel.deviceName, style: DeviceInfoText.rowLabel),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DeviceInfoCard(
            children: [
              DeviceInfoRow(
                label: '设备名称',
                trailing: DeviceRowValue(value: viewModel.deviceName),
              ),
              DeviceInfoRow(
                label: '序列号',
                trailing: DeviceRowValue(value: viewModel.deviceSerial),
              ),
              DeviceInfoRow(
                label: '固件版本',
                trailing: DeviceRowValue(
                  value: viewModel.firmwareVersion.isEmpty
                      ? '--'
                      : viewModel.firmwareVersion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DeviceInfoCard(
            children: [
              DeviceInfoRow(
                label: '解绑并重置',
                isDanger: true,
                onTap: () => _triggerUnbind(context, model),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
