import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 当前设备在升级逻辑里使用的系统名和 CPU。
class UpdateHost {
  /// 记录操作系统和架构。
  const UpdateHost({required this.operatingSystem, required this.architecture});

  /// `android`、`windows`、`macos`、`linux` 或 `ios`。
  final String operatingSystem;

  /// `x64`、`arm64` 或其他。
  final String architecture;
}

/// 读取本机平台。Web 上没有安装包。
UpdateHost currentUpdateHost() {
  if (kIsWeb) {
    return const UpdateHost(operatingSystem: 'web', architecture: 'web');
  }
  return UpdateHost(
    operatingSystem: Platform.operatingSystem,
    architecture: _architecture(),
  );
}

String _architecture() => switch (Abi.current()) {
  Abi.windowsX64 || Abi.linuxX64 || Abi.macosX64 || Abi.androidX64 => 'x64',
  Abi.windowsArm64 ||
  Abi.linuxArm64 ||
  Abi.macosArm64 ||
  Abi.androidArm64 ||
  Abi.iosArm64 => 'arm64',
  _ => 'other',
};
