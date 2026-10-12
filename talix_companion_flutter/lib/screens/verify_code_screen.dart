import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_api.dart';
import '../services/storage/token_storage.dart';
import '../widgets/app_toast.dart';
import 'auth/auth_card_scaffolding.dart';
import 'auth/auth_widgets.dart';
import 'set_password_screen.dart';

// ============================================================
// VerifyMode: 区分注册流程与找回密码流程
// register: 验证后进入 SetPasswordScreen,完成后 pop 回 LoginScreen
// forgot:   验证后进入 SetPasswordScreen,完成后 pop 回 LoginScreen
// ============================================================
enum VerifyMode { register, forgot }

// ============================================================
// VerifyCodeScreen (Figma 669:5298)
// 440×600 卡片 — 品牌区 → [标题"输入验证码" + "验证码已发送至 xxx"(绿)] (gap 12)
// → gap 48 → [6 个 52×56 方格 (gap 8) + "没有收到？重新发送"] (gap 24)
// → gap 48 → [绿色"验证"按钮 → gap 20 → "返回登录" (灰)]
//
// 流程: 输入 6 位验证码 → POST /checkPinpointVerifyCode → push SetPasswordScreen
// ============================================================
class VerifyCodeScreen extends StatefulWidget {
  final String email;
  final String uuid;
  final VerifyMode mode;

  const VerifyCodeScreen({
    super.key,
    required this.email,
    required this.uuid,
    required this.mode,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendCountdown = 60;
  Timer? _resendTimer;
  bool _loading = false;
  bool _verified = false; // 防止 auto-submit 多次触发
  late String _currentUuid; // 重新发送后会更新

  @override
  void initState() {
    super.initState();
    _currentUuid = widget.uuid;
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  void _showToast(String message) {
    AppToast.show(context, message);
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_isCodeComplete()) {
      _onSubmit();
    }
  }

  bool _isCodeComplete() {
    return _controllers.every((c) => c.text.isNotEmpty);
  }

  String get _codeText => _controllers.map((c) => c.text).join();

  Future<void> _onSubmit() async {
    if (_loading || _verified) return;
    if (!_isCodeComplete()) {
      _showToast('请输入完整的 6 位验证码');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final deviceId = await TokenStorage.instance.getOrCreateDeviceId();
      // 始终使用最新 _currentUuid (重发后会更新),避免新旧验证码混淆
      if (widget.mode == VerifyMode.register) {
        await AuthApi.instance.checkEmailCode(
          email: widget.email,
          uuid: _currentUuid,
          code: _codeText,
          deviceId: deviceId,
        );
      } else {
        await AuthApi.instance.checkForgetEmailCode(
          email: widget.email,
          uuid: _currentUuid,
          code: _codeText,
          deviceId: deviceId,
        );
      }
      if (!mounted) return;
      _verified = true;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SetPasswordScreen(
            email: widget.email,
            uuid: _currentUuid,
            mode: widget.mode,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        _showToast(AppToast.translateError(e.message));
        // 清空输入,允许重试
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) _showToast('验证失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onResend() async {
    if (_resendCountdown > 0) return;
    try {
      final deviceId = await TokenStorage.instance.getOrCreateDeviceId();
      String newUuid;
      if (widget.mode == VerifyMode.register) {
        newUuid = await AuthApi.instance.sendEmailCodeForRegister(
          email: widget.email,
          deviceId: deviceId,
        );
      } else {
        newUuid = await AuthApi.instance.sendEmailCodeForForget(
          email: widget.email,
          deviceId: deviceId,
        );
      }
      if (!mounted) return;
      _showToast('验证码已重新发送');
      // 重新计时; uuid 用本地 _currentUuid 持有,后端不校验旧 uuid 是否失效,新请求会覆盖
      _startResendCountdown();
      setState(() => _currentUuid = newUuid);
      // 清空已输入的旧验证码,避免和新验证码混淆
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } on ApiException catch (e) {
      if (mounted) _showToast(AppToast.translateError(e.message));
    } catch (e) {
      if (mounted) _showToast('重发失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffolding(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 标题区: "输入验证码" + "验证码已发送至 xxx" (gap 12) ──
          Column(
            children: [
              const AuthTitle('输入验证码'),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                    height: 18 / 14,
                  ),
                  children: [
                    const TextSpan(text: '验证码已发送至 '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF39D03D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          // ── 验证码区: 6 格 + 重新发送 (gap 24) ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 6 个 52×56 方格, gap 8, 居中
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                    child: _buildCodeSquare(i),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // "没有收到？重新发送" gap 4, 居中
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '没有收到？',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _resendCountdown > 0 ? null : _onResend,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      _resendCountdown > 0 ? '$_resendCountdown 秒后重发' : '重新发送',
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _resendCountdown > 0
                            ? const Color(0xFF999999)
                            : const Color(0xFF39D03D),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          // ── 操作区: "验证" 按钮 + "返回登录" ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPrimaryButton(
                label: _loading ? '验证中…' : '验证',
                onPressed: _loading ? null : _onSubmit,
              ),
              const SizedBox(height: 20),
              Center(
                child: AuthBackLink(
                  label: '返回登录',
                  onTap: _popToLogin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Figma digit-box: 52×56, 4px 圆角, 1.5px 描边
  // 有值/聚焦 → #39D03D 绿描边; 空且未聚焦 → rgba(0,0,0,0.1) 灰描边
  Widget _buildCodeSquare(int index) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;
    final borderColor = (hasValue || isFocused)
        ? const Color(0xFF39D03D)
        : const Color(0x1A000000); // rgba(0,0,0,0.1)

    return SizedBox(
      width: 52,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasValue)
              Text(
                _controllers[index].text,
                style: const TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                  height: 1.0,
                ),
              ),
            if (isFocused && !hasValue)
              Container(
                width: 1.5,
                height: 24,
                color: const Color(0xFF39D03D),
              ),
            Positioned.fill(
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                cursorColor: Colors.transparent,
                showCursor: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                onChanged: (v) => _onCodeChanged(index, v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _popToLogin() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
