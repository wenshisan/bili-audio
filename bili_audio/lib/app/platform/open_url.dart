import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';

/// 与介绍页、应用商店填写的地址是同一份。
const privacyPolicyUrl = 'https://wenshisan.github.io/bili-audio/privacy.html';

/// 与隐私政策放在同一站点。
const childrenPrivacyPolicyUrl =
    'https://wenshisan.github.io/bili-audio/children.html';

/// 用系统浏览器打开 [url]。打不开时返回 false。
Future<bool> openExternalUrl(String url) async {
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

/// 打开隐私政策页面。失败时在当前界面提示。
Future<void> openPrivacyDocument(
  BuildContext context,
  String url, {
  Future<bool> Function(String url)? openUrl,
}) async {
  final ok = await (openUrl ?? openExternalUrl)(url);
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.privacyOpenFailed)),
  );
}
