import 'package:flutter/material.dart';

import 'common/common.dart';

// ============================================================
// 共享样式常量
// ============================================================
class FigmaTokens {
  // 颜色
  static const Color primary = Color(0xFF262626);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF737373);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textMuted = Color(0xFFA1A1A1);
  static const Color textFaint = Color(0xFF999999);
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderStrong = Color(0xFFD1D1D1);
  static const Color iconPlaceholder = Color(0xFFD9D9D9);
  static const Color highlight = Color(0xFFEEEEEE);
  static const Color fieldBg = Color(0xFFF9FAFB);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color accent = Color(0xFF10B981);

  // 状态徽标颜色
  static const Color statusTranscribingBg = Color(0xFFFFF7ED);
  static const Color statusTranscribingFg = Color(0xFFF97316);
  static const Color statusCompletedBg = Color(0xFFECFDF5);
  static const Color statusCompletedFg = Color(0xFF10B981);
  static const Color statusFailedBg = Color(0xFFFEF2F2);
  static const Color statusFailedFg = Color(0xFFEF4444);
  static const Color statusWaitingBg = Color(0xFFF3F4F6);
  static const Color statusWaitingFg = Color(0xFF6B7280);
}

// ============================================================
// 工具: toast 提示
// ============================================================
void showFileListToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 12)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ============================================================
// 状态徽标 (Figma 1218:5609 status badge)
//   - 'transcribing': 转写中 (橙)
//   - 'completed': 已完成 (绿)
//   - 'failed': 失败 (红)
//   - 'waiting' / 'synced': 等待同步 (灰)
//   - 'pending' (Figma 1218:6792): 未生成 (灰, 与 waiting 同色但文案不同)
// ============================================================
class StatusBadge extends StatelessWidget {
  final String
      status; // 'transcribing' | 'completed' | 'failed' | 'waiting' | 'synced' | 'pending'
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 10, color: config.fg),
          const SizedBox(width: 3),
          Text(
            config.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: config.fg,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _config(String s) {
    switch (s) {
      case 'transcribing':
        return _StatusConfig(
          label: '转写中',
          icon: Icons.hourglass_top_rounded,
          bg: FigmaTokens.statusTranscribingBg,
          fg: FigmaTokens.statusTranscribingFg,
        );
      case 'failed':
        return _StatusConfig(
          label: '失败',
          icon: Icons.error_outline_rounded,
          bg: FigmaTokens.statusFailedBg,
          fg: FigmaTokens.statusFailedFg,
        );
      case 'pending':
        return _StatusConfig(
          label: '未生成',
          icon: Icons.auto_awesome_outlined,
          bg: FigmaTokens.statusWaitingBg,
          fg: FigmaTokens.statusWaitingFg,
        );
      case 'waiting':
      case 'synced':
        return _StatusConfig(
          label: '等待同步',
          icon: Icons.cloud_queue_rounded,
          bg: FigmaTokens.statusWaitingBg,
          fg: FigmaTokens.statusWaitingFg,
        );
      case 'completed':
      default:
        return _StatusConfig(
          label: '已完成',
          icon: Icons.check_circle_rounded,
          bg: FigmaTokens.statusCompletedBg,
          fg: FigmaTokens.statusCompletedFg,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  _StatusConfig(
      {required this.label,
      required this.icon,
      required this.bg,
      required this.fg});
}

// ============================================================
// 来源 chip (设备/手机)
// ============================================================
class SourceChip extends StatelessWidget {
  final String label;
  const SourceChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
          height: 1.0,
        ),
      ),
    );
  }
}

// ============================================================
// 搜索框
// ============================================================
class FileSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const FileSearchField(
      {super.key, required this.controller, required this.onChanged});

  @override
  State<FileSearchField> createState() => _FileSearchFieldState();
}

class _FileSearchFieldState extends State<FileSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FigmaTokens.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              size: 14, color: FigmaTokens.textFaint),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              style:
                  const TextStyle(fontSize: 11, color: FigmaTokens.textPrimary),
              decoration: const InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
                border: InputBorder.none,
                hintText: '搜索文件标题',
                hintStyle:
                    TextStyle(fontSize: 11, color: FigmaTokens.textMuted),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onChanged('');
              },
              child: const Icon(Icons.close_rounded,
                  size: 12, color: FigmaTokens.textFaint),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// 子标签筛选 chips (Figma 1218:5609 子标签区)
