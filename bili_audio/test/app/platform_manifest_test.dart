import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS 不强制全屏，iPad 允许四向旋转', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist.contains('UIRequiresFullScreen'), isFalse);
    expect(plist.contains('UIInterfaceOrientationPortraitUpsideDown'), isTrue);
    expect(plist.contains('UIInterfaceOrientationLandscapeLeft'), isTrue);
    expect(plist.contains('UIInterfaceOrientationLandscapeRight'), isTrue);
  });

  test('macOS 关闭 Impeller，避免 Intel 核显挂死', () {
    final plist = File('macos/Runner/Info.plist').readAsStringSync();
    expect(plist.contains('<key>FLTEnableImpeller</key>'), isTrue);
    expect(
      RegExp(r'<key>FLTEnableImpeller</key>\s*<false\s*/>').hasMatch(plist),
      isTrue,
    );
  });

  test('Android 清单可调整大小且不锁方向', () {
    final xml = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(xml.contains('screenOrientation'), isFalse);
    expect(xml.contains('compatible-screens'), isFalse);
    expect(xml.contains('resizeableActivity="false"'), isFalse);
    expect(
      xml.contains('android:networkSecurityConfig="@xml/network_security_config"'),
      isTrue,
    );
    final security = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();
    expect(security.contains('cleartextTrafficPermitted="true"'), isTrue);
    expect(security.contains('>127.0.0.1<'), isTrue);
  });
}
