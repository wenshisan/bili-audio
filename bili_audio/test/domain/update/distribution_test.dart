import 'package:bili_audio/domain/update/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('offersInAppUpdate', () {
    test('商店包不检查 GitHub 安装包', () {
      expect(offersInAppUpdate(microsoftStore: true), isFalse);
    });

    test('已经装进 MSIX 的进程不检查更新', () {
      expect(
        offersInAppUpdate(microsoftStore: false, packagedWindowsApp: true),
        isFalse,
      );
    });

    test('WindowsApps 下的程序视为商店或旁加载包', () {
      expect(
        windowsExecutableIsPackaged(
          r'C:\Program Files\WindowsApps\423A5ECF.492838BFDFE29_0.1.0.0_x64__jrardjz4vbb7a\bili_audio.exe',
        ),
        isTrue,
      );
      expect(
        windowsExecutableIsPackaged(
          r'D:\Code\flutter-app-deep\bili_audio\build\windows\x64\runner\Release\bili_audio.exe',
        ),
        isFalse,
      );
    });

    test('直接分发的安装包仍检查更新', () {
      expect(
        offersInAppUpdate(microsoftStore: false, packagedWindowsApp: false),
        isTrue,
      );
    });

    test('不传参数时跟随编译开关', () {
      expect(
        offersInAppUpdate(packagedWindowsApp: false),
        isNot(kMicrosoftStore),
      );
    });
  });

  group('productTitle', () {
    test('各安装包使用同一个产品名', () {
      expect(productTitle(), productName);
      expect(productName.toLowerCase(), isNot(contains('bili')));
    });
  });
}
