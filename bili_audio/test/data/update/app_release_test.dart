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

  group('releaseChangelog', () {
    test('只保留更新日志，安装包一节不进入升级界面', () {
      const notes = '''
## 更新日志

- 支持队列中搜索
- 优化歌词匹配

## 安装包

| 平台 | 文件 |
| --- | --- |
| Android | `bili_audio-android.apk` |
''';
      expect(releaseChangelog(notes), '- 支持队列中搜索\n- 优化歌词匹配');
    });

    test('手写短说明原样显示', () {
      expect(releaseChangelog('修复播放'), '修复播放');
    });

    test('旧的构建说明不是更新日志', () {
      const notes = '''
由 GitHub Actions 从 `abc` 自动构建。版本 `v0.1.0+2`。

| 平台 | 文件 |
| --- | --- |
| Android | `bili_audio-android.apk` |

应用内升级认这个版本号。
''';
      expect(releaseChangelog(notes), isEmpty);
    });
  });
}
