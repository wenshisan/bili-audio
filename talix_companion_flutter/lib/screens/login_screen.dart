import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main_frame.dart' show MainFrame;
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_toast.dart';
import 'auth/auth_card_scaffolding.dart';
import 'auth/auth_input_field.dart';
import 'auth/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

// ============================================================
// LoginScreen (Figma 669:4626)
// 440×600 卡片 (24px 圆角) — 品牌区 → gap 40 → 标题"登录" →
// gap 40 → [邮箱 / 密码 / 协议] (gap 20) → gap 40 →
// [绿色"登录"按钮 → gap 20 → 忘记密码 ⟷ 立即注册]
// 流程: 登录 → 调 AuthViewModel.loginByEmail → pushReplacement(MainFrame);
//       立即注册 → push(RegisterScreen);
//       忘记密码 → push(ForgotPasswordScreen)
// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    AppToast.show(context, AppToast.translateError(message));
  }

  bool _isValidEmail(String v) {
    final email = v.trim();
    if (email.isEmpty) return false;
    return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email);
  }

  Future<void> _onLogin() async {
    if (!_isValidEmail(_emailController.text)) {
      _showToast('请输入有效的邮箱地址');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showToast('密码至少 6 位');
      return;
    }
    if (!_agreed) {
      _showToast('请阅读并同意《用户协议》和《隐私政策》');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final auth = context.read<AuthViewModel>();
    final ok = await auth.loginByEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      _showToast('🎉 登录成功，欢迎回来');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainFrame()),
      );
    } else {
      _showToast(auth.lastError ?? '登录失败,请稍后重试');
    }
  }

  void _onGoToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _onForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffolding(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题 "登录" (父 Column 为 stretch, 需显式居中)
          const Center(child: AuthTitle('登录')),
          const SizedBox(height: 40),
          // 表单区
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                kind: AuthInputKind.email,
                placeholder: '请输入您的邮箱',
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              AuthInputField(
                kind: AuthInputKind.password,
                placeholder: '请输入密码',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              AuthAgreementRow(
                agreed: _agreed,
                onChanged: (v) => setState(() => _agreed = v),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // 操作区
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPrimaryButton(
                label: _loading ? '登录中…' : '登录',
                onPressed: _loading ? null : _onLogin,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AuthBackLink(
                    label: '忘记密码？',
                    onTap: _onForgotPassword,
                  ),
                  AuthBackLink(
                    label: '立即注册',
                    onTap: _onGoToRegister,
                    variant: AuthBackLinkVariant.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
