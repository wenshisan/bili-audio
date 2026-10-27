import 'package:bili_audio/features/login/login_method.dart';
import 'package:bili_audio/features/login/login_page.dart';
import 'package:bili_audio/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('手机默认显示网页登录，可以切到扫码', (tester) async {
    var method = LoginMethod.web;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return LoginMethodBody(
                mobile: true,
                method: method,
                onMethodChanged: (next) => setState(() => method = next),
                web: const Text('web-body'),
                qr: const Text('qr-body'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('web-body'), findsOneWidget);
    expect(find.text('网页登录'), findsOneWidget);
    expect(find.text('qr-body'), findsNothing);

    await tester.tap(find.text('扫码登录'));
    await tester.pumpAndSettle();

    expect(find.text('qr-body'), findsOneWidget);
    expect(find.text('web-body'), findsNothing);
  });

  testWidgets('桌面只显示扫码，没有登录方式切换', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LoginMethodBody(
            mobile: false,
            method: LoginMethod.qr,
            onMethodChanged: _noop,
            web: Text('web-body'),
            qr: Text('qr-body'),
          ),
        ),
      ),
    );

    expect(find.text('qr-body'), findsOneWidget);
    expect(find.text('网页登录'), findsNothing);
  });
}

void _noop(LoginMethod method) {}
