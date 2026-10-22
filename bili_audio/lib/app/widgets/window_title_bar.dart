import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../providers.dart';

/// 自定义窗口标题栏 (移植自 talix_companion_flutter，调整为 Material Design 风格)。
///
/// 功能:
/// - 拖拽移动窗口、双击最大化/还原
/// - 最小化、最大化/还原、关闭按钮 (关闭行为: 隐藏到托盘)
/// - 正在播放时显示上一首 / 播放 / 下一首，窗口化时也不会被底部区域裁掉
/// - 高度 48px
class WindowTitleBar extends ConsumerStatefulWidget {
  const WindowTitleBar({super.key});

  @override
  ConsumerState<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends ConsumerState<WindowTitleBar>
    with WindowListener {
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
    final item = ref.watch(mediaItemProvider).value;
    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;
    final handler = ref.read(audioHandlerProvider);
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
              Expanded(
                child: Text(
                  '哔哩哔哩音频播放器',
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item != null) ...[
                _TransportButton(
                  icon: Icons.skip_previous,
                  tooltip: '上一首',
                  onPressed: handler.skipToPrevious,
                ),
                _TransportButton(
                  icon: playing ? Icons.pause : Icons.play_arrow,
                  tooltip: playing ? '暂停' : '播放',
                  onPressed: playing ? handler.pause : handler.play,
                ),
                _TransportButton(
                  icon: Icons.skip_next,
                  tooltip: '下一首',
                  onPressed: handler.skipToNext,
                ),
              ],
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

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // 标题栏在 Navigator 之外，没有 Overlay，不能用带 Tooltip 的 IconButton。
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
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
