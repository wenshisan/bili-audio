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

  test('Android 清单可调整大小且不锁方向', () {
    final xml = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(xml.contains('screenOrientation'), isFalse);
    expect(xml.contains('compatible-screens'), isFalse);
    expect(xml.contains('resizeableActivity="false"'), isFalse);
  });
}
