import 'package:flutter/widgets.dart';

import '../domain/entities/app_error.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 将领域错误转为用户可读文案
String errorText(AppLocalizations l10n, Object? error) => switch (error) {
      RiskControlError(:final message) => message ?? l10n.errorRiskControl,
      NeedLoginError() => l10n.errorNeedLogin,
      NetworkError() => l10n.errorNetwork,
      NotFoundError() => l10n.errorNotFound,
      CopyrightError() => l10n.errorCopyright,
      UnknownError(:final message) => l10n.errorUnknown(message),
      _ => l10n.errorUnknown('$error'),
    };

/// `mm:ss` / `h:mm:ss`
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// 字节数格式化: 1.2 MB / 3.4 GB
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}