// 'all' | 'pending' (Figma 1218:6792 未生成) | 'transcribing' | 'completed' | 'failed'
// ============================================================
class SubTabFilterChips extends StatelessWidget {
  final String active;
  final ValueChanged<String> onChanged;
  const SubTabFilterChips(
      {super.key, required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      {'key': 'all', 'label': '全部'},
      {'key': 'pending', 'label': '未生成'},
      {'key': 'transcribing', 'label': '转写中'},
      {'key': 'completed', 'label': '已完成'},
      {'key': 'failed', 'label': '失败'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((it) {
          final isActive = active == it['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onChanged(it['key']!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? FigmaTokens.primary : Colors.white,
                  border: Border.all(
                    color: isActive ? FigmaTokens.primary : FigmaTokens.border,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  it['label']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? Colors.white : FigmaTokens.textSecondary,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// 选中操作栏 (Figma 1218:5609 sync-banner 1218:5669)
// 高度 51px, 白色背景, 1px #D1D1D1 底边
// 左侧: "已选中（X/Y）" 12px #737373
// 右侧: "移至回收站" 12px + "取消" 12px
// ============================================================
class FileSelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  const FileSelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      padding: const EdgeInsets.symmetric(horizontal: 19),
      decoration: const BoxDecoration(
        color: FigmaTokens.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: FigmaTokens.borderStrong, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 左侧: 已选中 (X/Y)
          Text(
            '已选中（$selectedCount/$totalCount）',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 13.5 / 12,
              letterSpacing: 0.0139,
              fontWeight: FontWeight.w400,
              color: FigmaTokens.textSecondary,
            ),
          ),
          const Spacer(),
          // 右侧: 移至回收站
          InkWell(
            onTap: selectedCount > 0 ? onDelete : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                '移至回收站',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 13.5 / 12,
                  letterSpacing: 0.0139,
                  fontWeight: FontWeight.w400,
                  color: selectedCount > 0
                      ? FigmaTokens.textSecondary
                      : FigmaTokens.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // 右侧: 取消
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                '取消',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 13.5 / 12,
                  letterSpacing: 0.0139,
                  fontWeight: FontWeight.w400,
                  color: FigmaTokens.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 截断文本 + Hover Tooltip (Figma 1218:5479 #1239:11267)
// 当文本被截断 (TextOverflow.ellipsis) 时, hover 显示完整内容
// Tooltip 样式 (Figma):
//   - 背景: #FFFFFF
//   - 边框: 1px #CACACA, 8px 圆角
//   - 内边距: 16px horizontal, 8px vertical
//   - 文字: 15px Inter Regular #333333 (与标题一致)
// 位置: 标题下方 (preferBelow=true, 默认行为)
// ============================================================
class TruncatedTextWithTooltip extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;

  const TruncatedTextWithTooltip({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
  });

  @override
  State<TruncatedTextWithTooltip> createState() => _TruncatedTextWithTooltipState();
}

class _TruncatedTextWithTooltipState extends State<TruncatedTextWithTooltip> {
  final GlobalKey _textKey = GlobalKey();
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    // 第一次布局后检测文本是否被截断
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());

    final textWidget = Text(
      widget.text,
      key: _textKey,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );

    if (!_isOverflowing) {
      return textWidget;
    }

    return Tooltip(
      message: widget.text,
      preferBelow: true,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCACACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF333333),
      ),
      waitDuration: const Duration(milliseconds: 300),
      child: textWidget,
    );
  }

  // 使用 TextPainter 检测实际可用宽度下文本是否被截断
  // 仅在状态变化时 setState, 避免无限重建
  void _checkOverflow() {
    if (!mounted) return;
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final size = renderObject.size;
    if (size.width <= 0) return;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final isOverflowing = textPainter.didExceedMaxLines;
    textPainter.dispose();
    if (isOverflowing != _isOverflowing) {
      setState(() {
        _isOverflowing = isOverflowing;
      });
    }
  }
}

// ============================================================
// 文件列表项 (Figma 1218:5609 - record-item 1218:5675)
// 严格对齐 UX 规范:
//   - 容器高度 71px (Figma 1218:5675 layout_4b4cc057)
//   - 标题 15px / #333333 (Figma style_02d97395)
//   - 元信息 12px / #A1A1A1 (Figma style_c487cf45)
//   - 元信息格式: "{date} · {duration}" (完成态) / "{date} · {statusText}" (转写/同步态)
//   - 选中态右侧 6x6 #262626 圆点指示器 (Figma 1218:5724)
//   - 同步态显示本地图标 icon-park-outline:local (Figma 1218:5685)
//   - Hover 态显示 16x16 #D9D9D9 占位复选框 (Figma 1218:5315/5322/5339)
//     点击占位框直接进入编辑模式并选中该文件
// ============================================================
class FileListItem extends StatefulWidget {
  final String id;
  final String title;
  final String dateText; // "今天 21:22" / "5月6日 09:22"
  final String? duration; // "25分钟" / "56分钟" / "136分钟" - 完成态显示
  final String? statusText; // "正在转写" / "正在同步至手机" / "等待同步至手机" - 状态文本
  final String? sourceLabel; // '设备' | '手机' (仅 all 视图显示)
  final bool isEditing;
  final bool isSelected;
  final bool isHighlighted; // 右侧详情面板中正在展示
  final bool dimmed; // 搜索时未命中的项
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;
  final VoidCallback onMore;

  const FileListItem({
    super.key,
    required this.id,
    required this.title,
    required this.dateText,
    this.duration,
    this.statusText,
    this.sourceLabel,
    required this.isEditing,
    required this.isSelected,
    required this.isHighlighted,
    required this.dimmed,
    required this.onTap,
    required this.onToggleSelect,
    required this.onMore,
  });

  @override
  State<FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<FileListItem> {
  // Figma 1218:5315/5322/5339: hover 时显示 16x16 #D9D9D9 占位复选框
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 复选框可见条件: 编辑模式 或 hover (非编辑模式)
    final showCheckbox = widget.isEditing || _isHovered;
    // 复选框样式: 编辑模式为实色 + 边框, hover 为 #D9D9D9 占位
    final checkboxIsEditing = widget.isEditing;
    final checkboxIsSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Opacity(
          opacity: widget.dimmed ? 0.35 : 1.0,
          child: Container(
            // Figma 1218:5675 高度 71px (无 source chip 时)
            // 含 source chip 时 (用于 'all' 视图) 自动撑高, 避免 overflow
            constraints: const BoxConstraints(minHeight: 71),
            decoration: BoxDecoration(
              // 选中态背景: Figma 1218:5725 fill_1c657ead (#EEEEEE)
              color: widget.isHighlighted ? FigmaTokens.highlight : Colors.white,
              border: const Border(
                bottom: BorderSide(color: FigmaTokens.border, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 复选框: 编辑模式 或 Hover 态
                if (showCheckbox)
                  Padding(
                    // Figma EL-497dae28 gap: 12
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: widget.onToggleSelect,
                      // Figma 1218:5315/5322/5339 hover 占位: 16x16 #D9D9D9 borderRadius 4
                      // Figma 1218:5303/5314 编辑态: 16x16 1.5px 黑边 + 选中时填色 + 对勾
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: checkboxIsEditing
                              ? (checkboxIsSelected
                                  ? FigmaTokens.primary
                                  : Colors.white)
                              : const Color(0xFFD9D9D9),
                          border: checkboxIsEditing
                              ? Border.all(
                                  color: FigmaTokens.primary,
                                  width: 1.5,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: (checkboxIsEditing && checkboxIsSelected)
                            ? const Icon(Icons.check_rounded,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                // 标题 + 元信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.sourceLabel != null) ...[
                        SourceChip(label: widget.sourceLabel!),
                        const SizedBox(height: 4),
                      ],
                      // 标题 15px / #333333 (Figma style_02d97395)
                      // 截断时 hover 显示完整文件名 (Figma 1218:5479 #1239:11267)
                      TruncatedTextWithTooltip(
                        text: widget.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: widget.isHighlighted
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: const Color(0xFF333333),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 元信息行: "{date} · {duration} · {statusText}"
                      _buildMetaRow(),
                    ],
                  ),
                ),
                // 右侧: 同步态本地图标 / 选中态黑色圆点 / 更多操作
                // Figma 1218:5315/5322/5339: hover 时右侧不显示 more
                _buildRightIcon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 元信息行: Figma 1218:5682/5696/5707/5714/5723/5731
  // 格式: "{date} · {duration} · {statusText}"  12px / #A1A1A1
  Widget _buildMetaRow() {
    final parts = <String>[widget.dateText];
    if (widget.duration != null && widget.duration!.isNotEmpty) {
      parts.add(widget.duration!);
    }
    if (widget.statusText != null && widget.statusText!.isNotEmpty) {
      parts.add(widget.statusText!);
    }
    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: FigmaTokens.textMuted,
        height: 1.0,
      ),
    );
  }

  // 右侧图标: 同步态本地图标 (Figma 1218:5685) / 选中态黑色圆点 (1218:5724) / 更多按钮
  // Figma 1218:5315/5322/5339: hover 时不显示 more 按钮
  Widget _buildRightIcon() {
    if (widget.isEditing) return const SizedBox.shrink();
    // 同步中/等待同步的文件: 显示本地存储图标 (Figma 1218:5685)
    final isSyncing = widget.statusText == '正在同步至手机' ||
        widget.statusText == '等待同步至手机';
    if (isSyncing) {
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.smartphone_rounded,
              size: 10, color: Color(0xFF666666)),
        ),
      );
    }
    // hover 时不显示右侧控件 (more 按钮)
    if (_isHovered) return const SizedBox.shrink();
    // 选中态黑色圆点 (Figma 1218:5724: 6x6 #262626 ellipse)
    if (widget.isHighlighted) {
      return Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: FigmaTokens.primary,
          shape: BoxShape.circle,
        ),
      );
    }
    // 默认: 更多操作按钮
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: const Icon(Icons.more_horiz_rounded,
          size: 18, color: FigmaTokens.textSecondary),
      onPressed: widget.onMore,
    );
  }
}

// ============================================================
// 更多操作菜单
// ============================================================
class MoreOptionsMenu extends StatelessWidget {
  final ValueChanged<String>
      onSelect; // returns 'retranscribe' | 'rename' | 'share' | 'export' | 'trash'
  const MoreOptionsMenu({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuItem(
              icon: Icons.autorenew_rounded,
              label: '重新转写',
              onTap: () => onSelect('retranscribe'),
            ),
            _MenuItem(
              icon: Icons.edit_outlined,
              label: '重命名',
              onTap: () => onSelect('rename'),
            ),
            _MenuItem(
              icon: Icons.share_outlined,
              label: '分享',
              onTap: () => onSelect('share'),
            ),
            _MenuItem(
              icon: Icons.download_outlined,
              label: '导出',
              onTap: () => onSelect('export'),
            ),
            const Divider(height: 10, color: Color(0xFFF3F4F6)),
            _MenuItem(
              icon: Icons.delete_forever_outlined,
              label: '移至回收站',
              isRed: true,
              onTap: () => onSelect('trash'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isRed;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.isRed = false});

  @override
  Widget build(BuildContext context) {
    final color = isRed ? Colors.redAccent : Colors.black87;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isRed ? Colors.redAccent : Colors.black54),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 重命名弹窗
// ============================================================
class RenameFileDialog extends StatefulWidget {
  final String initialName;
  final ValueChanged<String> onSave;
  final VoidCallback onClose;
  const RenameFileDialog({
    super.key,
    required this.initialName,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<RenameFileDialog> createState() => _RenameFileDialogState();
}

class _RenameFileDialogState extends State<RenameFileDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '文件重命名',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: FigmaTokens.fieldBg,
                    border: Border.all(color: FigmaTokens.fieldBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TalixButton(
                        label: '取消',
                        variant: TalixButtonVariant.neutralOutline,
                        height: 44,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        borderColor: Colors.grey.shade200,
                        onPressed: widget.onClose,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TalixButton(
                        label: '保存',
                        height: 44,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        onPressed: () {
                          final value = _controller.text.trim();
                          if (value.isNotEmpty) {
                            widget.onSave(value);
                          } else {
                            widget.onClose();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 分享底部 sheet
// ============================================================
class ShareFileSheet extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onClose;
  const ShareFileSheet(
      {super.key, required this.onConfirm, required this.onClose});

  @override
  State<ShareFileSheet> createState() => _ShareFileSheetState();
}

class _ShareFileSheetState extends State<ShareFileSheet> {
  final Set<String> _checked = {'audio', 'transcription', 'summary'};

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('分享文件',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900)),
                    GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close_rounded, size: 20)),
                  ],
                ),
                const SizedBox(height: 16),
                _CheckRow(
                  label: '音频文件',
                  value: _checked.contains('audio'),
                  onChanged: (v) => setState(() =>
                      v ? _checked.add('audio') : _checked.remove('audio')),
                ),
                _CheckRow(
                  label: '转写文稿',
                  value: _checked.contains('transcription'),
                  onChanged: (v) => setState(() => v
                      ? _checked.add('transcription')
                      : _checked.remove('transcription')),
                ),
                _CheckRow(
                  label: 'AI 纪要',
                  value: _checked.contains('summary'),
                  onChanged: (v) => setState(() =>
                      v ? _checked.add('summary') : _checked.remove('summary')),
                ),
                const SizedBox(height: 20),
                TalixButton(
                  label: '打包并生成分享链接',
                  variant: TalixButtonVariant.dark,
                  height: 46,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  backgroundColor: FigmaTokens.primary,
                  onPressed: widget.onConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? FigmaTokens.accent : Colors.white,
                border: Border.all(
                    color: value ? FigmaTokens.accent : FigmaTokens.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 导出底部 sheet (二步: 类型 -> 音频格式)
// ============================================================
class ExportTypeSheet extends StatefulWidget {
  final void Function(String exportType, String? audioFormat) onConfirm;
  final VoidCallback onClose;
  const ExportTypeSheet(
      {super.key, required this.onConfirm, required this.onClose});

  @override
  State<ExportTypeSheet> createState() => _ExportTypeSheetState();
}

class _ExportTypeSheetState extends State<ExportTypeSheet> {
  String? _selectedType; // 'audio' | 'pdf' | 'doc' | 'mindmap'
  String _selectedFormat = 'MP3';
  final List<String> _audioFormats = ['MP3', 'WAV', 'ALAC', 'FLAC'];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedType == null ? '选择导出类型' : '选择音频格式',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_selectedType == null) {
                          widget.onClose();
                        } else {
                          setState(() => _selectedType = null);
                        }
                      },
                      child: Icon(
                        _selectedType == null
                            ? Icons.close_rounded
                            : Icons.arrow_back_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedType == null)
                  _buildTypeList()
                else
                  _buildFormatList(),
                const SizedBox(height: 20),
                TalixButton(
                  label: '确认导出',
                  variant: TalixButtonVariant.dark,
                  height: 46,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  backgroundColor: FigmaTokens.primary,
                  disabledBackgroundColor: FigmaTokens.borderStrong,
                  disabledForegroundColor: Colors.white,
                  onPressed: _selectedType == null
                      ? null
                      : () => widget.onConfirm(_selectedType!,
                          _selectedType == 'audio' ? _selectedFormat : null),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeList() {
    final types = [
      {'key': 'audio', 'label': '录音文件', 'sub': '导出原始录音'},
      {'key': 'pdf', 'label': '完整文稿 PDF', 'sub': '含发言人、转写、纪要'},
      {'key': 'doc', 'label': 'AI 纪要 Word', 'sub': '导出 AI 生成的纪要'},
      {'key': 'mindmap', 'label': '思维脑图', 'sub': '导出脑图文件'},
    ];
    return Column(
      children: types
          .map((t) => _TypeRow(
                label: t['label']!,
                sub: t['sub']!,
                selected: _selectedType == t['key'],
                onTap: () => setState(() => _selectedType = t['key']),
              ))
          .toList(),
    );
  }

  Widget _buildFormatList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _audioFormats.map((f) {
        final selected = f == _selectedFormat;
        return InkWell(
          onTap: () => setState(() => _selectedFormat = f),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? FigmaTokens.primary : Colors.white,
              border: Border.all(
                  color: selected ? FigmaTokens.primary : FigmaTokens.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              f,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : FigmaTokens.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _TypeRow(
      {required this.label,
      required this.sub,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? FigmaTokens.primary : FigmaTokens.border,
                    width: 2),
                color: selected ? FigmaTokens.primary : Colors.white,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: FigmaTokens.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 重新转写流程 (auto/custom + 4 步选择 + 进度)
// ============================================================
class ReTranscribeFlow extends StatefulWidget {
  final String initialTemplate;
  final String initialAudioLang;
  final String initialAiModel;
  final String initialTranslateLang;
  final void Function(Map<String, String> config) onComplete;
  final VoidCallback onClose;
  const ReTranscribeFlow({
    super.key,
    required this.initialTemplate,
    required this.initialAudioLang,
    required this.initialAiModel,
    required this.initialTranslateLang,
    required this.onComplete,
    required this.onClose,
  });

  @override
  State<ReTranscribeFlow> createState() => _ReTranscribeFlowState();
}

class _ReTranscribeFlowState extends State<ReTranscribeFlow> {
  late String
      _step; // 'auto' | 'custom' | 'template' | 'audioLang' | 'aiModel' | 'translateLang' | 'generating'
  late String _template;
  late String _audioLang;
  late String _aiModel;
  late String _translateLang;
  int _progress = 0;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _step = 'auto';
    _template = widget.initialTemplate;
    _audioLang = widget.initialAudioLang;
    _aiModel = widget.initialAiModel;
    _translateLang = widget.initialTranslateLang;
  }

  void _startGenerating() {
    setState(() {
      _step = 'generating';
      _generating = true;
      _progress = 0;
    });
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_generating) return;
      setState(() => _progress += 5);
      if (_progress >= 100) {
        _generating = false;
        widget.onComplete({
          'template': _template,
          'audioLang': _audioLang,
          'aiModel': _aiModel,
          'translateLang': _translateLang,
        });
      } else {
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: _buildStepBody(),
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    if (_step == 'generating') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                  color: FigmaTokens.accent, strokeWidth: 4),
            ),
            const SizedBox(height: 20),
            const Text('AI 智能排程生成中...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('完成进度：$_progress%',
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('请保持设备连接，期间您可以做其他事',
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    if (_step == 'auto') {
      return _buildAutoPanel();
    }
    if (_step == 'custom') {
      return _buildCustomPanel();
    }
    if (_step == 'template') {
      return _buildSelectorPanel(
          '选择纪要模板', _template, const ['智能纪要', '会议纪要', '访谈纪要', '课堂笔记'], (v) {
        setState(() {
          _template = v;
          _step = 'custom';
        });
      });
    }
    if (_step == 'audioLang') {
      return _buildSelectorPanel('选择音频语言', _audioLang,
          const ['自动', '中文(简体-普通话)', 'English (US)', '日本語'], (v) {
        setState(() {
          _audioLang = v;
          _step = 'custom';
        });
      });
    }
    if (_step == 'aiModel') {
      return _buildSelectorPanel('选择 AI 模型', _aiModel,
          const ['自动', 'GPT-5.5', 'Gemini 2.5 Pro', 'Claude Sonnet 4.6'], (v) {
        setState(() {
          _aiModel = v;
          _step = 'custom';
        });
      });
    }
    if (_step == 'translateLang') {
      return _buildSelectorPanel(
          '选择翻译语言', _translateLang, const ['不翻译', '中文(简体)', 'English', '日本語'],
          (v) {
        setState(() {
          _translateLang = v;
          _step = 'custom';
        });
      });
    }
    return const SizedBox.shrink();
  }

  Widget _buildAutoPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('重新转写',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('智能匹配适合的模板和模型，自动生成转写与纪要。',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TalixButton(
                  label: '自定义生成',
                  variant: TalixButtonVariant.neutralOutline,
                  height: 44,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  foregroundColor: FigmaTokens.primary,
                  borderColor: FigmaTokens.border,
                  onPressed: () => setState(() {
                    _step = 'custom';
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TalixButton(
                  label: '开始生成',
                  variant: TalixButtonVariant.dark,
                  height: 44,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  backgroundColor: FigmaTokens.primary,
                  onPressed: _startGenerating,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('自定义生成',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _SelectorRow(
              label: '纪要模板',
              value: _template,
              onTap: () => setState(() => _step = 'template')),
          _SelectorRow(
              label: '音频语言',
              value: _audioLang,
              onTap: () => setState(() => _step = 'audioLang')),
          _SelectorRow(
              label: 'AI 模型',
              value: _aiModel,
              onTap: () => setState(() => _step = 'aiModel')),
          _SelectorRow(
              label: '翻译语言',
              value: _translateLang,
              onTap: () => setState(() => _step = 'translateLang')),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TalixButton(
                  label: '取消',
                  variant: TalixButtonVariant.neutralOutline,
                  height: 44,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  borderColor: Colors.grey.shade200,
                  onPressed: widget.onClose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TalixButton(
                  label: '确定并生成',
                  height: 44,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  onPressed: _startGenerating,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorPanel(String title, String current, List<String> options,
      ValueChanged<String> onSelect) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _step = 'custom'),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((o) => InkWell(
                onTap: () => onSelect(o),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: o == current
                                  ? FigmaTokens.primary
                                  : FigmaTokens.border,
                              width: 2),
                          color:
                              o == current ? FigmaTokens.primary : Colors.white,
                        ),
                        child: o == current
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(o, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _SelectorRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _SelectorRow(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: FigmaTokens.textMuted))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: FigmaTokens.textPrimary,
                        fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: FigmaTokens.textFaint),
          ],
        ),
      ),
    );
  }
}
