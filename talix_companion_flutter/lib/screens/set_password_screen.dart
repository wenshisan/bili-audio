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
// SetPasswordScreen (Figma 669:5082)
// 440×600 卡片 — 品牌区 → 标题"设置密码" → gap 40 →
// [密码 / 确认密码 / 错误文案 (gap 20)] → gap 40 →
// [绿色"确认"按钮 → gap 20 → "返回登录" (灰)]
// 密码输入框 borderRadius=8px (Figma EL-3d08350b)
//
// 流程: 输入两次密码 → 确认
//   register: POST /auth/register        → 提示 "请登录"
//   forgot:   POST /auth/forget-password → 提示 "请登录"
// ============================================================
class SetPasswordScreen extends StatefulWidget {
  final String email;
  final String uuid;
  final VerifyMode mode;

  const SetPasswordScreen({
    super.key,
    required this.email,
    required this.uuid,
    required this.mode,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    AppToast.show(context, message);
  }

  void _popToVerify() {
    Navigator.of(context).pop();
  }

  Future<void> _onSubmit() async {
    final pwd = _passwordController.text;
    final confirm = _confirmController.text;
    if (pwd.isEmpty) {
      _showToast('请输入密码');
      return;
    }
    if (pwd.length < 6) {
      _showToast('密码至少 6 位');
      return;
    }
    if (confirm != pwd) {
      _showToast('两次输入的密码不一致');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final deviceId = await TokenStorage.instance.getOrCreateDeviceId();
      if (widget.mode == VerifyMode.register) {
        await AuthApi.instance.emailRegister(
          email: widget.email,
          password: pwd,
          deviceId: deviceId,
        );
      } else {
        await AuthApi.instance.emailForgetPassword(
          email: widget.email,
          password: pwd,
          deviceId: deviceId,
        );
      }
      if (!mounted) return;
      final message = widget.mode == VerifyMode.register
          ? '🎉 注册成功,请登录'
          : '🎉 密码重置成功,请登录';
      _showToast(message);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (mounted) _showToast(AppToast.translateError(e.message));
    } catch (e) {
      if (mounted) _showToast('提交失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffolding(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题 "设置密码" (父 Column 为 stretch, 需显式居中)
          const Center(child: AuthTitle('设置密码')),
          const SizedBox(height: 40),
          // 表单区 (密码输入 8px 圆角)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                kind: AuthInputKind.password,
                placeholder: '请输入密码',
                controller: _passwordController,
                obscureText: true,
                borderRadius: 8,
              ),
              const SizedBox(height: 20),
              AuthInputField(
                kind: AuthInputKind.password,
                placeholder: '再次输入密码',
                controller: _confirmController,
                obscureText: true,
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 40),
          // 操作区
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPrimaryButton(
                label: _loading ? '处理中…' : '确认',
                onPressed: _loading ? null : _onSubmit,
              ),
              const SizedBox(height: 20),
              Center(
                child: AuthBackLink(
                  label: '返回登录',
                  onTap: _popToVerify,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
