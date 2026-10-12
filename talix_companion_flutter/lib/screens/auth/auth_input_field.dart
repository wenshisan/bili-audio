import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'auth_assets.dart';

// ============================================================
// AuthInputField (Figma 669:4640 / 669:4643 / 669:5096)
// input-container: 高 48, padding 0 16, gap 12, 白底,
//                  1px rgba(0,0,0,0.1) 描边, 4px 圆角
// 文字: 14px Regular #333333, placeholder #999999
// 密码类型右侧带 24×24 eye / eye-off 切换图标 (无前置图标)
// 宽度默认撑满父容器 (卡片内容区 360)
// ============================================================
enum AuthInputKind { email, password, text }

class AuthInputField extends StatefulWidget {
  final AuthInputKind kind;
  final String placeholder;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  /// 校验失败时显示的错误文案 (12px #FF6801, 显示在输入框下方 8px 处)
  final String? errorText;

  /// 输入框圆角, 默认 4px; SetPasswordScreen 使用 8px (Figma EL-3d08350b)
  final double borderRadius;

  const AuthInputField({
    super.key,
    required this.kind,
    required this.placeholder,
    required this.controller,
    this.onChanged,
    this.obscureText = false,
    this.errorText,
    this.borderRadius = 4,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  late bool _obscure;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: hasError
                  ? const Color(0xFFFF6801)
                  : _isFocused
                      ? const Color(0xFF39D03D)
                      : const Color(0x1A000000), // rgba(0,0,0,0.1)
              width: 1,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: _obscure,
                  onChanged: widget.onChanged,
                  keyboardType: widget.kind == AuthInputKind.email
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                  cursorColor: const Color(0xFF39D03D),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.placeholder,
                    hintStyle: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),
              if (widget.kind == AuthInputKind.password) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.string(
                    _obscure ? AuthAssets.eyeOff : AuthAssets.eye,
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFFFF6801),
            ),
          ),
        ],
      ],
    );
  }
}
