import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/bili/bili_login_api.dart';
import '../../l10n/l10n.dart';
import 'login_controller.dart';

/// 扫码登录页 (M7.2)
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String? _url;
  QrStatus? _status;
  Object? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _url = null;
      _status = null;
      _error = null;
    });
    _pollTimer?.cancel();
    final result = await ref.read(loginApiProvider).generate();
    if (!mounted) return;
    if (result.isFailure) {
      setState(() => _error = result.errorOrNull);
      return;
    }
    final (url, key) = result.valueOrNull!;
    setState(() {
      _url = url;
      _status = const QrWaiting();
    });
    _startPolling(key);
  }

  void _startPolling(String key) {
    final deadline = DateTime.now().add(const Duration(seconds: 180));
    var busy = false;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (busy) return;
      if (DateTime.now().isAfter(deadline)) {
        _pollTimer?.cancel();
        setState(() => _status = const QrExpired());
        return;
      }
      busy = true;
      final result = await ref.read(loginApiProvider).poll(key);
      busy = false;
      if (!mounted || _pollTimer?.isActive != true) return;
      final status = result.valueOrNull;
      if (status == null) {
        setState(() => _error = result.errorOrNull);
        _pollTimer?.cancel();
        return;
      }
      setState(() {
        _status = status;
        _error = null;
      });
      if (status is QrConfirmed) {
        _pollTimer?.cancel();
        await ref.read(loginControllerProvider.notifier).refresh();
        if (mounted) Navigator.pop(context);
      } else if (status is QrExpired) {
        _pollTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final err = _error;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_url != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(data: _url!, size: 240),
                ),
              const SizedBox(height: 24),
              if (err != null) ...[
                Text(errorText(l10n, err),
                    style: TextStyle(color: scheme.error)),
                const SizedBox(height: 12),
                FilledButton.tonal(
                    onPressed: _generate, child: Text(l10n.loginRetry)),
              ] else ...[
                Text(_statusText(l10n, _status)),
                if (_status is QrExpired)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilledButton.tonal(
                        onPressed: _generate, child: Text(l10n.loginRetry)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(AppLocalizations l10n, QrStatus? status) => switch (status) {
        QrWaiting() => l10n.loginWaiting,
        QrScanned() => l10n.loginScanned,
        QrExpired() => l10n.loginExpired,
        QrConfirmed() => l10n.loginSuccess,
        _ => l10n.loginScan,
      };
}
