import 'package:bili_audio/data/update/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRelease.fromGithubJson', () {
    Map<String, dynamic> json({
      String tag = 'v0.1.0+2',
      String? name,
      bool prerelease = false,
    }) => {
      'tag_name': tag,
      'name': name ?? tag,
      'body': '',
      'html_url': 'https://example.test/$tag',
      'draft': false,
      'prerelease': prerelease,
      'assets': <Object?>[],
    };

    test('标签里的构建号可以比较', () {
      final release = AppRelease.fromGithubJson(json());
      expect(release?.version.text, '0.1.0+2');
    });

    test('标题补上同一版的构建号', () {
      final release = AppRelease.fromGithubJson(
        json(tag: 'v0.2.0', name: 'v0.2.0+6'),
      );
      expect(release?.version.text, '0.2.0+6');
    });

    test('标题的另一条版本线不能盖过标签', () {
      final release = AppRelease.fromGithubJson(
        json(tag: 'v0.2.0', name: 'v9.0.0+1'),
      );
      expect(release?.version.text, '0.2.0');
    });

    test('预发布没有可升级版本', () {
      expect(
        AppRelease.fromGithubJson(
          json(tag: 'continuous', name: 'v0.1.0+6', prerelease: true),
        ),
        isNull,
      );
    });
  });
}
