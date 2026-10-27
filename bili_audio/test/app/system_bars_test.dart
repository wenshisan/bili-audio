import 'package:bili_audio/app/system_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('浅色界面用深色系统栏图标', () {
    final style = immersiveOverlayStyle(Brightness.light);
    expect(style.statusBarColor, Colors.transparent);
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.systemNavigationBarDividerColor, Colors.transparent);
    expect(style.systemStatusBarContrastEnforced, isFalse);
    expect(style.systemNavigationBarContrastEnforced, isFalse);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.statusBarBrightness, Brightness.light);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
  });

  test('深色界面用浅色系统栏图标', () {
    final style = immersiveOverlayStyle(Brightness.dark);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.statusBarBrightness, Brightness.dark);
    expect(style.systemNavigationBarIconBrightness, Brightness.light);
  });
}
