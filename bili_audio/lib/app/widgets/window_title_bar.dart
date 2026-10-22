import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/l10n.dart';

/// 自定义窗口标题栏 (移植自 talix_companion_flutter，调整为 Material Design 风格)。
///
/// 功能:
/// - 拖拽移动窗口、双击最大化/还原
/// - 最小化、最大化/还原、关闭按钮 (关闭行为: 隐藏到托盘)
/// - 高度 48px
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
    final theme = Theme.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
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
              const SizedBox(width: 16),
              Icon(Icons.music_note, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                context.l10n.appTitle,
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              _WindowControlButton(
                icon: Icons.remove,
                onPressed: () => windowManager.minimize(),
                semanticLabel: '最小化',
              ),
              _WindowControlButton(
                icon: _isMaximized ? Icons.fullscreen_exit : Icons.crop_square,
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
                onPressed: () => windowManager.hide(), // 隐藏到托盘
                hoverColor: const Color(0xFFE81123),
                semanticLabel: '关闭 (隐藏到托盘)',
              ),
            ],
          ),
        ],
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
