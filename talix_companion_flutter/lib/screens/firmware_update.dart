import 'package:flutter/material.dart';
import '../viewmodels/firmware_update_viewmodel.dart';
import '../widgets/file_list_widgets.dart';

// ============================================================
// 固件升级页 (Figma 弹窗样式)
// 状态: ready | upgrading | success | failure | upToDate
// 所有弹窗尺寸: 480x260, 8px 圆角, 阴影 0 4 4 rgba(0,0,0,0.25)
// 标题 18px Bold #18181B, 关闭 icon 16x16 (upgrading 无)
// 正文: ready/upgrading 14px #6B7280 lh 2.0 / 其他 12-14px #262626
// 底部按钮: 取消 (白底 1px #D1D5DB 描边) + 主按钮 (#18181B 填充, 6px 圆角)
//   ready: 取消 + 升级 (居中, 主按钮 hug)
//   success: 取消 + 完成 (右对齐, 主按钮 119 宽)
//   failure: 取消 + 立即更新 (右对齐, 主按钮 119 宽)
//   upToDate: 仅 知道了 (右对齐, 119 宽)
//   upgrading: 无
// ============================================================
class FirmwareUpdateScreen extends StatefulWidget {
  final double currentBattery;
  final String deviceSN;
  const FirmwareUpdateScreen({
    super.key,
    required this.currentBattery,
    required this.deviceSN,
  });

  @override
  State<FirmwareUpdateScreen> createState() => _FirmwareUpdateScreenState();
}

class _FirmwareUpdateScreenState extends State<FirmwareUpdateScreen> {
  late final FirmwareUpdateViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FirmwareUpdateViewModel(
      currentBattery: widget.currentBattery,
      deviceSN: widget.deviceSN,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // 半透明黑色背景 (Figma backdrop)
          const Positioned.fill(
            child: ColoredBox(color: Color(0x80000000)),
          ),
          // 居中弹窗卡片
          Center(child: _buildModalCard()),
        ],
      ),
    );
  }

  Widget _buildModalCard() {
    return Container(
      width: 480,
      height: 260,
      decoration: BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(child: _buildStateContent()),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // 标题映射
  String _titleFor(String status) {
    switch (status) {
      case 'ready':
        return '固件更新';
      case 'upgrading':
        return '正在更新固件';
      case 'success':
        return '更新完成';
      case 'failure':
        return '更新失败';
      case 'upToDate':
        return '最新版本';
      default:
        return '固件更新';
    }
  }

  // upgrading (Figma 1218:4983) 标题左侧无关闭 icon
  // 其他状态 标题居中 + 右侧关闭 icon
  Widget _buildHeader() {
    final status = _viewModel.status;
    final isUpgrading = status == 'upgrading';
    if (isUpgrading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 28, 40, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _titleFor(status),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
              height: 1.33,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 28, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _titleFor(status),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
                height: 1.33,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent() {
    final status = _viewModel.status;
    switch (status) {
      case 'ready':
        return _buildReadyState();
      case 'upgrading':
        return _buildUpgradingState();
      case 'success':
        return _buildSimpleState('录音卡固件已升级至最新版本v${_viewModel.firmware.version}');
      case 'failure':
        return _buildSimpleState('连接中断，请尝试重启设备或重新配置网络');
      case 'upToDate':
        return _buildUpToDateState();
      default:
        return _buildReadyState();
    }
  }

  // Figma 1218:5028 ready 状态
  // 短消息 + 2 行 release notes, 14px #6B7280 lh 2.0
  Widget _buildReadyState() {
    final fw = _viewModel.firmware;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '有新的固件版本（${fw.version}）可用，建议立即更新',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              height: 2.0,
            ),
          ),
          ...fw.releaseNotes.take(2).map((note) => Padding(
                padding: const EdgeInsets.only(top: 0, left: 12),
                child: Text(
                  note,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                    height: 2.0,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Figma 1218:4980 upgrading 状态
  // 2 行文字: 进度行 + 注意事项行, 14px #6B7280 lh 2.0
  Widget _buildUpgradingState() {
    final progress = (_viewModel.progress * 100).toInt();
    final seconds = _viewModel.secondsLeft;
    final timeText = seconds >= 60
        ? '${(seconds / 60).round()}分钟'
        : '$seconds秒';
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '下载固件安装包 $progress% 剩余$timeText',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              height: 2.0,
            ),
          ),
          const Text(
            '请保持蓝牙连接，且升级期间不可以录音，升级过程中请不要退出应用',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              height: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  // Figma 1218:5056 / 1218:5070 success / failure 共享的单行简短正文
  // 12px Regular #262626, lh 20
  Widget _buildSimpleState(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: FigmaTokens.primary,
            height: 20 / 12,
          ),
        ),
      ),
    );
  }

  // Figma 1218:5084 upToDate 状态
  // 14px Regular #262626, lh 20
  Widget _buildUpToDateState() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(40, 0, 40, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '您的Talix AI Note已是最新版本',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: FigmaTokens.primary,
            height: 20 / 14,
          ),
        ),
      ),
    );
  }

  // 底部按钮 (按状态分发)
  Widget _buildBottomActions() {
    final status = _viewModel.status;
    switch (status) {
      case 'ready':
        // Figma 1218:5036 center 取消 + 升级 (主按钮 hug)
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _outlineButton('取消', () => Navigator.pop(context)),
              const SizedBox(width: 12),
              _filledButton(
                '升级',
                width: null,
                onTap: _viewModel.startUpgrade,
              ),
            ],
          ),
        );
      case 'success':
        // Figma 1218:5064 flex-end 取消 + 完成 (主按钮 119 宽)
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _outlineButton('取消', () => Navigator.pop(context)),
              const SizedBox(width: 12),
              _filledButton(
                '完成',
                width: 119,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      case 'failure':
        // Figma 1218:5078 flex-end 取消 + 立即更新 (主按钮 119 宽)
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _outlineButton('取消', () => Navigator.pop(context)),
              const SizedBox(width: 12),
              _filledButton(
                '立即更新',
                width: 119,
                onTap: _viewModel.retryUpgrade,
              ),
            ],
          ),
        );
      case 'upToDate':
        // Figma 1218:5092 flex-end 仅 知道了 (119 宽)
        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _filledButton(
                '知道了',
                width: 119,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      case 'upgrading':
      default:
        return const SizedBox.shrink();
    }
  }

  // 描边按钮: 白底 + 1px #D1D5DB, 6px 圆角, hug 宽
  Widget _outlineButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: FigmaTokens.surfaceWhite,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF18181B),
            height: 1.43,
          ),
        ),
      ),
    );
  }

  // 填充按钮: #18181B 填充, 6px 圆角
  // width: null = hug, 否则固定宽度
  Widget _filledButton(
    String label, {
    required double? width,
    required VoidCallback onTap,
  }) {
    final child = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: FigmaTokens.surfaceWhite,
            height: 1.43,
          ),
        ),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
