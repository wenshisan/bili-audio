import 'package:bili_audio/app/platform/open_url.dart';
import 'package:bili_audio/features/login/login_method.dart';
import 'package:bili_audio/features/login/login_page.dart';
import 'package:bili_audio/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  testWidgets('登录页默认未勾选隐私政策，勾选前不开始登录', (tester) async {
    String? opened;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(
            mobile: true,
            openUrl: (url) async {
              opened = url;
              return true;
            },
          ),
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(find.text('《隐私政策》'), findsOneWidget);
    expect(find.text('勾选下方后才能登录。不登录也可以搜索、播放和歌单。'), findsOneWidget);
    expect(
      find.text('在页面中用短信或密码登录。完成后会自动读取登录凭证，只保存在本机。'),
      findsNothing,
    );

    await tester.tap(find.text('《隐私政策》'));
    await tester.pump();
    expect(opened, privacyPolicyUrl);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('隐私政策勾选可以打开和取消', (tester) async {
    var agreed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return LoginPrivacyConsent(
                agreed: agreed,
                onChanged: (value) => setState(() => agreed = value),
                onOpenPrivacy: () {},
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(agreed, isTrue);

    await tester.tap(find.text('我已阅读并同意'));
    await tester.pump();
    expect(agreed, isFalse);
  });
}

void _noop(LoginMethod method) {}
