import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const systemCarChannel = MethodChannel('bili_audio/ui_mode');

/// Android 车载 UI 模式。其他平台、读不到或调用失败时为 false。
Future<bool> loadSystemCarUi() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final value = await systemCarChannel.invokeMethod<bool>('isCar');
    return value ?? false;
  } catch (e, st) {
    debugPrint('ui_mode isCar failed: $e\n$st');
    return false;
  }
}
