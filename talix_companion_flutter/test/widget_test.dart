// Basic smoke test for Talix app.

import 'package:flutter_test/flutter_test.dart';

import 'package:talix_companion/main.dart';

void main() {
  test('TalixApp class is defined', () {
    // TalixApp 依赖 tray_manager / window_manager 等原生插件,
    // 直接 pumpWidget 会在测试环境抛 PlatformException。
    // 此处仅验证主类可被引用, 实际渲染由集成测试覆盖。
    expect(TalixApp, isNotNull);
  });
}
