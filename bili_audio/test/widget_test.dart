import 'package:bili_audio/app/theme.dart';
import 'package:bili_audio/features/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomePage renders placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('项目初始化完成'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });

  test('ThemeController updates mode and seed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(themeControllerProvider.notifier);
    expect(container.read(themeControllerProvider).mode, ThemeMode.system);

    controller.setMode(ThemeMode.dark);
    controller.setSeed(presetSeeds[1]);

    final state = container.read(themeControllerProvider);
    expect(state.mode, ThemeMode.dark);
    expect(state.seed, presetSeeds[1]);
  });
}
