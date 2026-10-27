import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import 'login_controller.dart';
import 'login_method.dart';
import 'qr_login_panel.dart';
import 'web_login_panel.dart';

/// 登录页。手机默认网页登录，桌面默认扫码。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.mobile});

  /// 为空时按 Android / iOS 判断。
  final bool? mobile;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late LoginMethod _method;

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
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.loginTitle)),
      body: SafeArea(
        top: false,
        child: LoginMethodBody(
          mobile: _mobile,
          method: _method,
          onMethodChanged: (method) => setState(() => _method = method),
          web: WebLoginPanel(onSignedIn: _signedIn),
          qr: QrLoginPanel(onSignedIn: _signedIn),
        ),
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
