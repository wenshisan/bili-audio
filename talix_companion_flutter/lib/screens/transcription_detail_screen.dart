import 'package:flutter/material.dart';
import '../viewmodels/transcription_detail_viewmodel.dart';
import '../widgets/common/common.dart';
import '../data/dialogue_block.dart';

// ============================================================
// MINDMAP PAINTER (Figma 1218:7146 思维导图缩略图)
// 简易思维导图绘制: 中心节点 + 3个分支 (左上/右上/正下)
// ============================================================
class _MindmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = const Color(0xFFD1D1D1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 三个分支点
    final points = [
      Offset(cx - 110, cy - 50),
      Offset(cx + 110, cy - 50),
      Offset(cx, cy + 80),
    ];
    for (final p in points) {
      canvas.drawLine(Offset(cx, cy), p, paint);
    }
    // 分支端点圆
    final fill = Paint()..color = const Color(0xFFE5E5E5);
    for (final p in points) {
      canvas.drawCircle(p, 28, fill);
      canvas.drawCircle(p, 28, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// CLOSE ICON PAINTER (Figma 1218:8494 Union 15.56x15.56 #000)
// 生成方式弹窗标题栏关闭按钮: 两条对角线
// ============================================================
class _CloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(1, 1), Offset(size.width - 1, size.height - 1), paint);
    canvas.drawLine(Offset(size.width - 1, 1), Offset(1, size.height - 1), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// CHECK MARK PAINTER (Figma 1218:8756 10x8 #000)
// 侧边面板选中态: 折线 √
// ============================================================
class _CheckMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// 侧边面板选项数据 (Figma 1218:8689 / 1218:8799 / 1218:8909 / 1218:8998)
// title: 14px / desc: 12px / 选中时右侧展示 ✓
// ============================================================
class _SidePanelItem {
  final String title;
  final String desc;
  const _SidePanelItem(this.title, this.desc);
}

class TranscriptionDetailScreen extends StatefulWidget {
  final String initialTitle;
  final String initialDate;
  // Figma 1218:6792: 'pending' 表示录音未生成, 显示占位页
  final String? initialFileStatus;
  // 当嵌入三栏布局时, 返回按钮不再 pop, 而是调用 onBack 关闭右侧详情
  final VoidCallback? onBack;
  const TranscriptionDetailScreen({
    super.key,
    required this.initialTitle,
    required this.initialDate,
    this.initialFileStatus,
    this.onBack,
  });

  @override
  State<TranscriptionDetailScreen> createState() =>
      _TranscriptionDetailScreenState();
}

class _TranscriptionDetailScreenState extends State<TranscriptionDetailScreen> {
  late final TranscriptionDetailViewModel _viewModel;

  // UI-only: TextEditingControllers
  final TextEditingController _speakerInputController = TextEditingController();
  final TextEditingController _editTextController = TextEditingController();
  final TextEditingController _chatInputController = TextEditingController();
  final TextEditingController _renameInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = TranscriptionDetailViewModel(initialTitle: widget.initialTitle);
    _renameInputController.text = widget.initialTitle;
    // Figma 1218:6792: 未生成状态在 init 时直接启用
    if (widget.initialFileStatus == 'pending') {
      _viewModel.isUngenerated = true;
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _speakerInputController.dispose();
    _editTextController.dispose();
    _chatInputController.dispose();
    _renameInputController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF111827),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateStateForFrame(String frameId) {
    _viewModel.goToFrame(frameId);
  }

  String _formatSeconds(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _handleAskSubmit(String query) {
    _chatInputController.clear();
    _viewModel.sendChatMessage(query);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // Figma 1218:6792: 转写未生成占位页 (玩家上方, 占位区下方)
        if (_viewModel.isUngenerated) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: Column(
              children: [
                _buildTopPlayerCard(),
                Expanded(child: _buildUngeneratedView()),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Main body based on active frame / route
              Expanded(
                child: _buildMainBody(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================================== APP BAR ====================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 18),
        onPressed: () {
          // 优先调用 onBack 回调 (用于三栏布局中关闭右侧详情), 否则回退到 Navigator.pop
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      // 居中标题: Figma 1218:7276 下划线样式
      // "转写 | 纪要" - 激活态加粗 + 下划线 (ts1 + ts2)
      titleSpacing: 0,
      title: ['10', '11', '12', '13', '14', '15', '16', '17']
              .contains(_viewModel.activeFrame)
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUnderlineTab('转写', _viewModel.activeTab == 'transcription', () {
                    _viewModel.activeTab = 'transcription';
                    _showToast('已切换至转写文本视图');
                  }),
                  const SizedBox(width: 32),
                  _buildUnderlineTab('纪要', _viewModel.activeTab == 'summary', () {
                    _viewModel.activeTab = 'summary';
                    _showToast('已切换至AI智能纪要视图');
                  }),
                ],
              ),
            )
          : Text(
              _viewModel.renameValue,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w900),
            ),
      actions: [
        // Ask AI 按钮 (Figma 1218:7075: 16x16 灰底图标 + 14px 文字 "Ask AI")
        // Figma 1218:9130: 点击切换右侧悬浮 AI 问答面板
        // Figma 1218:6792: 文件未生成时, AI 问答无数据基础, 点击提示
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () {
              if (_viewModel.isUngenerated) {
                _showToast('文件尚未生成转写，无法使用 AI 问答');
                return;
              }
              _viewModel.toggleAskAi();
              _showToast(_viewModel.isAskAiOpen ? '已打开 AI 智能体' : '已关闭 AI 智能体');
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.auto_awesome,
                        size: 10, color: Color(0xFF666666)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ask AI',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: _viewModel.isAskAiOpen
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: _viewModel.isAskAiOpen
                          ? const Color(0xFF262626)
                          : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 更多按钮 (Figma 1218:7073: ri:more-line 16x16)
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.black87, size: 18),
          onPressed: () {
            _viewModel.isMenuOpen = !_viewModel.isMenuOpen;
          },
        ),
      ],
    );
  }

  // 下划线样式的 Tab (Figma 1218:7071: ts1 加粗下划线 / ts2 无下划线)
  // 规格: 16px / lineHeight 16.5px / letterSpacing 0.004em / #262626
  Widget _buildUnderlineTab(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF262626) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF262626),
            decoration:
                isActive ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFF262626),
            decorationThickness: 2,
            letterSpacing: 0.004 * 16, // Figma 0.004em
            height: 16.5 / 16,
          ),
        ),
      ),
    );
  }

  // ==================================== MAIN BODY ROUTING ====================================
  Widget _buildMainBody() {
    return Stack(
      children: [
        // Background View (Standard content)
        Column(
          children: [
            // Top player block (Unless in settings/generation/QA screens)
            // Figma 1218:9130: AI 问答 (frames 21/22/23) 改为右侧悬浮 overlay,
            //   不再全屏替换主区, 所以从排除列表中移除, 主内容 (转写/纪要) 持续显示
            if (![
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '19',
              '20',
            ].contains(_viewModel.activeFrame))
              _buildTopPlayerCard(),

            Expanded(
              child: _buildTabOrFrameContent(),
            ),
          ],
        ),

        // 更多菜单点击空白处关闭的透明屏障 (Figma 1218:7322)
        // 只在 isMenuOpen 时显示, 位于背景之上、菜单之下
        // - HitTestBehavior.opaque: 吸收点击, 阻止穿透到背景
        // - 点击 menu 本身的项: 菜单在屏障之上, 由菜单项的 InkWell 处理
        // - 点击其他 overlay (rename/share/...): 它们在更上层, 不受影响
        if (_viewModel.isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _viewModel.isMenuOpen = false;
              },
            ),
          ),

        // Overlays & Dialogs (Menu, Rename, Share, etc.)
        if (_viewModel.isMenuOpen) _buildEllipsisDropdown(),
        if (_viewModel.isRenameOpen) _buildRenameOverlay(),
        if (_viewModel.isShareOpen) _buildShareOverlay(),
        if (_viewModel.isExportOpen) _buildExportOverlay(),
        if (_viewModel.activeFrame == '03') _buildAutoGenerateModal(),
        if (['04', '05', '06', '07', '08'].contains(_viewModel.activeFrame))
          _buildCustomGenerateModal(),
        if (_viewModel.activeFrame == '09') _buildGeneratingOverlay(),
        if (_viewModel.activeFrame == '14') _buildSpeakerEditDialog(),

        // AI 问答右侧悬浮面板 (Figma 1218:9130 / 1218:9335)
        // 位于所有 overlay 之上, 作为最顶层的浮层
        _buildAskAiOverlay(),
      ],
    );
  }

  Widget _buildTabOrFrameContent() {
    if (_viewModel.activeFrame == '01') {
      return _buildFrame01State();
    }
    // Figma 1218:9130: AI 问答改为右侧悬浮 overlay, 主区不再切换,
    //   所以 frame 21/22/23 不再作为路由分支, 默认走下方 tab 逻辑
    // 导出 / 分享 (frame 19 / 18) 都作为 overlay 弹出, 不改变 tab 背景
    //   - frame 18 (分享): _isShareOpen
    //   - frame 19 (导出): _isExportOpen
    // 其它 frame (03-09 生成流程等) 在 _buildMainBody 内单独路由

    // Tab content
    if (_viewModel.activeTab == 'summary') {
      return _buildSummaryTab();
    } else {
      return _buildTranscriptionTab();
    }
  }

  // ==================================== COMPONENT: PLAYER CARD ====================================
  // Figma 1218:7078 规格:
  //   - 顶部 4px 进度条 (640x4 / #D9D9D9 背景, 已播放 #262626)
  //   - 标题左 (14px / 12px lh / 0.0147em / #262626)
  //   - 时间右 (12px / 12px lh / 0.0171em / #737373; 当前时间 #262626)
  //   - 中心 32x32 黑色圆形播放按钮 + 白色 "▶" 图标
  Widget _buildTopPlayerCard() {
    final progressRatio =
        (_viewModel.currentTime / _viewModel.totalDuration).clamp(0.0, 1.0);
    final totalWidth = MediaQuery.of(context).size.width - 32;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) 顶部进度条 (4px / #D9D9D9 背景, 已播放部分 #262626)
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final localX = details.localPosition.dx.clamp(0.0, totalWidth);
              _viewModel.seekTo((localX / totalWidth * _viewModel.totalDuration).toInt());
            },
            onTapDown: (details) {
              final localX = details.localPosition.dx.clamp(0.0, totalWidth);
              _viewModel.seekTo((localX / totalWidth * _viewModel.totalDuration).toInt());
            },
            child: Container(
              width: totalWidth,
              height: 4,
              color: const Color(0xFFD9D9D9),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: totalWidth * progressRatio,
                  height: 4,
                  color: const Color(0xFF262626),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2) 控制行: 标题(左) | 播放按钮(中) | 时间(右)
          SizedBox(
            height: 32,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 标题 (左) - Figma 1218:7080
                Expanded(
                  child: Text(
                    _viewModel.activeFrame == '12'
                        ? '05-07 Weekly Review'
                        : '05-06 产品品会：用户增长策略与方案复盘',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 12 / 14,
                      letterSpacing: 0.0147 * 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF262626),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 播放按钮 (中) - Figma 1218:7081 32x32 黑色圆 + 白色 ▶
                GestureDetector(
                  onTap: () {
                    _viewModel.togglePlay();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _viewModel.isPlaying ? '⏸' : '▶',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 15 / 14,
                        letterSpacing: 0.0084 * 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 时间 (右) - Figma 1218:7079 当前时间 #262626 / 总时长 #737373
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _formatSeconds(_viewModel.currentTime),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          height: 12 / 12,
                          letterSpacing: 0.0171 * 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF262626),
                        ),
                      ),
                      TextSpan(
                        text: ' / ${_formatSeconds(_viewModel.totalDuration)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          height: 12 / 12,
                          letterSpacing: 0.0171 * 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF737373),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================== SCREEN STATE: 01 UNGENERATED ====================================
  // Figma 1218:6792 规格:
  //   - 容器: Column, alignItems center, gap 24
  //   - 占位区: 96x96 #D9D9D9 圆角 16px (Figma 1218:6937)
  //   - 提示文字: "转写与纪要将一并生成，生成后可多端查看" 15px / #A1A1A1 (Figma 1218:6938)
  //   - 操作按钮: 360x48 #262626 圆角 12px 白色文字 "生成" (Figma 1218:6939-6940)
  // 点击 "生成" 触发自动生成 Modal (frame '03'), isUngenerated 切换为 false
  Widget _buildFrame01State() => _buildUngeneratedView();

  Widget _buildUngeneratedView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 占位区: 96x96 #D9D9D9 圆角 16 (Figma 1218:6937)
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          // 提示文字: 15px / #A1A1A1 (Figma 1218:6938)
          const Text(
            '转写与纪要将一并生成，生成后可多端查看',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A1A1),
              height: 13.5 / 15,
              letterSpacing: 0.0111 * 15,
            ),
          ),
          const SizedBox(height: 32),
          // 操作按钮: 360x48 #262626 圆角 12 白色文字 (Figma 1218:6939-6940)
          TalixButton(
            label: '生成',
            variant: TalixButtonVariant.dark,
            width: 360,
            height: 48,
            borderRadius: 12,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            backgroundColor: const Color(0xFF262626),
            onPressed: () {
              _viewModel.isUngenerated = false;
              _viewModel.goToFrame('03');
              _showToast('即将生成转写与纪要');
            },
          ),
        ],
      ),
    );
  }

  // ==================================== TAB 1: TRANSCRIPTION ====================================
  // Figma 1218:7088 (hover 状态) 规格:
  //   - hover: 发言人 + edit (16x16) + 时间 + ▶ (14px)
  //   - 默认: 发言人 + 时间 (无 edit / ▶)
  //   - 文本行: 14px / 24px lh / 0.0119em / #404040
  // 每条对话使用 _DialogueBlockItem 渲染, hover 状态由内部 MouseRegion 管理
  // 点击 edit: 内联编辑发言人; Enter 保存, blur 失焦保存
  Widget _buildTranscriptionTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _viewModel.dialogues.length,
      itemBuilder: (context, idx) {
        final d = _viewModel.dialogues[idx];
        return _DialogueBlockItem(
          idx: idx,
          dialogue: d,
          isEditingText: _viewModel.editingIndex == idx,
          isBookmarked: _viewModel.bookmarkedLines.contains(idx),
          // 仅在非 frame '14' (弹窗态) 时启用内联编辑, 避免与弹窗冲突
          // 按段落索引 (idx) 区分, 避免同名发言人 (如"发言人1" 出现在多段)
          // 的所有段落同时进入编辑态
          isEditingSpeaker: _viewModel.activeFrame != '14' &&
              _viewModel.editingSpeakerIndex == idx,
          displaySpeaker: _viewModel.speakerMap[d.speaker] ?? d.speaker,
          editTextController: _editTextController,
          speakerInputController: _speakerInputController,
          // 点击 edit: 进入内联编辑态, 填充当前显示名
          onEditSpeaker: () {
            _viewModel.editingSpeakerIndex = idx;
            _speakerInputController.text =
                _viewModel.speakerMap[d.speaker] ?? d.speaker;
          },
          // hover 出现: 点击 ▶ 跳转到此段落并播放当前段落录音 (Figma 1218:7094)
          onPlayParagraph: () {
            _viewModel.seekTo(d.time);
            if (!_viewModel.isPlaying) {
              _viewModel.togglePlay();
            }
            _showToast('已跳转并播放 ${d.timeText} 段落录音');
          },
          onToggleBookmark: () {
            _viewModel.toggleBookmark(idx);
            _showToast(_viewModel.bookmarkedLines.contains(idx)
                ? '已添加重点标记'
                : '已取消标记段落');
          },
          onEditText: () {
            _viewModel.editingIndex = idx;
            _editTextController.text = d.text;
          },
          onSaveText: (newText) {
            _viewModel.updateDialogueText(idx, newText);
            _viewModel.editingIndex = null;
            _showToast('文本编辑成功已保存');
          },
          onCancelText: () {
            _viewModel.editingIndex = null;
          },
          // 内联编辑发言人: 保存新名字, 一键同步到所有同名对话
          onSaveSpeaker: (newName) {
            final trimmed = newName.trim();
            if (trimmed.isNotEmpty &&
                trimmed != (_viewModel.speakerMap[d.speaker] ?? d.speaker)) {
              _viewModel.updateSpeaker(d.speaker, trimmed);
              _showToast('发言人已更新为 "$trimmed"');
            }
            _viewModel.editingSpeakerIndex = null;
          },
          // 显式取消 (目前未直接绑定, 保留接口)
          onCancelSpeaker: () {
            _viewModel.editingSpeakerIndex = null;
          },
        );
      },
    );
  }

  // ==================================== TAB 2: SUMMARY (Figma 1218:7146) ====================================
  // 标题: 24px / 28px lh / #262626
  // Meta: 12px / 18px lh / #A1A1A1 (多行)
  // 章节标题: 20px / 16.5px lh / #262626
  // 思维导图缩略图: 640x374 / #F5F5F5
  // 展开大图: 432px height / #E5E5E5 border
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) 主标题 (Figma 1218:7293 - 24px / #262626)
          const Text(
            '05-07 周会：功能测试规划与项目排期/分工',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              height: 28 / 24,
              letterSpacing: 0.0027,
              fontWeight: FontWeight.w400,
              color: Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 12),

          // 2) Meta 多行信息 (Figma 1218:7294 - 12px / #A1A1A1 / 多行)
          const Text(
            '日期：2049年5月8日\n'
            '地点：齐鲁508\n'
            '参会者：李梅、王强、张伟',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 18 / 12,
              letterSpacing: 0.0139,
              fontWeight: FontWeight.w400,
              color: Color(0xFFA1A1A1),
            ),
          ),
          const SizedBox(height: 20),

          // 3) 章节标题 (Figma 1218:7295 - 20px / #262626)
          const Text(
            '会议纪要',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              height: 16.5 / 20,
              letterSpacing: 0.0032,
              fontWeight: FontWeight.w400,
              color: Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 12),

          // 4) 思维导图缩略图 (Figma 1218:7296 - 640x374 / #F5F5F5)
          _buildSummaryMindmapPreview(),
          const SizedBox(height: 20),

          // 5) 展开大图区 (Figma 1218:7321 - 432px height / #E5E5E5 border)
          _buildSummaryExpandedView(),
        ],
      ),
    );
  }

  // 思维导图缩略图 (Figma 1218:7296)
  Widget _buildSummaryMindmapPreview() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // 简易示意: 中心节点 + 三个分支
          Positioned.fill(
            child: CustomPaint(painter: _MindmapPainter()),
          ),
          // 中心节点
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF262626), width: 1),
              ),
              child: const Text(
                '05-07 周会\n功能测试 / 排期 / 分工',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF262626),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 展开大图区 (Figma 1218:7321)
  Widget _buildSummaryExpandedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 决议与代办 (与底部展开图同宽, 保持一致性)
        const Text(
          '会议结构与决议要点',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            height: 16.5 / 20,
            letterSpacing: 0.0032,
            fontWeight: FontWeight.w400,
            color: Color(0xFF262626),
          ),
        ),
        const SizedBox(height: 12),
        // 决议卡片 (Figma 1218:7321 - 432px height)
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 432),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDecisionRow(
                  '1', '功能测试规划', '完成核心功能回归测试用例库更新与执行, 5月12日前完成 80% 用例覆盖。'),
              const SizedBox(height: 16),
              _buildDecisionRow('2', '项目排期',
                  '研发端采用并行串行混合模式, 测试与开发同步推进, 关键里程碑已锁定 5/15 / 5/22 / 5/30。'),
              const SizedBox(height: 16),
              _buildDecisionRow(
                  '3', '人员分工', '李梅负责功能测试主流程, 王强负责接口与性能压测, 张伟负责回归测试与上线验收。'),
              const SizedBox(height: 16),
              _buildDecisionRow(
                  '4', '风险评估', '第三方支付 SDK 接入存在联调风险, 需提前 3 天完成沙箱联调。'),
              const SizedBox(height: 16),
              _buildDecisionRow(
                  '5', '后续跟进', '下一周会同步测试报告与缺陷修复进度, 关键路径问题升级至项目群处理。'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionRow(String idx, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            idx,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF262626),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF262626),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF737373),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================================== EXPORT: CHOOSE TYPE PANEL ====================================
  Widget _buildChooseExportTypePanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择导出内容',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          const Text('请选择您需要导出的会议产物：',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildExportTypeItem(
            icon: Icons.volume_up_rounded,
            color: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            title: '录音音频',
            desc: '导出 MP3 / WAV 高清原音轨',
            onTap: () => _updateStateForFrame('20'),
          ),
          const SizedBox(height: 12),
          _buildExportTypeItem(
            icon: Icons.file_present_rounded,
            color: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: '完整转写文本',
            desc: '包含发言人与时间戳对照的 PDF 格式',
            onTap: () {
              _showToast('完整文稿 PDF 正在打包下载...');
              _updateStateForFrame('15');
            },
          ),
          const SizedBox(height: 12),
          _buildExportTypeItem(
            icon: Icons.auto_awesome,
            color: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            title: 'AI 智能会议纪要',
            desc: '包含决议、行动项及大纲的 Word (.docx) 文档',
            onTap: () {
              _showToast('智能纪要 Word 文档已生成下载！');
              _updateStateForFrame('15');
            },
          ),
          const SizedBox(height: 12),
          _buildExportTypeItem(
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFFAF5FF),
            iconColor: const Color(0xFFA855F7),
            title: '思维脑图',
            desc: '高清 PNG / SVG 矢量思维脑图大图',
            onTap: () {
              _showToast('已生成高清思维导图大图');
              _updateStateForFrame('15');
            },
          ),
          const Spacer(),
          TalixButton(
            label: '取消',
            variant: TalixButtonVariant.neutralOutline,
            height: 46,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            borderColor: Colors.grey.shade200,
            onPressed: () => _updateStateForFrame('15'),
          )
        ],
      ),
    );
  }

  Widget _buildExportTypeItem({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  // ==================================== EXPORT: CHOOSE FORMAT PANEL ====================================
  Widget _buildAudioFormatSelectPanel() {
    final formats = [
      {'name': 'MP3', 'desc': '高度压缩、体积轻巧，适合日常快速传输分享'},
      {'name': 'WAV', 'desc': '高品质无损音频，保留所有录音人声环境细节'},
      {'name': 'ALAC', 'desc': 'Apple 无损压缩格式，提供极高采样精度'},
      {'name': 'FLAC', 'desc': '高清开源无损音频格式，高压缩率完美音质'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('导出音频格式',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          const Text('选择导出的录音文件编码格式：',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: formats.length,
              itemBuilder: (context, idx) {
                final f = formats[idx];
                final isSelected = _viewModel.exportSelectedFormat == f['name'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () => _viewModel.exportSelectedFormat = f['name']!,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFFF9FAFB) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF111827)
                              : const Color(0xFFF3F4F6),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: isSelected
                                        ? const Color(0xFF111827)
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(f['desc']!,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF111827)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF111827)
                                      : Colors.grey.shade300),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          TalixButton(
            label: '确认导出并下载',
            variant: TalixButtonVariant.dark,
            height: 46,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            backgroundColor: const Color(0xFF111827),
            onPressed: () {
              _showToast(
                  '正在转码打包 (05-07周会.${_viewModel.exportSelectedFormat.toLowerCase()})...');
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (!mounted) return;
                _showToast(
                    '🎉 (05-07周会.${_viewModel.exportSelectedFormat.toLowerCase()}) 音频导出成功已保存本地！');
                _updateStateForFrame('15');
              });
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => _updateStateForFrame('19'),
              child: const Text('返回上一步',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // ==================================== AI Q&A OVERLAY (Figma 1218:9130) ====================================
  // 右侧悬浮面板 (Figma 1218:9335 容器):
  //   - 尺寸: 278x519
  //   - 位置: 右上, right 24 / top 16
  //   - 样式: 白色背景, 顶部圆角 16 (顶左/顶右), 阴影 0 4 4 0 rgba(0,0,0,0.25)
  //   - 状态: 仅在 isAskAiOpen=true 时渲染
  //   - 背景主区仍显示转写/纪要内容 (面板为浮层)
  Widget _buildAskAiOverlay() {
    if (!_viewModel.isAskAiOpen) return const SizedBox.shrink();
    return Positioned(
      right: 24,
      top: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 278,
          height: 519,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000), // rgba(0,0,0,0.25)
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Column(
              children: [
                _buildAiPanelHeader(),
                Expanded(
                  child: _viewModel.chatMessages.isEmpty
                      ? _buildAiWelcomeState()
                      : _buildAiMessageList(),
                ),
                _buildAiInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================================== AI Q&A PANEL CONTENT (Figma 1218:9112) ====================================
  // 严格对齐 Figma 1218:9335 (欢迎页) / 1218:9560 (加载页) / 1218:9716 (详情页)
  //
  // Figma 规范:
  //   - 面板: 圆角 16px 16px 0 0 (顶部圆角), 阴影 0 4 4 0 rgba(0,0,0,0.25)
  //   - Header: "Ask AI" 14px/#262626 + close icon 15.56x15.56 (#000)
  //   - 欢迎页: "有什么可以帮到你?" 16px Bold/#000 + 3 个建议问题 chip
  //     (chip: h=36, fill #D9D9D9, border 1px #DBDBDB, radius 4, padding 6px 8px 6px 12px)
  //   - 关键词 tag: h=36, fill #D9D9D9, radius 4, padding 6px 8px, text 12px/#222
  //   - 加载页: keyword tag + "正在阅读相关转写" 14px/#737373 + loading 图标
  //   - 详情页: keyword tag + AI 回答 (14px/#222, lh 28px, keyword 加粗 700)
  //   - 时间跳转 chip: h=20, padding 2px 6px, fill #D9D9D9, radius 20px
  //   - 输入区: 246x40, fill #FAFAFA, radius 8, padding 8
  // 已废弃: _buildAiChatPanel (全屏版本) - 由 _buildAskAiOverlay 替代

  // Figma 1218:9336 面板头部
  Widget _buildAiPanelHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Ask AI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF262626),
              height: 1.0,
            ),
          ),
          GestureDetector(
            onTap: () {
              _viewModel.closeAskAi();
              _showToast('已关闭 AI 智能体');
            },
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              child:
                  const Icon(Icons.close, size: 14, color: Color(0xFF000000)),
            ),
          ),
        ],
      ),
    );
  }

  // Figma 1218:9354 + 1218:9348-9353 欢迎页
  Widget _buildAiWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎标题 (Figma 1218:9354 - 16px Bold, #000000)
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              '有什么可以帮到你？',
              style: TextStyle(
                fontFamily: 'Microsoft YaHei',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
                height: 1.5,
              ),
            ),
          ),
          // 3 个建议问题 chip (Figma 1218:9348-9353)
          ..._buildSuggestedQuestions(),
        ],
      ),
    );
  }

  // 建议问题列表 (Figma 1218:9348/9350/9352)
  List<Widget> _buildSuggestedQuestions() {
    const questions = [
      '下次会议前需要准备什么？',
      '列出所有待办事项？',
      '总结市场部的反馈？',
    ];
    return questions.map((q) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _handleAskSubmit(q),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 36,
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              border: Border.all(color: const Color(0xFFDBDBDB), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              q,
              style: const TextStyle(
                fontFamily: 'Microsoft YaHei',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF222222),
                height: 1.0,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // 消息列表 (详情页 / 加载页)
  // Figma 1218:9355 详情对话布局:
  //   - 用户消息 (1218:9571 关键词 tag): 顶部靠右 (align centerRight)
  //   - 助手消息 (1218:9573 回答 + 1218:9574 时间跳转): 左侧文字 + 右侧时间 chip
  //   - 加载状态 (1218:9791-9792): 显示在最后一条用户消息之后, 位于助手区
  Widget _buildAiMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _viewModel.chatMessages.length,
      itemBuilder: (context, idx) {
        final msg = _viewModel.chatMessages[idx];
        final isUser = msg['role'] == 'user';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: isUser
              ? _buildUserMessageBubble(msg)
              : _buildAssistantMessageBubble(msg),
        );
      },
    );
  }

  // 用户消息气泡 (Figma 1218:9571 关键词 tag, 顶部靠右)
  Widget _buildUserMessageBubble(Map<String, dynamic> msg) {
    if (msg['keyword'] == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: _buildKeywordTag(msg['keyword']),
    );
  }

  // 助手消息气泡 (Figma 1218:9573 回答 + 1218:9574 时间跳转)
  Widget _buildAssistantMessageBubble(Map<String, dynamic> msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiResponse(msg),
        // 全局加载状态: 在助手消息之后再渲染一次, 保证即使还没有助手消息也能显示
        if (_viewModel.isAiLoading) _buildLoadingIndicator(),
      ],
    );
  }

  // 关键词 tag (Figma 1218:9571 EL-2cea7717: h=36, fill #D9D9D9, radius 4,
  //   padding 6 8, text 12px Microsoft YaHei UI, align center)
  Widget _buildKeywordTag(String keyword) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        keyword,
        style: const TextStyle(
          fontFamily: 'Microsoft YaHei UI',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF222222),
          height: 1.0,
        ),
      ),
    );
  }

  // AI 回答 (Figma 1218:9573)
  // 规范: 12px Microsoft YaHei UI, lh 24px (2.0), color #222222, keyword 加粗 (Figma boldWeight 700)
  // 最大宽度 250, 底部 93%→98% 渐变消失 (从 #000 到 #FFF) 提示更多内容
  Widget _buildAiResponse(Map<String, dynamic> msg) {
    final text = msg['text'] as String;
    final keyword = msg['keyword'] as String?;
    final linkTime = msg['linkTime'] as int?;

    const regularStyle = TextStyle(
      fontFamily: 'Microsoft YaHei UI',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFF222222),
      height: 2.0, // 24/12
    );
    const keywordStyle = TextStyle(
      fontFamily: 'Microsoft YaHei UI',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF222222),
      height: 2.0,
    );

    final spans = <InlineSpan>[];
    if (keyword != null && text.contains(keyword)) {
      // 按 keyword 切分文本, keyword 部分加粗
      final parts = text.split(keyword);
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          spans.add(TextSpan(text: parts[i], style: regularStyle));
        }
        if (i < parts.length - 1) {
          spans.add(TextSpan(text: keyword, style: keywordStyle));
        }
      }
    } else {
      spans.add(TextSpan(text: text, style: regularStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI 回答文字 + 底部 5% 渐变消失 (提示更多内容)
        // ShaderMask + BlendMode.dstIn: 顶部 93% 完全可见, 93%→98% 渐变到透明 (底色为白)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0.0, 0.93, 0.98],
              ).createShader(rect);
            },
            child: RichText(text: TextSpan(children: spans)),
          ),
        ),
        // 时间跳转 chip (Figma 1218:9574: w=64, h=20, padding 2px 6px,
        //   fill #D9D9D9, radius 20, alignItems flex-end, gap 4)
        if (linkTime != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _buildLinkTimeChip(linkTime),
          ),
        ],
      ],
    );
  }

  // 时间跳转 chip (Figma 1218:9574-9579)
  // 规范: 64x20, padding 2 6, fill #D9D9D9, radius 20, alignItems flex-end, gap 4
  // icon ic_goto 16x16 + 文本 "00:15" 12px Microsoft YaHei UI, #222222
  Widget _buildLinkTimeChip(int seconds) {
    final timeText = '00:${seconds.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: () {
        _viewModel.seekTo(seconds);
        _viewModel.activeTab = 'transcription';
        _viewModel.goToFrame('10');
        if (!_viewModel.isPlaying) {
          _viewModel.togglePlay();
        }
        _showToast('已跳转并播放 $timeText 相关录音段落');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 64,
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.play_arrow_rounded,
                size: 16, color: Color(0xFF222222)),
            const SizedBox(width: 4),
            Text(
              timeText,
              style: const TextStyle(
                fontFamily: 'Microsoft YaHei UI',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF222222),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 加载状态 (Figma 1218:9791-9792: 16x16 loading + "正在阅读相关转写" 14px/#737373)
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // loading 图标
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF737373)),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '正在阅读相关转写',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF737373),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // 输入区 (Figma 1218:9341: 246x40, fill #FAFAFA, radius 8, padding 8)
  Widget _buildAiInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatInputController,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF262626),
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                  border: InputBorder.none,
                  hintText: '向AI提问',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFFA1A1A1),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onSubmitted: _handleAskSubmit,
              ),
            ),
            GestureDetector(
              onTap: () => _handleAskSubmit(_chatInputController.text),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: Color(0xFF262626),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================== MODAL: 选择生成方式 (Figma 1218:8489 + 1218:8532) ====================================
  // 共用一张弹窗卡片, 仅 isCustom 不同:
  //   - isCustom=false (frame 03 自动生成): 480x315, 2 个单选行 (auto + custom)
  //   - isCustom=true  (frame 04 自定义生成): 480x507, 额外 4 个配置行 (模版/音频语言/AI模型/翻译语言)
  // 点击配置行会展开右侧侧边面板 (frames 05-08)
  Widget _buildAutoGenerateModal() => _buildGenModalOverlay(isCustom: false);
  Widget _buildCustomGenerateModal() => _buildGenModalOverlay(isCustom: true);

  Widget _buildGenModalOverlay({required bool isCustom}) {
    final showSidePanel =
        isCustom && _viewModel.activeSubScreen != 'none';
    return Positioned.fill(
      child: Stack(
        children: [
          // 半透明背景遮罩 (rgba(0,0,0,0.5))
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // 优先关闭侧边面板, 否则回退到占位页
                if (_viewModel.activeSubScreen != 'none') {
                  _viewModel.activeSubScreen = 'none';
                } else {
                  _viewModel.goToFrame('01');
                }
              },
              child: const ColoredBox(color: Color(0x80000000)),
            ),
          ),
          // 居中: 主弹窗卡片 (+ 侧边面板)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGenModalCard(isCustom: isCustom),
                if (showSidePanel) ...[
                  const SizedBox(width: 16),
                  _buildGenSidePanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 弹窗卡片 (Figma 1218:8491 / 1218:8534)
  Widget _buildGenModalCard({required bool isCustom}) {
    return Container(
      width: 480,
      height: isCustom ? 507 : 315,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 内容主体
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                _buildGenModalRow1Header(),
                const SizedBox(height: 6),
                _buildGenOptionRow(
                  title: '自动生成',
                  desc: '自动生成最匹配的转写与纪要，无需手动设置',
                  isSelected: !isCustom,
                  onTap: () => _viewModel.goToFrame('03'),
                ),
                _buildGenOptionRow(
                  title: '自定义生成',
                  desc: '手动设置模版音频等配置',
                  isSelected: isCustom,
                  onTap: () => _viewModel.goToFrame('04'),
                ),
                if (isCustom) ...[
                  _buildGenSelectorRow(
                    label: '模版',
                    value: _viewModel.customTemplate,
                    onTap: () => _viewModel.goToFrame('05'),
                  ),
                  _buildGenSelectorRow(
                    label: '音频语言',
                    value: _viewModel.customAudioLanguage,
                    onTap: () => _viewModel.goToFrame('06'),
                  ),
                  _buildGenSelectorRow(
                    label: 'AI模型',
                    value: _viewModel.customAiModel,
                    onTap: () => _viewModel.goToFrame('07'),
                  ),
                  _buildGenSelectorRow(
                    label: '翻译语言',
                    value: _viewModel.customTranslationLanguage,
                    onTap: () => _viewModel.goToFrame('08'),
                  ),
                ],
                const Spacer(),
                _buildGenModalActions(),
                const SizedBox(height: 19),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 弹窗 header: "选择生成方式" 18px Bold + 关闭 icon (15.56x15.56)
  Widget _buildGenModalRow1Header() {
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 标题居中
          const Positioned.fill(
            child: Center(
              child: Text(
                '选择生成方式',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                  height: 22 / 18,
                ),
              ),
            ),
          ),
          // 关闭按钮 (右上角, 15.56x15.56, #000 SVG)
          Positioned(
            right: 0,
            top: 3,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _viewModel.goToFrame('01'),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CustomPaint(painter: _CloseIconPainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 弹窗底部操作按钮: "取消" (1px #D1D5DB 描边) + "立即生成" (#18181B 填充, 119 宽)
  Widget _buildGenModalActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 取消
        InkWell(
          onTap: () => _viewModel.goToFrame('01'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '取消',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF18181B),
                height: 20 / 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 立即生成
        InkWell(
          onTap: () => _viewModel.goToFrame('09'),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 119,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '立即生成',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 自动/自定义 单选行 (Figma 1218:8502 / 1218:8510)
  // 规格: 400x64 / padding 8 0 / 1px 底边 #F5F5F5 / 行高 40
  // 选中: 16x16 黑填充 + 白色 "✓" SVG; 未选中: 16x16 空心圆 1px 黑描边
  Widget _buildGenOptionRow({
    required String title,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
          ),
        ),
        child: Row(
          children: [
            // 左: 标题 + 描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 16.5 / 14,
                      letterSpacing: 0.0046 * 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 13.5 / 12,
                      letterSpacing: 0.0139 * 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFA1A1A1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 右: radio 按钮
            _buildRadioIndicator(isSelected: isSelected),
          ],
        ),
      ),
    );
  }

  // 模版/音频/AI/翻译 配置行 (Figma 1218:8563 等 4 行)
  // 规格: 400x40 / padding 8 0 / 1px 底边 #F5F5F5
  // 左: label 14px #404040; 右: value 12px #A1A1A1 + chevron "›" 12px #D4D4D4
  Widget _buildGenSelectorRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 16.5 / 14,
                letterSpacing: 0.0046 * 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF404040),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 15 / 12,
                    letterSpacing: 0.0098 * 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA1A1A1),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '›',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 18 / 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFD4D4D4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Radio 指示器: 选中 = 16x16 黑填充 + 白色 "✓"; 未选中 = 16x16 空心 1px 圆
  Widget _buildRadioIndicator({required bool isSelected}) {
    return SizedBox(
      width: 16,
      height: 16,
      child: isSelected
          ? Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            )
          : Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF000000), width: 1),
              ),
            ),
    );
  }

  // ==================================== MODAL: SIDE PANEL (Figma 1218:8689 / 1218:8799 / 1218:8909 / 1218:8998) ====================================
  // 通用侧边面板: 328x[auto] / #FFFFFF / 8px radius / shadow
  // 内容: 多个 ListFile 行 (296x64 / padding 8 0 / 1px 底边 #F5F5F5)
  // 选中行: 右侧 10x8 黑色 "✓" SVG; 未选中: 右侧空白
  Widget _buildGenSidePanel() {
    final sub = _viewModel.activeSubScreen;
    final List<_SidePanelItem> items;
    final String currentValue;
    final ValueChanged<String> onSelect;

    if (sub == 'template') {
      items = const [
        _SidePanelItem('智能纪要', '多场景自适应摘要，快速提炼要点'),
        _SidePanelItem('会议秘书', '专属助理模版，结构化输出议程与结论'),
        _SidePanelItem('咨询问答', '整理咨询会问答与行动项，快速出纪要'),
        _SidePanelItem('讨论摘要', '聚焦讨论观点与争议点，输出客观摘要'),
        _SidePanelItem('会议报告', '全面会议报告，含背景决议与后续安排'),
        _SidePanelItem('教学课堂', '教学场景模版，突出知识点与互动'),
        _SidePanelItem('访谈整理', '访谈逐字稿整理，自动标注发言人'),
      ];
      currentValue = _viewModel.customTemplate;
      onSelect = (v) {
        _viewModel.customTemplate = v;
        _viewModel.activeSubScreen = 'none';
      };
    } else if (sub == 'audioLang') {
      items = const [
        _SidePanelItem('自动', '系统会自动识别录音语言'),
        _SidePanelItem('中文简体-普通话', '中文(简体-普通话)'),
        _SidePanelItem('English (US)', '英语(美国)'),
        _SidePanelItem('日本語', '日语'),
        _SidePanelItem('Portugues', '葡萄牙语'),
        _SidePanelItem('Francais (France)', '法语(法国)'),
        _SidePanelItem('中文繁體-國語中文', '(繁体-普通话)'),
      ];
      currentValue = _viewModel.customAudioLanguage;
      onSelect = (v) {
        _viewModel.customAudioLanguage = v;
        _viewModel.activeSubScreen = 'none';
      };
    } else if (sub == 'aiModel') {
      items = const [
        _SidePanelItem('自动', '智能匹配适合的模型'),
        _SidePanelItem(
            'GPT-5.5', '适合深度讨论与复杂推理，精准产出详尽、结构化的笔记'),
        _SidePanelItem('Gemini 2.5 Pro', '擅长理解复杂文本，更适合深度内容分析'),
        _SidePanelItem('Claude Sonnet 4.6', '深层逻辑推理，具备卓越的综合分析能力'),
      ];
      currentValue = _viewModel.customAiModel;
      onSelect = (v) {
        _viewModel.customAiModel = v;
        _viewModel.activeSubScreen = 'none';
      };
    } else {
      // translateLang
      items = const [
        _SidePanelItem('不翻译', '使用原文'),
        _SidePanelItem('中文简体-普通话', '中文(简体-普通话)'),
        _SidePanelItem('English (US)', '英语(美国)'),
        _SidePanelItem('日本語', '日语'),
        _SidePanelItem('Portugues', '葡萄牙语'),
        _SidePanelItem('Francais (France)', '法语(法国)'),
        _SidePanelItem('中文繁體-國語中文', '(繁体-普通话)'),
      ];
      currentValue = _viewModel.customTranslationLanguage;
      onSelect = (v) {
        _viewModel.customTranslationLanguage = v;
        _viewModel.activeSubScreen = 'none';
      };
    }

    return Container(
      width: 328,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 120,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            final isLast = idx == items.length - 1;
            return _buildSidePanelRow(
              title: item.title,
              desc: item.desc,
              isSelected: item.title == currentValue,
              isLast: isLast,
              onTap: () => onSelect(item.title),
            );
          },
        ),
      ),
    );
  }

  // 侧边面板单行 (Figma 1218:8750 等 7 行模板)
  // 规格: 296x64 / padding 8 16 / 1px 底边 #F5F5F5 (末行无)
  // 左: 标题 14px #262626 + 描述 12px #A1A1A1; 右: 选中时 10x8 黑色 "✓"
  Widget _buildSidePanelRow({
    required String title,
    required String desc,
    required bool isSelected,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 16.5 / 14,
                      letterSpacing: 0.0046 * 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 13.5 / 12,
                      letterSpacing: 0.0139 * 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFA1A1A1),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) _buildCheckMark(),
          ],
        ),
      ),
    );
  }

  // 选中态 ✓: 10x8 黑色 "✓" SVG (Figma #1218:8756 等)
  Widget _buildCheckMark() {
    return SizedBox(
      width: 10,
      height: 8,
      child: CustomPaint(painter: _CheckMarkPainter()),
    );
  }

  // ==================================== OVERLAY: GENERATING PROGRESS ====================================
  Widget _buildGeneratingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
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
                      color: Color(0xFF10B981), strokeWidth: 4),
                ),
                const SizedBox(height: 20),
                const Text('AI 智能排程生成中...',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('拼尽全力处理音频数据，完成进度：${_viewModel.generationProgress}%',
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
          ),
        ),
      ),
    );
  }

  // ==================================== OVERLAY: SPEAKER EDIT ====================================
  Widget _buildSpeakerEditDialog() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('重命名发言人',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('修改发言人名称，将对所有对应的文稿对话一键同步生效。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12)),
                  child: TextField(
                    controller: _speakerInputController,
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
                        onPressed: () => _viewModel.editingSpeakerKey = null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TalixButton(
                        label: '一键修改',
                        height: 44,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        onPressed: () {
                          _viewModel.updateSpeaker(
                              _viewModel.editingSpeakerKey!,
                              _speakerInputController.text);
                          _viewModel.editingSpeakerKey = null;
                          _showToast('一键同步修改发言人成功！');
                          _updateStateForFrame('10');
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================================== OVERLAY: MORE DOTS DROPDOWN ====================================
  Widget _buildEllipsisDropdown() {
    return Positioned(
      top: kToolbarHeight + 8,
      right: 12,
      child: Material(
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
              _buildDropdownItem(Icons.autorenew_rounded, '重新转写', () {
                _viewModel.isMenuOpen = false;
                _updateStateForFrame('03');
              }),
              _buildDropdownItem(Icons.edit_outlined, '重命名', () {
                _viewModel.isMenuOpen = false;
                _updateStateForFrame('17');
              }),
              _buildDropdownItem(Icons.share_outlined, '分享', () {
                _viewModel.isMenuOpen = false;
                _updateStateForFrame('18');
              }),
              _buildDropdownItem(Icons.download_outlined, '导出', () {
                _viewModel.isMenuOpen = false;
                _updateStateForFrame('19');
              }),
              const Divider(height: 10, color: Color(0xFFF3F4F6)),
              _buildDropdownItem(Icons.delete_forever_outlined, '移至回收站', () {
                _viewModel.isMenuOpen = false;
                _showToast('文件已移至系统回收站中');
                Navigator.pop(context);
              }, isRed: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(IconData icon, String label, VoidCallback onTap,
      {bool isRed = false}) {
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
                fontSize: 11,
                color: isRed ? Colors.redAccent : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================== OVERLAY: RENAME FILE ====================================
  // Figma 1218-8517
  // 规格:
  //   - modal-card: 480x315, #FFFFFF, 8px radius, shadow (0 4 4 rgba(0,0,0,0.25))
  //   - backdrop: rgba(0,0,0,0.5) 全屏 + 点击关闭
  //   - title row (1218:8520): 标题 "重命名文件" (Inter Bold 18px #18181B) + 关闭 icon (15.56x15.56 #000)
  //   - text input (1218:8530): 400x128, 1px #E5E5E5 stroke, 4px radius
  //     padding 10 8 0 8; 文字 Inter 14px / 15px lh / 0.0084em / #0A0A0A; 顶对齐
  //   - actions (1218:8525): 右对齐, gap 12
  //     取消 (1218:8526): padding 10 20, 1px #D1D5DB stroke, 6px radius, #18181B 文字
  //     保存 (1218:8528): width 119, #18181B bg, 6px radius, #FFFFFF 文字
  // 布局: padding 40 / 40 / 40 / 29 → 内容总高 ~246 → 弹窗总高 ~315
  Widget _buildRenameOverlay() {
    final controller = TextEditingController(text: _viewModel.renameValue);
    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop: 全屏半透明 + 点击关闭 (Figma 1218:8518)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _viewModel.isRenameOpen = false,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          // Modal card 居中
          Center(
            child: Container(
              width: 480,
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 29),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000), // rgba(0,0,0,0.25)
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题行 (Figma 1218:8520): 标题 + 关闭 icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title (Figma 1218:8521: Inter Bold 18px #18181B)
                      const Text(
                        '重命名文件',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      // Close icon (Figma 1218:8522: Union 15.56x15.56 #000)
                      // 加 InkWell + 4px 内边距 → 命中区更大, 接近 16x16
                      InkWell(
                        onTap: () => _viewModel.isRenameOpen = false,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Text input (Figma 1218:8530: 400x128, 1px #E5E5E5, 4px radius)
                  // height 128 + expands + maxLines null → 多行可滚动; 文本顶对齐
                  Container(
                    height: 128,
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.0,
                        letterSpacing: 0.0084 * 14,
                        color: Color(0xFF0A0A0A),
                      ),
                      cursorColor: const Color(0xFF18181B),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Actions (Figma 1218:8525): 右对齐, gap 12
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 取消 button (Figma 1218:8526)
                      InkWell(
                        onTap: () => _viewModel.isRenameOpen = false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF18181B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 保存 button (Figma 1218:8528: width 119, #18181B bg)
                      InkWell(
                        onTap: () {
                          _viewModel.renameValue = controller.text;
                          _viewModel.isRenameOpen = false;
                          _showToast('重命名成功！');
                          _updateStateForFrame('10');
                        },
                        child: Container(
                          width: 119,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '保存',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================== OVERLAY: SHARE FILE ====================================
  // Figma 1218-8591
  // 规格:
  //   - modal-card: 480x440, #FFFFFF, 8px radius, shadow
  //   - backdrop: rgba(0,0,0,0.5) 全屏 + 点击关闭
  //   - title row (1218:8594): 标题 "分享" (Inter Bold 18px #18181B) + 关闭 icon
  //   - subtitle (1218:8624): "通过链接分享" (Inter Regular 16px / 16.5 lh / 0.004em / #262626)
  //   - description (1218:8623): "任何拥有链接的人..." (Inter Regular 14px / 13.5 lh / 0.0119em / #A1A1A1)
  //   - 4 toggle rows (1218:8604/8609/8614/8619): y 161.5/209.5/258/306, 400x40, 1px #F5F5F5 下边框
  //     - 录音 (audio): 必含, 始终选中
  //     - 转写 (transcription): 默认选中
  //     - 纪要 (summary): 默认选中
  //     - 思维导图 (mindmap): 默认未选
  //   - actions (1218:8599): 右对齐, gap 12
  //     - 复制链接 (1218:8600): padding 10 20, 1px #D1D5DB stroke, 6px radius
  //     - 分享链接 (1218:8602): width 119, #18181B bg, 6px radius
  Widget _buildShareOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop: 全屏半透明 + 点击关闭 (Figma 1218:8592)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _viewModel.isShareOpen = false,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          // Modal card 居中
          Center(
            child: Container(
              width: 480,
              height: 440,
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 29),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000), // rgba(0,0,0,0.25)
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题行 (Figma 1218:8594)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title (Figma 1218:8595: Inter Bold 18px #18181B)
                      const Text(
                        '分享',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      // Close icon (Figma 1218:8596: Union 15.56x15.56 #000)
                      InkWell(
                        onTap: () => _viewModel.isShareOpen = false,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Subtitle "通过链接分享" (Figma 1218:8624)
                  const Text(
                    '通过链接分享',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      height: 16.5 / 16,
                      letterSpacing: 0.004 * 16,
                      color: Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description (Figma 1218:8623)
                  const Text(
                    '任何拥有链接的人都可以查看此文件，链接有效期为7天',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 13.5 / 14,
                      letterSpacing: 0.0119 * 14,
                      color: Color(0xFFA1A1A1),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 4 toggle rows (录音 / 转写 / 纪要 / 思维导图)
                  _buildShareToggleRow('audio', '录音', isPrimary: true),
                  _buildShareToggleRow('transcription', '转写'),
                  _buildShareToggleRow('summary', '纪要'),
                  _buildShareToggleRow('mindmap', '思维导图'),
                  const Spacer(),
                  // Actions (Figma 1218:8599)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 复制链接 button (Figma 1218:8600)
                      InkWell(
                        onTap: () {
                          _viewModel.isShareOpen = false;
                          _showToast('链接已复制到粘贴板');
                          _updateStateForFrame('10');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '复制链接',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF18181B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 分享链接 button (Figma 1218:8602: width 119, #18181B bg)
                      InkWell(
                        onTap: () {
                          _viewModel.isShareOpen = false;
                          _showToast('🎉 分享链接已生成');
                          _updateStateForFrame('10');
                        },
                        child: Container(
                          width: 119,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '分享链接',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 单条分享 toggle 行 (Figma 1218:8604/8609/8614/8619)
  // 规格: 400x40, padding 8 0, 1px #F5F5F5 下边框
  //   - 文字: Inter Regular 14px / 16.5 lh / 0.0046em / #404040
  //   - 选中: 16x16 黑色填充圆 + 8x6 白色 ✓
  //   - 未选: 16x16 黑色 1px 描边空心圆
  // isPrimary=true: 必含项, 不可切换 (如 "录音")
  Widget _buildShareToggleRow(String key, String label,
      {bool isPrimary = false}) {
    final isChecked =
        isPrimary || _viewModel.shareCheckedOptions.contains(key);
    return InkWell(
      onTap: isPrimary ? null : () => _viewModel.toggleShareOption(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 16.5 / 14,
                letterSpacing: 0.0046 * 14,
                color: isPrimary
                    ? const Color(0xFF404040)
                    : const Color(0xFF404040),
              ),
            ),
            // 选中: 黑底圆 + 白勾; 未选: 空心圆
            isChecked
                ? Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF000000),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF000000), width: 1),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ==================================== OVERLAY: EXPORT FILE ====================================
  // Figma 1218-8625
  // 规格:
  //   - modal-card: 480x398, #FFFFFF, 8px radius, shadow (0 4 4 rgba(0,0,0,0.25))
  //   - backdrop: rgba(0,0,0,0.5) 全屏 + 点击关闭
  //   - title (1218:8629): "导出" (Inter Bold 18px #18181B) + 关闭 icon (1218:8630 15.56x15.56 #000)
  //   - 4 rows (1218:8633/8640/8647/8654): y 102/150/198/246, 400x40, padding 8 0, 1px #F5F5F5 下边框
  //     录音 (audio): 默认未选, 右侧 "MP3" + ›
  //     转写 (transcription): 默认选中, 右侧 "TXT" + ›
  //     纪要 (summary): 默认选中, 右侧 "TXT" + ›
  //     思维导图 (mindmap): 默认选中, 右侧 "PNG" + ›
  //     - 文字: Inter Regular 14px / 16.5 lh / 0.0046em / #404040
  //     - 选中: 16x16 黑色填充圆角方块 + 8x6 白色 ✓
  //     - 未选: 16x16 1px 黑色描边圆角方块
  //     - 右侧格式文字: Inter Regular 12px / 15 lh / 0.0098em / right align / #A1A1A1
  //   - actions (1218:8661): 右对齐, gap 12
  //     取消 (1218:8662): padding 10 20, 1px #D1D5DB stroke, 6px radius, #18181B 文字
  //     导出 (1218:8664): width 119, #18181B bg, 6px radius, #FFFFFF 文字
  // 侧边面板 (1218:8666): 328x[auto] 在主弹窗右侧 (gap 16), 8px 圆角 + 阴影
  //   - 仅在 _exportOpenPanel != null 时显示 (其它项只有单一格式, 不可点)
  //   - 3 行 ListFile: MP3 (默认选中) / WAV / Alac, 选中行右侧 10x8 黑色 ✓
  //   - 列表行: 296x40, padding 8 0, 1px #F5F5F5 下边框, gap 8
  //   - 文字: Inter Regular 14px / 16.5 lh / 0.0046em / #262626
  Widget _buildExportOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop: 全屏半透明 + 点击关闭 (Figma 1218:8626)
          // 当侧边面板打开时, 优先级: 先关闭侧边面板, 再关闭弹窗
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_viewModel.exportOpenPanel != null) {
                  _viewModel.closeExportFormatPanel();
                } else {
                  _viewModel.isExportOpen = false;
                }
              },
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          // 整体水平垂直居中: 主弹窗 + (可选) 侧边面板 (gap 16)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 主弹窗 modal-card (Figma 1218:8627: 480x398)
                Container(
                  width: 480,
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 29),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000), // rgba(0,0,0,0.25)
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标题行 (Figma 1218:8628): "导出" 居中 + 关闭 icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 居中标题 (1218:8629: Inter Bold 18px #18181B)
                          const Text(
                            '导出',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18181B),
                            ),
                          ),
                          // 右侧关闭 icon (1218:8630: 15.56x15.56 #000)
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () => _viewModel.isExportOpen = false,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      // 4 toggle rows (Figma 1218:8633/8640/8647/8654)
                      _buildExportOptionRow('audio', '录音'),
                      _buildExportOptionRow('transcription', '转写'),
                      _buildExportOptionRow('summary', '纪要'),
                      _buildExportOptionRow('mindmap', '思维导图'),
                      const SizedBox(height: 12),
                      // Actions (Figma 1218:8661)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 取消 button (1218:8662)
                          InkWell(
                            onTap: () => _viewModel.isExportOpen = false,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFD1D5DB)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '取消',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF18181B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 导出 button (1218:8664: width 119, #18181B bg)
                          InkWell(
                            onTap: () {
                              final selected =
                                  _viewModel.exportCheckedOptions.join(', ');
                              _viewModel.isExportOpen = false;
                              _showToast('🎉 导出已开始: $selected');
                              _updateStateForFrame('10');
                            },
                            child: Container(
                              width: 119,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF18181B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '导出',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 主弹窗与侧边面板间距 (Figma: gap 16)
                if (_viewModel.exportOpenPanel != null) ...[
                  const SizedBox(width: 16),
                  // 侧边面板: 格式选择 (Figma 1218:8666: 328x[auto])
                  _buildExportFormatPanel(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 单条导出项 row (Figma 1218:8633/8640/8647/8654)
  // 规格: 400x40, padding 8 0, 1px #F5F5F5 下边框
  //   - 左: 16x16 圆角方块 checkbox + 14px 文字 (label)
  //   - 右: 12px 格式文字 + 12x12 chevron › (点击打开侧边面板, 仅多格式时)
  Widget _buildExportOptionRow(String key, String label) {
    final isChecked = _viewModel.exportCheckedOptions.contains(key);
    final format = _viewModel.exportFormats[key] ?? '';
    final options = _viewModel.exportFormatOptionsFor(key);
    final canOpenPanel = options.length > 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左侧: 勾选方块 + 文字
          Row(
            children: [
              InkWell(
                onTap: () => _viewModel.toggleExportOption(key),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFF000000)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF000000),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isChecked
                      ? CustomPaint(
                          size: const Size(8, 6),
                          painter: _ExportCheckMarkPainter(strokeColor: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 16.5 / 14,
                  letterSpacing: 0.0046 * 14,
                  color: Color(0xFF404040),
                ),
              ),
            ],
          ),
          // 右侧: 格式文字 + chevron › (点击打开侧边面板)
          InkWell(
            onTap: canOpenPanel
                ? () {
                    if (_viewModel.exportOpenPanel == key) {
                      _viewModel.closeExportFormatPanel();
                    } else {
                      _viewModel.openExportFormatPanel(key);
                    }
                  }
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  format,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 15 / 12,
                    letterSpacing: 0.0098 * 12,
                    color: Color(0xFFA1A1A1),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '›',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 18 / 12,
                    color: Color(0xFFD4D4D4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 导出侧边面板 (Figma 1218:8666)
  // 规格: 328 wide, 自适应高, 8px 圆角 + 阴影 + 白色
  // 内容: 3 行 ListFile, 每行 296x40, padding 8 0, 1px #F5F5F5 下边框
  //   - 文字 (Inter 14px / 16.5 lh / 0.0046em / #262626) + 10x8 黑色 ✓ (选中行)
  Widget _buildExportFormatPanel() {
    final key = _viewModel.exportOpenPanel!;
    final options = _viewModel.exportFormatOptionsFor(key);
    final current = _viewModel.exportFormats[key] ?? '';
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 328,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000), // rgba(0,0,0,0.25)
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < options.length; i++)
              _buildExportFormatRow(key, options[i], current,
                  isLast: i == options.length - 1),
          ],
        ),
      ),
    );
  }

  // 侧边面板中单行 (Figma 1218:8668/8675/8682)
  // 规格: 296x40, padding 8 0, 1px #F5F5F5 下边框 (最后一行无)
  //   - 左: 文字 (Inter 14px / 16.5 lh / 0.0046em / #262626)
  //   - 右: 10x8 黑色 ✓ (选中时)
  Widget _buildExportFormatRow(
      String key, String format, String currentFormat,
      {required bool isLast}) {
    final isSelected = format == currentFormat;
    return InkWell(
      onTap: () => _viewModel.setExportFormat(key, format),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              format,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 16.5 / 14,
                letterSpacing: 0.0046 * 14,
                color: Color(0xFF262626),
              ),
            ),
            if (isSelected)
              CustomPaint(
                size: const Size(10, 8),
                painter: _ExportCheckMarkPainter(strokeColor: const Color(0xFF000000)),
              ),
          ],
        ),
      ),
    );
  }
}

// 导出复选框内/侧边面板选中态 ✓ (Figma 1218:6524a2b4 + 1218:8674)
// 8x6 (选中框内) 或 10x8 (侧边面板), 颜色: 白色 (选中框内) / 黑色 (侧边面板)
class _ExportCheckMarkPainter extends CustomPainter {
  final Color strokeColor;
  _ExportCheckMarkPainter({this.strokeColor = Colors.white});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeColor == Colors.white ? 1 : 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// 单条对话块 (Figma 1218:7088)
// 状态: _isHovered 由 MouseRegion 控制
// 行为:
//   - 默认 (非 hover): 仅显示发言人 + 时间
//   - hover: 额外显示 edit (16x16) + ▶ (14px) 两个操作按钮
//   - 第一个段落 (idx == 0) 保留右侧的收藏 / 编辑文本按钮
//   - 点击 edit: 发言人位置变为内联 TextField (自动聚焦, Enter 保存, blur 取消)
// ============================================================
class _DialogueBlockItem extends StatefulWidget {
  final int idx;
  final DialogueBlock dialogue;
  final bool isEditingText;
  final bool isBookmarked;
  final bool isEditingSpeaker;
  final String displaySpeaker;
  final TextEditingController editTextController;
  final TextEditingController speakerInputController;
  final VoidCallback onEditSpeaker;
  final VoidCallback onPlayParagraph;
  final VoidCallback onToggleBookmark;
  final VoidCallback onEditText;
  final ValueChanged<String> onSaveText;
  final VoidCallback onCancelText;
  final ValueChanged<String> onSaveSpeaker;
  final VoidCallback onCancelSpeaker;

  const _DialogueBlockItem({
    super.key,
    required this.idx,
    required this.dialogue,
    required this.isEditingText,
    required this.isBookmarked,
    required this.isEditingSpeaker,
    required this.displaySpeaker,
    required this.editTextController,
    required this.speakerInputController,
    required this.onEditSpeaker,
    required this.onPlayParagraph,
    required this.onToggleBookmark,
    required this.onEditText,
    required this.onSaveText,
    required this.onCancelText,
    required this.onSaveSpeaker,
    required this.onCancelSpeaker,
  });

  @override
  State<_DialogueBlockItem> createState() => _DialogueBlockItemState();
}

class _DialogueBlockItemState extends State<_DialogueBlockItem> {
  // Figma 1218:7088: hover 时显示 edit + ▶ 按钮
  bool _isHovered = false;

  // 内联编辑发言人时的 FocusNode, 用于在 save/cancel 后主动失焦
  final FocusNode _speakerFocusNode = FocusNode();

  @override
  void dispose() {
    _speakerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) {
        // 失焦时: 如果在内联编辑发言人, 则取消 (避免 blur 后状态错乱)
        if (widget.isEditingSpeaker) {
          // 不在 onExit 里清状态, 避免与 TextField 内部点击冲突
        }
        setState(() => _isHovered = false);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 行1: header (发言人 + [hover]edit + 时间 + [hover]▶)
            // Figma 1218-8115 (EL-f1b2d507) 规格:
            //   - row, gap 10px
            //   - 间距: 发言人 ↔ 时间 = 10px (Figma 转写标记布局)
            //   - hover 时 edit 插入 发言人↔edit↔时间, play 插入 时间↔play↔Spacer
            //   - 每对相邻元素之间 10px
            // 行高 20: 匹配 Figma 1218-7520 编辑输入框 (86x20), 避免 20px 字段溢出 16px 行
            // 导致视觉上字段顶部高于时间/play 图标 (居中错位).  非编辑态元素 (12-14px)
            // 居中于 20px 行, 上下各 2-3px 留白.
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  // 发言人: 内联编辑态 -> TextField; 否则 -> 普通文本
                  if (widget.isEditingSpeaker)
                    _buildInlineSpeakerEditor()
                  else
                    Text(
                      widget.displaySpeaker,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 13.5 / 12,
                        letterSpacing: 0.0139 * 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF404040),
                      ),
                    ),
                  // Figma 1218:7091: hover 时显示的 edit 图标 (16x16 / #000)
                  // 非内联编辑态时才显示, 避免与 TextField 重复
                  // 与前一元素间隔 10px
                  if (_isHovered && !widget.isEditingSpeaker) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: widget.onEditSpeaker,
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ],
                  // 时间 (12px / 13.5px lh / 0.0139em / #A1A1A1)
                  // 与前一元素间隔 10px (发言人 或 hover 时的 edit)
                  const SizedBox(width: 10),
                  Text(
                    widget.dialogue.timeText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 13.5 / 12,
                      letterSpacing: 0.0139 * 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFA1A1A1),
                    ),
                  ),
                  // Figma 1218:7094 / 1218:7678: ▶ 按钮 (14px / 15px lh / 0.0084em / #000)
                  // 显示条件: hover 时 或 编辑态时
                  //   - hover (非编辑): 显示供快速播放
                  //   - 编辑: 始终显示 (Figma 1218:7667 编辑字段旁必有 ▶)
                  if (_isHovered || widget.isEditingSpeaker) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: widget.onPlayParagraph,
                      child: const Text(
                        '▶',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          height: 15 / 14,
                          letterSpacing: 0.0084 * 14,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // 右侧操作: 收藏 / 编辑文本 (Figma 1218-7520 编辑态下隐藏)
                  if (widget.idx == 0 && !widget.isEditingSpeaker)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            widget.isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                            size: 14,
                          ),
                          color: widget.isBookmarked
                              ? const Color(0xFF10B981)
                              : Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onToggleBookmark,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_note,
                              size: 16, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onEditText,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 行2: body (对话文本 / 编辑态 TextField)
            if (widget.isEditingText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: widget.editTextController,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 24 / 14,
                      letterSpacing: 0.0119 * 14,
                      color: Color(0xFF404040),
                    ),
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onCancelText,
                        child: const Text('取消',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ),
                      TalixButton(
                        label: '保存',
                        variant: TalixButtonVariant.dark,
                        size: TalixButtonSize.small,
                        expand: false,
                        fontSize: 11,
                        backgroundColor: const Color(0xFF262626),
                        onPressed: () {
                          widget
                              .onSaveText(widget.editTextController.text);
                        },
                      ),
                    ],
                  )
                ],
              )
            else
              // 文本内容 (14px / 24px lh / 0.0119em / #404040)
              Text(
                widget.dialogue.text,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 24 / 14,
                  letterSpacing: 0.0119 * 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF404040),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 内联编辑发言人: 圆角输入框 (Figma 1218:7669)
  // 规格: 86x20 容器, 1px #000 border, 4px radius
  //   - padding 8 0 8 8 (左 8, 上下 8, 右 0)
  //   - 文字 12px / #000 (style_c487cf45)
  //   - 光标 2x16 / #000 (Figma 1218:7671)
  //   - autofocus: 点击 edit 立即聚焦
  // 触发保存的 3 个时机:
  //   - onSubmitted: 按 Enter / Done
  //   - onTapOutside: 点击外部失焦
  //   - onEditingComplete: 键盘收起
  Widget _buildInlineSpeakerEditor() {
    return Container(
      width: 86,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF000000), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: widget.speakerInputController,
        focusNode: _speakerFocusNode,
        autofocus: true,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: Color(0xFF000000),
        ),
        cursorColor: const Color(0xFF000000),
        cursorWidth: 2,
        cursorHeight: 16,
        textAlignVertical: TextAlignVertical.center,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          isCollapsed: true,
          contentPadding: EdgeInsets.fromLTRB(8, 0, 0, 0),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        onSubmitted: widget.onSaveSpeaker,
        onTapOutside: (_) {
          widget.onSaveSpeaker(widget.speakerInputController.text);
        },
        onEditingComplete: () {
          widget.onSaveSpeaker(widget.speakerInputController.text);
        },
      ),
    );
  }
}
