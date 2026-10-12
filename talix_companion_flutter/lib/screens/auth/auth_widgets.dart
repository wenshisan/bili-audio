import 'package:flutter/material.dart';

// ============================================================
// auth_widgets.dart — 登录流程共享 UI 组件
// Figma 669:4626 / 669:5229 / 669:5266 / 669:5298 / 669:5082
// ============================================================

// ── 颜色常量 ─────────────────────────────────────────────────
const Color _kGreen = Color(0xFF39D03D);
const Color _kGrey = Color(0xFF999999);

// ============================================================
// AuthTitle
// Figma: 24px Regular #333333 屏幕标题 (登录/注册/忘记密码/设置密码/输入验证码)
// ============================================================
class AuthTitle extends StatelessWidget {
  final String text;

  const AuthTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Color(0xFF333333),
      ),
    );
  }
}

// ============================================================
// AuthPrimaryButton
// Figma primary-button: 高 48, 4px 圆角, #39D03D 绿色填充,
//                       boxShadow 0 4 12 rgba(57,208,61,0.2),
//                       14px Semibold 白字
// ============================================================
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x3339D03D), // rgba(57,208,61,0.2)
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: SizedBox(
        height: 48,
        child: Material(
          color: enabled ? _kGreen : const Color(0xFFCCCCCC),
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.0,
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
// AuthBackLink
// Figma: 14px Semibold, 点击跳转链接
// variant=primary → #39D03D 绿 (立即登录/立即注册)
// variant=secondary → #999999 灰 (返回登录/忘记密码)
// ============================================================
enum AuthBackLinkVariant { primary, secondary }

class AuthBackLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AuthBackLinkVariant variant;

  const AuthBackLink({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = AuthBackLinkVariant.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final color = variant == AuthBackLinkVariant.primary ? _kGreen : _kGrey;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// AuthAgreementRow
// Figma agreement-row: 16x16 复选框 + 12px #999999 协议文字
// 复选框选中态: #39D03D 绿色填充 + √ 图标
// 复选框未选态: 白底 + 1.5px #999999 描边
// ============================================================
class AuthAgreementRow extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;

  const AuthAgreementRow({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 16×16 复选框
        GestureDetector(
          onTap: () => onChanged(!agreed),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: agreed ? _kGreen : Colors.white,
              border: Border.all(
                color: agreed ? _kGreen : _kGrey,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.center,
            child: agreed
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        // 12px 协议文字
        const Expanded(
          child: Text(
            '阅读并同意协议《用户协议》和《隐私政策》',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: _kGrey,
            ),
          ),
        ),
      ],
    );
  }
}
