import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/platform/open_url.dart';
import '../../l10n/l10n.dart';
import 'login_controller.dart';
import 'login_method.dart';
import 'qr_login_panel.dart';
import 'web_login_panel.dart';

/// 登录页。手机默认网页登录，桌面默认扫码。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.mobile, this.openUrl});

  /// 为空时按 Android / iOS 判断。
  final bool? mobile;

  /// 打开隐私政策。测试可替换；为空时用系统浏览器。
  final Future<bool> Function(String url)? openUrl;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late LoginMethod _method;
  var _agreed = false;

  @override
  void initState() {
    super.initState();
    _method = defaultLoginMethod(
      mobile: widget.mobile ?? loginPlatformIsMobile(),
    );
  }

  bool get _mobile => widget.mobile ?? loginPlatformIsMobile();

  Future<void> _signedIn() async {
    await ref.read(loginControllerProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hold = l10n.loginPrivacyHold;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LoginMethodBody(
                mobile: _mobile,
                method: _method,
                onMethodChanged: (method) => setState(() => _method = method),
                web: _agreed
                    ? WebLoginPanel(onSignedIn: _signedIn)
                    : _LoginBlocked(text: hold),
                qr: _agreed
                    ? QrLoginPanel(onSignedIn: _signedIn)
                    : _LoginBlocked(text: hold),
              ),
            ),
            LoginPrivacyConsent(
              agreed: _agreed,
              onChanged: (agreed) => setState(() => _agreed = agreed),
              onOpenPrivacy: () => openPrivacyDocument(
                context,
                privacyPolicyUrl,
                openUrl: widget.openUrl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 未同意隐私政策时占住登录区域，避免扫码或网页登录先开始。
class _LoginBlocked extends StatelessWidget {
  const _LoginBlocked({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// 登录页底部的隐私政策勾选。默认不勾选。
class LoginPrivacyConsent extends StatelessWidget {
  const LoginPrivacyConsent({
    super.key,
    required this.agreed,
    required this.onChanged,
    required this.onOpenPrivacy,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              children: [
                Checkbox(
                  value: agreed,
                  onChanged: (value) => onChanged(value ?? false),
                ),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      GestureDetector(
                        onTap: () => onChanged(!agreed),
                        child: Text(l10n.loginPrivacyLead),
                      ),
                      GestureDetector(
                        onTap: onOpenPrivacy,
                        child: Text(
                          l10n.loginPrivacyLink,
                          style: TextStyle(color: scheme.primary),
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
}

class LoginMethodBody extends StatelessWidget {
  const LoginMethodBody({
    super.key,
    required this.mobile,
    required this.method,
    required this.onMethodChanged,
    required this.web,
    required this.qr,
  });

  final bool mobile;
  final LoginMethod method;
  final ValueChanged<LoginMethod> onMethodChanged;
  final Widget web;
  final Widget qr;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final child = method == LoginMethod.web ? web : qr;
    if (!mobile) return child;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<LoginMethod>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: LoginMethod.web,
                label: Text(l10n.loginMethodWeb),
              ),
              ButtonSegment(
                value: LoginMethod.qr,
                label: Text(l10n.loginMethodQr),
              ),
            ],
            selected: {method},
            onSelectionChanged: (next) => onMethodChanged(next.first),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
