import 'dart:async';
import 'package:flutter/material.dart';
import '../viewmodels/recycle_bin_viewmodel.dart';
import '../widgets/file_list_widgets.dart';

// ============================================================
// RecycleBinScreen (View 层, MVVM 模式, Figma 1218:9817)
// 整体布局:
//   - 顶部 24px 内边距 + 24px Bold #262626 标题 "回收站"
//   - 搜索栏 + 清空 (Row, spaceBetween)
//   - 文件表格: 文件名(flex) | 日期 140 | 大小 80 | 操作 40 (右对齐)
//   - 列间 24px gap, 行间 1px #F5F5F5 分隔
//   - 浮层: 永久删除/清空后弹出黑色胶囊 SnackBar (Figma 1218:9932 54x40) 含"恢复"动作
// ============================================================
class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  late final RecycleBinViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  // Figma 1218:9932 自定义浮层 (54x40 黑色胶囊), 替代 ScaffoldMessenger SnackBar
  OverlayEntry? _toastOverlay;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _viewModel = RecycleBinViewModel();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastOverlay?.remove();
    _toastOverlay = null;
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // 监听 ViewModel 暴露的 lastActionMessage, 决定 SnackBar 类型
        final msg = _viewModel.lastActionMessage;
        if (msg != null) {
          // 在 build 之后异步展示 SnackBar, 避免在 build 阶段触发
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showActionSnackBar(context, msg);
            _viewModel.clearLastActionMessage();
          });
        }
        return _buildContent(context);
      },
    );
  }

  // ===== 整体内容 =====
  // 布局 (对齐 Figma 1218:9817):
  //   - Content-Header (1218:9877) w=800, padding 24/48/24/0
  //   - Workspace (1218:9879) 内:
  //       Search bar (1218:9925) x=200 y=13 w=280 h=40
  //       "清空" (1218:9931)        x=971 y=26
  //       File-List-Section (1218:9880) x=200 y=72 w=800
  //     搜索栏与表格间距 = 72 - 13 - 40 = 19px
  //     表格右侧 (971+29=1000) 距 Main-Area 右边缘 200px, 用 right:200 padding 实现
  Widget _buildContent(BuildContext context) {
    return Material(
      // 使用 Material 显式覆盖 IndexedStack 底层页面的内容,
      // 避免 me_profile 的 "PRO" 标签等组件透出
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 搜索栏 + 清空 (Figma 1218:9925 / 1218:9931)
                  // Row 宽 = Main-Area 1200 - left:200 - right:200 = 800
                  // spaceBetween 让搜索栏贴左, 清空贴右, 恰好对齐 Figma x=200 / x=971
                  Padding(
                    padding: const EdgeInsets.only(top: 13, right: 200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildSearchBar(),
                        _buildClearAllButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  // 文件列表 (Figma 1218:9880) - 严格 800px 宽
                  // 使用 Expanded 填充剩余高度, Align 让子组件居左
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 800,
                        child: _buildFileListSection(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 顶部标题区 (Figma 1218:9877) =====
  // 标题 "回收站" 与下方搜索框/文件列表左边对齐 (Main-Area 内 x=200)

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(200, 24, 48, 24),
      child: const Text(
        '回收站',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF262626),
          height: 1.0,
        ),
      ),
    );
  }

  // ===== 搜索框 (Figma 1218:9925) =====
  // 280x40, padding 14 24 14 16, 1px #ACACAC 4px radius
  // 内部使用 Stack 让 icon 居左 + 文本水平居中
  Widget _buildSearchBar() {
    return Container(
      width: 280,
      height: 40,
      padding: const EdgeInsets.fromLTRB(16, 14, 24, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFACACAC), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      // Stack 层级: 底层 TextField (透明, 接收输入), 顶层 icon + hint 居中
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 透明 TextField 占满整个搜索框, 用于接收输入
          // 内容靠左输入 (textAlign: start), 但视觉上整体居中
          TextField(
            controller: _searchController,
            onChanged: _viewModel.setSearchQuery,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Microsoft YaHei',
              fontSize: 12,
              color: Color(0xFF333333),
              height: 1.0,
            ),
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: '搜索...',
              hintStyle: TextStyle(
                fontFamily: 'Microsoft YaHei',
                fontSize: 12,
                color: Color(0xFF777777),
                height: 1.0,
              ),
            ),
          ),
          // 搜索 icon 浮在左侧, 不阻挡输入
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.search_rounded,
                size: 14, color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }

  // ===== "清空" 按钮 (Figma 1218:9931) =====
  // 14px Regular #242424, 仅在有文件时可点击
  Widget _buildClearAllButton() {
    final hasFiles = _viewModel.totalCount > 0;
    return InkWell(
      onTap: hasFiles ? () => _confirmClearAll(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          '清空',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: hasFiles
                ? const Color(0xFF242424)
                : FigmaTokens.textMuted,
            height: 13.5 / 14,
            letterSpacing: 0.0119,
          ),
        ),
      ),
    );
  }

  // ===== 文件列表区 (Figma 1218:9880) =====

  Widget _buildFileListSection() {
    final files = _viewModel.visibleFiles;
    if (files.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: files.length,
            separatorBuilder: (_, __) => const _TrashRowDivider(),
            itemBuilder: (context, index) {
              final file = files[index];
              return _TrashTableRow(
                title: file.title,
                dateText: file.dateText,
                size: file.size,
                onRestore: () async {
                  final outerContext = context;
                  try {
                    await _viewModel.restoreFile(file.id);
                    if (!outerContext.mounted) return;
                    // Figma 1218:9935 "文件已恢复"
                    _showActionSnackBar(outerContext, '文件已恢复');
                  } catch (e) {
                    if (!outerContext.mounted) return;
                    _showActionSnackBar(outerContext, '恢复失败,请重试');
                  }
                },
                onDelete: () => _confirmDeleteSingle(context, file.id),
              );
            },
          ),
        ),
      ],
    );
  }

  // 表头 (Figma 1218:9881) - 1px 底边 #E5E5E5, 列间 24px gap
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FigmaTokens.border, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              '文件名',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: FigmaTokens.textMuted,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(width: 24),
          SizedBox(
            width: 140,
            child: Text(
              '日期时间',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: FigmaTokens.textMuted,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(width: 24),
          SizedBox(
            width: 80,
            child: Text(
              '大小',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: FigmaTokens.textMuted,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(width: 24),
          SizedBox(
            width: 40,
            child: Text(
              '操作',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: FigmaTokens.textMuted,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 空态 =====
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '回收站是空的',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: FigmaTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===== 确认弹窗 (永久删除单个) =====
  // Figma 1218:10245 "删除文件"
  // 描述必须用 "该文件" 单数语义, 不能复用清空的 "所有文件" 文案
  void _confirmDeleteSingle(BuildContext context, String id) {
    final file = _viewModel.findById(id);
    final fileName = file?.title ?? '该文件';
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x80000000), // rgba(0,0,0,0.5)
      builder: (ctx) => _TrashConfirmDialog(
        title: '删除文件',
        description: '「$fileName」将被永久删除无法恢复，您确定要删除吗？',
        confirmLabel: '删除',
        onConfirm: () async {
          final outerContext = context;
          Navigator.pop(ctx);
          try {
            await _viewModel.deleteFile(id);
            if (!outerContext.mounted) return;
            // Figma 1218:10052: toast 带文件名, 明确是哪一条被删
            _showActionSnackBar(outerContext, '已删除「$fileName」');
          } catch (e) {
            if (!outerContext.mounted) return;
            _showActionSnackBar(outerContext, '删除失败,请重试');
          }
        },
      ),
    );
  }

  // ===== 确认弹窗 (清空回收站) =====
  // Figma 1218:10231 "全部删除"
  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x80000000), // rgba(0,0,0,0.5)
      builder: (ctx) => _TrashConfirmDialog(
        title: '全部删除',
        description: '回收站中的所有文件将被永久删除无法恢复，您确定要删除吗？',
        confirmLabel: '删除',
        onConfirm: () async {
          final outerContext = context;
          Navigator.pop(ctx);
          try {
            await _viewModel.clearAll();
            if (!outerContext.mounted) return;
            // Figma 1218:10157 "回收站中的所有文件已删除"
            _showActionSnackBar(outerContext, '回收站中的所有文件已删除');
          } catch (e) {
            if (!outerContext.mounted) return;
            _showActionSnackBar(outerContext, '清空失败,请重试');
          }
        },
      ),
    );
  }

  // ===== 操作反馈浮层 (Figma 1218:10157 / 1218:9935 / 1218:10052) =====
  // 纯文本黑色胶囊, 14px Inter Regular #FFFFFF
  void _showActionSnackBar(BuildContext context, String message) {
    // 清除已有, 避免连续触发叠加
    _toastTimer?.cancel();
    _toastOverlay?.remove();
    _toastOverlay = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (ctx) => _TrashToast(
        message: message,
        onDismiss: () {
          _toastTimer?.cancel();
          _toastOverlay?.remove();
          _toastOverlay = null;
        },
      ),
    );
    overlay.insert(entry);
    _toastOverlay = entry;

    // 3 秒后自动消失
    _toastTimer = Timer(const Duration(seconds: 3), () {
      _toastOverlay?.remove();
      _toastOverlay = null;
    });
  }
}

