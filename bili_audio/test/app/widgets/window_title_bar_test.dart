import 'package:bili_audio/app/widgets/window_title_bar.dart';
import 'package:bili_audio/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('window_manager');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isMaximized') return false;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpBar(WidgetTester tester, {required bool native}) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WindowTitleBar(nativeWindowButtons: native),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Windows 标题在左，右侧有窗体按钮', (tester) async {
    await pumpBar(tester, native: false);

    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.crop_square), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    final title = tester.getCenter(find.text('bili-audio'));
    final logo = tester.getCenter(find.byIcon(Icons.music_note));
    expect(logo.dx, lessThan(title.dx));
    expect(title.dx, lessThan(400));
    expect(tester.getCenter(find.byIcon(Icons.close)).dx, greaterThan(title.dx));
  });

  testWidgets('macOS 不画右侧窗体按钮，标题靠右', (tester) async {
    await pumpBar(tester, native: true);

    expect(find.byIcon(Icons.remove), findsNothing);
    expect(find.byIcon(Icons.crop_square), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.fullscreen_exit), findsNothing);

    final title = tester.getCenter(find.text('bili-audio'));
    final logo = tester.getCenter(find.byIcon(Icons.music_note));
    expect(logo.dx, lessThan(title.dx));
    expect(logo.dx, greaterThan(400));
    expect(title.dx, greaterThan(logo.dx));
    expect(tester.getTopRight(find.text('bili-audio')).dx, closeTo(800 - 16, 8));
  });
}
