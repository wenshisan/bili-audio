import 'package:flutter/material.dart';
import '../viewmodels/ask_ai_viewmodel.dart';
import '../widgets/file_list_widgets.dart';

// ============================================================
// Ask AI 智能问答 (Figma 1218:9580 home / 1218:9725 loading / 1218:9652 response - 薄 View)
// 布局:
//   - home:     居中标题 + 3 个建议 chips + 底部输入栏
//   - loading:  topic chip(右上) + 加载圆+文本(左下) + 底部输入栏
//   - response: topic chip(右上) + AI 响应文本(含内联加粗) + 底部输入栏
// 状态: 输入文本 + isLoading + activeQuery + response (在 ViewModel)
// UI-only: TextEditingController (一次性)
// ============================================================
class AskAiScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AskAiScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  late final AskAiViewModel _viewModel;
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _viewModel = AskAiViewModel();
    _inputController = TextEditingController();
    _inputController.addListener(_syncInput);
  }

  @override
  void dispose() {
    _inputController.removeListener(_syncInput);
    _inputController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _syncInput() {
    _viewModel.chatInput = _inputController.text;
  }

  void _submit() {
    final String query = _inputController.text.trim();
    if (query.isEmpty) return;
    _viewModel.submitQuery(query);
    _inputController.clear();
  }

  void _fillFromSuggestion(String text) {
    _inputController.text = text;
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaTokens.surfaceWhite,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.isLoading) return _buildLoadingState();
            if (_viewModel.hasResponse) return _buildResponseState();
            return _buildHomeState();
          },
        ),
      ),
    );
  }

  // --- Figma 1218:9580 home state ---
  Widget _buildHomeState() {
    return Column(
      children: [
        const Spacer(flex: 2),
        // Figma 1218:9651: 标题 "有什么可以帮到你？" 32px Bold
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '有什么可以帮到你？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: FigmaTokens.primary,
              height: 24 / 32,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Figma 1218:9645/9647/9649: 3 个建议 chips
        // 40px 高, 1px #DBDBDB 边框, 4px 圆角, 透明背景
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _viewModel.suggestions
              .map((s) => _SuggestionChip(
                    text: s,
                    onTap: () => _fillFromSuggestion(s),
                  ))
              .toList(),
        ),
        const Spacer(flex: 3),
        // Figma 1218:9639: 底部输入栏
        _buildBottomInputBar(),
      ],
    );
  }

  // --- Figma 1218:9725 loading state ---
  Widget _buildLoadingState() {
    final String topicText = _viewModel.activeQuery.isNotEmpty
        ? _viewModel.activeQuery
        : AskAiViewModel.defaultTopic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        // Figma 1218:9789: topic chip (右上对齐)
        // 40px 高, #D9D9D9 背景, 4px 圆角, 6px 8px 内边距
        // 文字 14px Inter #222222
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: _TopicChip(text: topicText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Figma 1218:9791/9792: loading 圆 (16x16) + "正在阅读相关转写"
        // 文字 14px Inter Regular #A1A1A1, 行高 15px, 字间距 0.0084em
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FigmaTokens.textMuted,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '正在阅读相关转写',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: FigmaTokens.textMuted,
                  height: 15 / 14,
                  letterSpacing: 0.0084,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Figma 1218:9784: 底部输入栏 (与 home 一致)
        _buildBottomInputBar(),
      ],
    );
  }

  // --- Figma 1218:9652 response state ---
  Widget _buildResponseState() {
    final String topicText = _viewModel.activeQuery.isNotEmpty
        ? _viewModel.activeQuery
        : AskAiViewModel.defaultTopic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        // Figma 1218:9716: topic chip (右上对齐, 与 loading 一致)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: _TopicChip(text: topicText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Figma 1218:9718: AI 响应文本
        // 14px Inter, lineHeight 28px, 颜色 #222222
        // 内联加粗: topic 部分 (如"智能水杯") 700, 其余 400
        // 文本内容: "关于{topic}的会议记录如下：\n05-06 产品组会：用户增长测试与方案讨论"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _buildResponseText(topicText),
        ),
        const Spacer(),
        _buildBottomInputBar(),
      ],
    );
  }

  // Figma 1218:9718: AI 响应 RichText, 内联加粗 topic
  Widget _buildResponseText(String topic) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Color(0xFF222222),
          height: 28 / 14,
        ),
        children: [
          const TextSpan(text: AskAiViewModel.topicPrefix),
          TextSpan(
            text: topic,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: AskAiViewModel.suffix),
        ],
      ),
    );
  }

  Widget _buildBottomInputBar() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _InputBar(
            controller: _inputController,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

// 建议 chip (Figma 1218:9645/9647/9649)
// 40px 高, 1px #DBDBDB 边框, 4px 圆角, 透明背景
// 文字 14px Inter #222222
class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: const Color(0xFFDBDBDB), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF222222),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// Topic chip (Figma 1218:9789)
// 40px 高, #D9D9D9 背景, 4px 圆角, 6px 8px 内边距
// 文字 14px Inter #222222
class _TopicChip extends StatelessWidget {
  final String text;
  const _TopicChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF222222),
          height: 1.0,
        ),
      ),
    );
  }
}

// 底部输入栏 (Figma 1218:9639/9784)
// 640x64, #EEEEEE 背景, 8px 圆角, 8px 内边距
// 占位符 "向AI提问" 14px Inter #000000
// 右侧 24x24 发送 icon (prime:send → Icons.send_rounded)
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _InputBar({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FigmaTokens.highlight, // #EEEEEE
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSubmit(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
              decoration: const InputDecoration(
                hintText: '向AI提问',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onSubmit,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: const Icon(
                Icons.send_rounded,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