// ============================================================
// 单行: 文件名 / 日期 / 大小 / 操作
// 严格对齐 Figma 1218:9887 EL-ebcaf300 (padding 16 8, 列间 gap 24)
// 操作列宽 56px 容纳 2 个 16x16 图标 + 16px 间距 (Figma 40px 不够)
// ============================================================
class _TrashTableRow extends StatelessWidget {
  final String title;
  final String dateText;
  final String size;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashTableRow({
    required this.title,
    required this.dateText,
    required this.size,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 文件名 (Name-Col EL-7d5ab796)
          Expanded(
            child: TruncatedTextWithTooltip(
              text: title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF262626),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // 日期时间 (EL-5297a4f3)
          SizedBox(
            width: 140,
            child: Text(
              dateText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF737373),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // 大小 (EL-33d6d136)
          SizedBox(
            width: 80,
            child: Text(
              size,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF737373),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // 操作 (EL-d3015e12, right-aligned)
          // Figma 1218:9885 width=40, 但内部 2 个 16x16 图标 + 16 gap = 48 实际溢出 8px
          // 为避免溢出, 内部图标 gap 改为 8px (16+8+16=40 恰好)
          SizedBox(
            width: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 恢复 (Figma 1218:9895 radix-icons:reset)
                _ActionIcon(
                  icon: Icons.restore_rounded,
                  tooltip: '恢复',
                  onTap: onRestore,
                ),
                // 删除 (Figma 1218:9897 ic:outline-delete)
                _ActionIcon(
                  icon: Icons.delete_outline_rounded,
                  tooltip: '永久删除',
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFF666666)),
        ),
      ),
    );
  }
}

// 行间分隔线 (Figma EL-0a835613, 1px #F5F5F5)
class _TrashRowDivider extends StatelessWidget {
  const _TrashRowDivider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0xFFF5F5F5));
  }
}

