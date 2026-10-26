import 'package:bili_audio/domain/update/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('offersInAppUpdate', () {
    test('商店包不检查 GitHub 安装包', () {
      expect(offersInAppUpdate(microsoftStore: true), isFalse);
    });

    test('直接分发的安装包仍检查更新', () {
      expect(offersInAppUpdate(microsoftStore: false), isTrue);
    });
  });

  group('productTitle', () {
    test('各安装包使用同一个产品名', () {
      expect(productTitle(), productName);
      expect(productName.toLowerCase(), isNot(contains('bili')));
    });
  });
}
