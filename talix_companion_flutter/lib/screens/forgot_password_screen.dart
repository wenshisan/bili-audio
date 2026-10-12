import 'package:flutter/material.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_api.dart';
import '../services/storage/token_storage.dart';
import '../widgets/app_toast.dart';
import 'auth/auth_card_scaffolding.dart';
import 'auth/auth_input_field.dart';
import 'auth/auth_widgets.dart';
import 'verify_code_screen.dart';

// ============================================================
// ForgotPasswordScreen (Figma 669:5266)
// 440×600 卡片 — 品牌区 → 标题"忘记密码" → gap 56 →
// 邮箱输入 → gap 56 →
// [绿色"获取验证码"按钮 → gap 20 → "返回登录" (灰)]
//
// 流程:
//   1. POST /mail-send/pinpoint/check-forget-password-email (邮箱已注册)
//   2. POST /mail-send/pinpoint/forget/pwd/sendVerifyCode → uuid
//   3. push VerifyCodeScreen(mode: forgot, email, uuid)
// ============================================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    AppToast.show(context, message);
  }

  bool _isValidEmail(String v) {
    final email = v.trim();
    if (email.isEmpty) return false;
    return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email);
  }

  Future<void> _onSubmit() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      _showToast('请输入有效的邮箱地址');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final deviceId = await TokenStorage.instance.getOrCreateDeviceId();
      // 1) 校验邮箱已注册
      await AuthApi.instance.checkEmailForForget(email: email, deviceId: deviceId);
      // 2) 发送忘记密码邮箱验证码
      final uuid = await AuthApi.instance.sendEmailCodeForForget(
        email: email,
        deviceId: deviceId,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            email: email,
            uuid: uuid,
            mode: VerifyMode.forgot,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) _showToast(AppToast.translateError(e.message));
    } catch (e) {
      if (mounted) _showToast('发送失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _popToLogin() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffolding(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题 "忘记密码"
          const AuthTitle('忘记密码'),
          const SizedBox(height: 56),
          // 邮箱输入
          AuthInputField(
            kind: AuthInputKind.email,
            placeholder: '请输入您的邮箱',
            controller: _emailController,
          ),
          const SizedBox(height: 56),
          // 操作区
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPrimaryButton(
                label: _loading ? '发送中…' : '获取验证码',
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
}
