import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../core/logging/app_logger.dart';
import '../../data/bili/bili_login_api.dart';
import '../../domain/entities/app_error.dart';
import '../../l10n/l10n.dart';
import 'login_controller.dart';
import 'login_cookie_source.dart';
import 'login_web.dart';

/// 打开哔哩哔哩登录页，从本机网页容器读取登录凭证。
class WebLoginPanel extends ConsumerStatefulWidget {
  const WebLoginPanel({super.key, required this.onSignedIn, this.cookies});

  final Future<void> Function() onSignedIn;
  final LoginCookieSource? cookies;

  @override
  ConsumerState<WebLoginPanel> createState() => _WebLoginPanelState();
}

class _WebLoginPanelState extends ConsumerState<WebLoginPanel> {
  late final WebViewController _controller;
  late final LoginCookieSource _cookies;
  Timer? _timer;
  var _generation = 0;
  var _opened = false;
  var _done = false;
  var _busy = false;
  var _paused = false;
  var _loading = true;
  var _readFailed = false;
  var _thirdParty = false;
  var _thirdPartyLogged = false;
  var _painted = false;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _cookies = widget.cookies ?? const PlatformLoginCookieSource();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _onPageFinished,
          onWebResourceError: _onError,
          onNavigationRequest: (request) {
            return biliLoginNavigationAllowed(request.url)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _capture());
    _open(initial: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_painted) return;
    _painted = true;
    _controller.setBackgroundColor(Theme.of(context).colorScheme.surface);
  }

  @override
  void dispose() {
    _done = true;
    _generation++;
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _open({bool initial = false}) async {
    final generation = ++_generation;
    _paused = false;
    _opened = false;
    _banner = null;
    _loading = true;
    if (!initial && mounted) setState(() {});
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setUserAgent(biliLoginUserAgent);
      await _cookies.clear();
      if (!mounted || _done || generation != _generation) return;
      _opened = true;
      await _controller.loadRequest(Uri.parse(biliWebLoginUrl));
      Future<void>.delayed(const Duration(seconds: 15), () {
        if (!mounted || _done || generation != _generation || !_loading) return;
        setState(() => _loading = false);
      });
    } catch (_) {
      if (!mounted || _done || generation != _generation) return;
      setState(() {
        _loading = false;
        _paused = true;
        _opened = false;
        _banner = context.l10n.loginWebFailed;
      });
    }
  }

  Future<void> _onPageFinished(String url) async {
    if (!mounted || _done) return;
    if (!_thirdParty) {
      try {
        await _allowEmbeddedLoginCookies();
        _thirdParty = true;
      } catch (_) {
        if (!_thirdPartyLogged) {
          _thirdPartyLogged = true;
          AppLogger.w('未能允许网页写入登录 Cookie', tag: 'login');
        }
      }
    }
    if (!mounted || _done) return;
    setState(() => _loading = false);
    await _capture();
  }

  Future<void> _allowEmbeddedLoginCookies() async {
    final controller = _controller.platform;
    if (controller is! AndroidWebViewController) return;
    final manager = WebViewCookieManager().platform;
    if (manager is! AndroidWebViewCookieManager) return;
    await manager.setAcceptThirdPartyCookies(controller, true);
  }

  void _onError(WebResourceError error) {
    if (error.isForMainFrame != true || !mounted || _done) return;
    final url = error.url;
    if (url != null && !biliLoginNavigationAllowed(url)) return;
    setState(() {
      _loading = false;
      _paused = true;
      _banner = context.l10n.loginWebFailed;
    });
  }

  Future<void> _capture() async {
    if (!_opened || _paused || _done || _busy || !mounted) return;
    _busy = true;
    final generation = _generation;
    try {
      final raw = await _cookies.read();
      if (!mounted || _done || _paused || generation != _generation) return;
      final picked = BiliLoginApi.parseLoginCookies(raw);
      if (picked == null) return;
      await _finish(picked, generation);
    } catch (_) {
      if (!_readFailed) {
        _readFailed = true;
        AppLogger.w('读取网页登录凭证失败', tag: 'login');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _submit(Map<String, String> cookies) async {
    for (var i = 0; i < 50; i++) {
      if (!mounted || _done) return;
      if (!_busy) break;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted || _done || _busy) return;
    _busy = true;
    try {
      await _finish(cookies, _generation);
    } finally {
      _busy = false;
    }
  }

  Future<void> _finish(Map<String, String> cookies, int generation) async {
    if (generation != _generation || _done) return;
    final saved = await ref.read(loginApiProvider).applyCookies(cookies);
    if (!mounted || _done || generation != _generation) return;
    if (saved.isFailure) {
      setState(() => _banner = errorText(context.l10n, saved.errorOrNull));
      return;
    }
    final user = await ref.read(loginApiProvider).currentUser();
    if (!mounted || _done || generation != _generation) return;
    if (user.valueOrNull == null) {
      final err = user.errorOrNull;
      if (err is NetworkError) {
        final text = errorText(context.l10n, err);
        if (_banner != text) setState(() => _banner = text);
        return;
      }
      await ref.read(loginApiProvider).logout();
      await _cookies.clear();
      if (!mounted || generation != _generation) return;
      setState(() {
        _paused = true;
        _loading = false;
        _banner = err is NeedLoginError
            ? context.l10n.loginWebRejected
            : errorText(context.l10n, err);
      });
      return;
    }
    _done = true;
    _timer?.cancel();
    if (!mounted) return;
    await widget.onSignedIn();
    await _cookies.clear();
  }

  Future<void> _paste() async {
    final parsed = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _PasteCookieDialog(),
    );
    if (parsed == null || !mounted || _done) return;
    await _submit(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final banner = _banner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            l10n.loginWebHint,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: _paste,
              child: Text(l10n.loginWebPaste),
            ),
          ),
        ),
        if (banner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner, style: TextStyle(color: scheme.error)),
                TextButton(onPressed: _open, child: Text(l10n.loginRetry)),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasteCookieDialog extends StatefulWidget {
  const _PasteCookieDialog();

  @override
  State<_PasteCookieDialog> createState() => _PasteCookieDialogState();
}

class _PasteCookieDialogState extends State<_PasteCookieDialog> {
  final _controller = TextEditingController();
  var _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = BiliLoginApi.parseLoginInput(_controller.text);
    if (parsed == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.loginWebPasteTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: l10n.loginWebPasteHint,
          errorText: _invalid ? l10n.loginWebPasteInvalid : null,
        ),
        onChanged: (_) {
          if (_invalid) setState(() => _invalid = false);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.confirm)),
      ],
    );
  }
}
