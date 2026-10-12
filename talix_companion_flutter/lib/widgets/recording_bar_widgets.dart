import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'device_info_widgets.dart';

// ============================================================
// 录音控件 (设备详情页右上角)
//
// Figma:
//   669:5796  开始录音按钮   — 312×56, #39D03D, 4px 圆角
//   669:6397  禁用态         — 同尺寸, #CCCCCC (设备离线)
//   669:6635  录音中状态栏   — 波形 + 时长 + 文件名 + 播放/停止/标记
// ============================================================

/// 开始录音按钮 (Figma 669:5796 / 禁用态 669:6397)。
///
/// 312×56, padding 12/16, 左侧 ic_record 24×24 + 8px + 「开始录音」,
/// 右侧 16×16 白色 caret。[onTap] 为 null 时按 #CCCCCC 渲染 (设备离线)。
class StartRecordingButton extends StatelessWidget {
  /// 点击左侧主区: 开始录音。null → 禁用态。
  final VoidCallback? onTap;

  /// 点击右侧 caret: 展开录音模式选择。null → 不响应。
  final VoidCallback? onCaretTap;

  const StartRecordingButton({super.key, this.onTap, this.onCaretTap});

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 312,
      height: 56,
      decoration: BoxDecoration(
        color: _enabled ? AppColors.primary : AppColors.neutralFill,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            // 左侧: 图标 + 文案 (点击直接开始录音)
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/ic_record.svg',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text('开始录音', style: DeviceInfoText.buttonLabel),
                    ],
                  ),
                ),
              ),
            ),
            // 右侧: caret (仅展开模式选择, 不开始录音)
            InkWell(
              onTap: onCaretTap,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: Container(
                width: 48,
                height: 56,
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/ic_caret_white.svg',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 录音中状态栏 (Figma 669:6635)。
///
/// #39D03D 底 + 4px 圆角, padding 9/16。
/// 左: 32×32 波形 + 8px + (时长 14px Semibold / 文件名 12px);
/// 右: 播放 32 + 24px + 停止 32 + 16px + 1×24 分隔 + 标记 24 + caret 16。
class RecordingStatusBar extends StatelessWidget {
  /// 已录制时长, 形如 `00:12:34`。
  final String elapsedText;

  /// 录音文件名, 形如 `新录音2026-07-17`。
  final String fileName;

  /// 当前是否处于暂停态 (决定播放/暂停图标)。
  final bool isPaused;

  final VoidCallback? onTogglePause;
  final VoidCallback? onStop;
  final VoidCallback? onMark;
  final VoidCallback? onCaretTap;

  const RecordingStatusBar({
    super.key,
    required this.elapsedText,
    required this.fileName,
    this.isPaused = false,
    this.onTogglePause,
    this.onStop,
    this.onMark,
    this.onCaretTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _VoiceLineIcon(),
            const SizedBox(width: 8),
            // 时长 + 文件名
            SizedBox(
              width: 106,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    elapsedText,
                    style: DeviceInfoText.buttonLabel.copyWith(height: 18 / 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DeviceInfoText.rowSubtitle
                        .copyWith(color: AppColors.textOnPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 85),
            // 播放/暂停 + 停止
            _CircleIconButton(
              asset: 'assets/images/btn_play.svg',
              tooltip: isPaused ? '继续录音' : '暂停录音',
              onTap: onTogglePause,
            ),
            const SizedBox(width: 24),
            _CircleIconButton(
              asset: 'assets/images/btn_stop.svg',
              tooltip: '结束录音',
              onTap: onStop,
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 16),
            // 标记
            InkWell(
              onTap: onMark,
              borderRadius: BorderRadius.circular(4),
              child: Tooltip(
                message: '标记',
                child: SvgPicture.asset(
                  'assets/images/ic_flag.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textOnPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: onCaretTap,
              borderRadius: BorderRadius.circular(4),
              child: SvgPicture.asset(
                'assets/images/ic_caret_white.svg',
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 32×32 半透明圆形按钮 (Figma btn_play 669:6649 / btn_stop 669:6653)。
class _CircleIconButton extends StatelessWidget {
  final String asset;
  final String tooltip;
  final VoidCallback? onTap;

  const _CircleIconButton({
    required this.asset,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Tooltip(
        message: tooltip,
        child: SvgPicture.asset(asset, width: 32, height: 32),
      ),
    );
  }
}

/// 波形图标 (Figma ic_voice line 669:6637)。
///
/// 32×32 容器内 6 根 2px 宽竖条, 高度 14/18/24/28/20/12, 间距 3,
/// 透明度 0.3 / 0.5 / 0.8 / 1 / 1 / 0.3。
class _VoiceLineIcon extends StatelessWidget {
  const _VoiceLineIcon();

  static const List<(double, double)> _bars = [
    (14, 0.3),
    (18, 0.5),
    (24, 0.8),
    (28, 1.0),
    (20, 1.0),
    (12, 0.3),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < _bars.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 2,
              height: _bars[i].$1,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _bars[i].$2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