// ============================================================
// 操作反馈浮层 (Figma 1218:10157 "回收站中的所有文件已删除" /
//             1218:9935 "文件已恢复" /
//             1218:10052 "文件已删除")
// 规格:
//   - Container: padding 5/16/5/24, 40px 高, #262626 bg, 完全胶囊 (圆角 16777200)
//   - 文本: 14px Inter Regular #FFFFFF, lh 13.5px, letter-spacing 0.0119em
//   - 阴影: 0 4 4 rgba(0, 0, 0, 0.25)
//   - 位置: 屏幕右上, 距右 24px, 距上 16px (Figma y=55 在 Main-Area 顶 43 之后 12px)
//   - 入场动画: 200ms 淡入 + 8px 上滑
//   - 不含 "恢复" 动作 (Figma 中所有 3 个 toast 都是纯文本)
// ============================================================
class _TrashToast extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _TrashToast({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_TrashToast> createState() => _TrashToastState();
}

class _TrashToastState extends State<_TrashToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Positioned(
      // 屏幕右上: 顶部 16px, 右侧 24px (Figma y=55 是 Main-Area 顶 43 + 12, 这里统一用 padding.top + 16)
      top: mediaQuery.padding.top + 16,
      right: 24,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            // 点击浮层直接关闭
            child: GestureDetector(
              onTap: widget.onDismiss,
              // Figma Container 1218:10229/10050/1218:10155
              child: Container(
                height: 40,
                padding: const EdgeInsets.fromLTRB(24, 5, 16, 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(16777200), // 完全胶囊
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                // 文本 (Figma 1218:10230/10051/1218:10156)
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 13.5 / 14, // 0.964
                    letterSpacing: 0.0119 * 14, // 0.1666
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 通用确认弹窗 (居中模态, Figma 1218:10231 "全部删除" / 1218:10245 "删除文件")
// 规格:
//   - modal-card 480x[auto], 8px radius, 白色背景
//   - 标题区 (Figma 子节点): 标题 18px Bold #18181B 左对齐 + 关闭 icon 15.56x15.56 #000000 右对齐
//   - 描述: 14px Regular #262626 lh 20px, x=40 width=392
//   - 按钮: 居中底部, 12px gap
//     - "取消" 按钮: 白底 1px #D1D5DB 描边 6px radius, padding 10/20, 14px Medium #18181B
//     - "删除" 按钮: #18181B 填充 6px radius, padding 10/20, 14px Medium #FFFFFF
//   - 背景: rgba(0, 0, 0, 0.5) 蒙层
// ============================================================
class _TrashConfirmDialog extends StatelessWidget {
  final String title;
  final String description;
  final String confirmLabel;
  final VoidCallback onConfirm;
  const _TrashConfirmDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      // Figma modal-card 480x260
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题区: 标题左对齐 + 关闭 icon 右对齐
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 标题 18px Bold #18181B
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                      height: 1.0,
                    ),
                  ),
                  // 关闭 icon 15.56x15.56 #000000
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 描述: 14px Regular #262626 lh 20px
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF262626),
                  height: 20 / 14, // 1.428
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              // 按钮区: 居中, 12px gap
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "取消" 按钮: 白底 1px #D1D5DB 描边 6px radius
                  _DialogButton(
                    label: '取消',
                    background: Colors.white,
                    foreground: const Color(0xFF18181B),
                    borderColor: const Color(0xFFD1D5DB),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  // "删除" 按钮: #18181B 填充
                  _DialogButton(
                    label: confirmLabel,
                    background: const Color(0xFF18181B),
                    foreground: Colors.white,
                    onTap: onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 对话框按钮 (Figma layout_5965597b: padding 10/20, justifyContent center, alignItems center)
class _DialogButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onTap;
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: foreground,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
