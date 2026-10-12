import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import '../desktop/float_window_controller.dart' show hideMainWindow;
import '../screens/auth/auth_assets.dart';

/// Custom window title bar matching the Figma design (node-id 669:4658).
///
/// Specs:
/// - Height: 48px
/// - Background: #F2F2F2
/// - Bottom border: 1px rgba(0,0,0,0.1)
/// - Left: Talix logo SVG 56×12, left padding 22px, vertically centered
/// - Right: window control buttons (minimize / maximize / close)
class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F2),
        border: Border(
          bottom: BorderSide(color: Color(0x1A000000), width: 1), // rgba(0,0,0,0.1)
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      // Stack: 下层拖拽/双击 + 上层可见内容（解耦 gesture arena）
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
          // 上层: 品牌 logo + 窗口控制按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧: Talix logo 56×12, 左边距 22px (Figma brand logo @ x=22)
              const SizedBox(width: 22),
              SvgPicture.string(
                AuthAssets.talixLogo,
                width: 56,
                height: 12,
                fit: BoxFit.contain,
              ),
              // 占满中间剩余区域（可拖拽）
              const Spacer(),
              // 右侧: 窗口控制按钮 (minimize / maximize / close)
              _WindowControlButton(
                icon: Icons.remove,
                onPressed: () => windowManager.minimize(),
                semanticLabel: 'Minimize',
              ),
              _WindowControlButton(
                icon: _isMaximized
                    ? Icons.fullscreen_exit_rounded
                    : Icons.crop_square_rounded,
                onPressed: () {
                  if (_isMaximized) {
                    setState(() => _isMaximized = false);
                    windowManager.unmaximize();
                  } else {
                    setState(() => _isMaximized = true);
                    windowManager.maximize();
                  }
                },
                semanticLabel: _isMaximized ? 'Restore' : 'Maximize',
              ),
              _WindowControlButton(
                icon: Icons.close_rounded,
                onPressed: () => hideMainWindow(),
                hoverColor: const Color(0xFFE81123),
                semanticLabel: 'Close (minimize to tray)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 控制按钮: 48×48 可点击区域，悬停时显示背景色
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
    final Color iconColor =
        _hovered && widget.hoverColor != null ? Colors.white : const Color(0xFF333333);
    final Color bg =
        _hovered ? (widget.hoverColor ?? const Color(0xFFE5E7EB)) : Colors.transparent;

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
            width: 48,
            height: 48,
            alignment: Alignment.center,
            color: bg,
            child: Icon(widget.icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}

