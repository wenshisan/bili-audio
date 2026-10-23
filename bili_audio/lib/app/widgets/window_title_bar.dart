import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/l10n.dart';
import 'region_surface.dart';

/// 自定义窗口标题栏。
///
/// 拖拽移动窗口，双击最大化或还原，高度 48px。
/// Windows / Linux 在左侧放 logo 与标题，右侧放最小化、最大化、关闭
/// （关闭为隐藏到托盘）。macOS 使用系统红绿灯，不画这组按钮，logo 与标题靠右。
class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({super.key, this.nativeWindowButtons});

  /// 为 null 时按平台决定：macOS 为 true。
  final bool? nativeWindowButtons;

  /// 标题栏高度。
  static const double barHeight = 48;

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (mounted && maximized != _isMaximized) {
      setState(() => _isMaximized = maximized);
    }
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  bool get _nativeWindowButtons =>
      widget.nativeWindowButtons ?? (!kIsWeb && Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nativeButtons = _nativeWindowButtons;
    final brand = <Widget>[
      Icon(Icons.music_note, size: 20, color: theme.colorScheme.primary),
      const SizedBox(width: 8),
      Text(context.l10n.appTitle, style: theme.textTheme.titleSmall),
    ];
    return RegionSurface(
      edge: RegionEdge.bottom,
      extent: 6,
      child: SizedBox(
        height: WindowTitleBar.barHeight,
        child: Stack(
          children: [
            // 下层: 拖拽和双击最大化
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => windowManager.startDragging(),
                onDoubleTap: () {
                  if (_isMaximized) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
              ),
            ),
            // 上层: 标题 + 窗口控制按钮
            Row(
              children: [
                if (!nativeButtons) ...[const SizedBox(width: 16), ...brand],
                const Spacer(),
                if (nativeButtons) ...[
                  ...brand,
                  const SizedBox(width: 16),
                ] else ...[
                  _WindowControlButton(
                    icon: Icons.remove,
                    onPressed: () => windowManager.minimize(),
                    semanticLabel: '最小化',
                  ),
                  _WindowControlButton(
                    icon: _isMaximized
                        ? Icons.fullscreen_exit
                        : Icons.crop_square,
                    onPressed: () {
                      if (_isMaximized) {
                        windowManager.unmaximize();
                      } else {
                        windowManager.maximize();
                      }
                    },
                    semanticLabel: _isMaximized ? '还原' : '最大化',
                  ),
                  _WindowControlButton(
                    icon: Icons.close,
                    onPressed: () => windowManager.hide(),
                    hoverColor: const Color(0xFFE81123),
                    semanticLabel: '关闭 (隐藏到托盘)',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  const _WindowControlButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.hoverColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color? hoverColor;

  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _hovered && widget.hoverColor != null
        ? Colors.white
        : theme.colorScheme.onSurface;
    final bg = _hovered
        ? (widget.hoverColor ?? theme.colorScheme.surfaceContainerHighest)
        : Colors.transparent;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            width: WindowTitleBar.barHeight,
            height: WindowTitleBar.barHeight,
            alignment: Alignment.center,
            color: bg,
            child: Icon(widget.icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}
