import 'package:bili_audio/domain/update/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppVersion', () {
    test('解析带 v 的标签和构建号', () {
      final version = AppVersion.parse('v1.2.3+4');
      expect(version, isNotNull);
      expect(version!.text, '1.2.3+4');
      expect(version.hasBuild, isTrue);
      expect(version.build, 4);
    });

    test('拒绝非版本标签', () {
      expect(AppVersion.parse('continuous'), isNull);
      expect(AppVersion.parse('1.2'), isNull);
    });

    test('修订号更大则是更新', () {
      final current = AppVersion.parse('1.2.3+9')!;
      final remote = AppVersion.parse('v1.2.4')!;
      expect(remote.isNewerThan(current), isTrue);
    });

    test('两边都有构建号时比较构建号', () {
      final current = AppVersion.parse('0.1.0+1')!;
      final remote = AppVersion.parse('0.1.0+2')!;
      expect(remote.isNewerThan(current), isTrue);
      expect(current.isNewerThan(remote), isFalse);
    });

    test('只有一边有构建号时不把构建号当成更新', () {
      final current = AppVersion.parse('0.1.0+1')!;
      final remote = AppVersion.parse('v0.1.0')!;
      expect(remote.isNewerThan(current), isFalse);
      expect(current.isNewerThan(remote), isFalse);
    });
  });
}
