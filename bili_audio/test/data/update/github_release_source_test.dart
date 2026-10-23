import 'package:bili_audio/data/update/release_source.dart';
import 'package:bili_audio/domain/update/installer_asset.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late GithubReleaseSource source;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'));
    adapter = DioAdapter(dio: dio);
    source = GithubReleaseSource(dio: dio);
  });

  Map<String, Object?> release({
    String tag = 'v0.2.0',
    String? name,
    bool prerelease = false,
  }) => {
    'tag_name': tag,
    'name': name ?? tag,
    'body': '修复播放',
    'html_url': 'https://github.com/$githubRepository/releases/tag/$tag',
    'draft': false,
    'prerelease': prerelease,
    'assets': [
      {
        'name': androidInstaller,
        'browser_download_url':
            'https://github.com/$githubRepository/releases/download/$tag/$androidInstaller',
        'size': 12,
      },
    ],
  };

  test('解析最新正式版和安装包地址', () async {
    adapter.onGet(
      '/repos/$githubRepository/releases',
      (server) => server.reply(200, [release()]),
    );

    final latest = await source.latestStable();

    expect(latest, isNotNull);
    expect(latest!.version.text, '0.2.0');
    expect(latest.notes, '修复播放');
    expect(latest.assetByName(androidInstaller)?.downloadUrl, contains(tag));
  });

  test('还没有正式版时返回空', () async {
    adapter.onGet(
      '/repos/$githubRepository/releases',
      (server) => server.reply(404, {'message': 'Not Found'}),
    );

    expect(await source.latestStable(), isNull);
  });

  test('预发布和非版本标签不当作升级', () async {
    adapter.onGet(
      '/repos/$githubRepository/releases',
      (server) => server.reply(200, [
        release(tag: 'continuous', name: 'v0.9.0+9', prerelease: true),
      ]),
    );
    expect(await source.latestStable(), isNull);
  });

  test('多条正式版里取最高构建号', () async {
    adapter.onGet(
      '/repos/$githubRepository/releases',
      (server) => server.reply(200, [
        release(tag: 'v0.1.0+2'),
        release(tag: 'v0.1.0+4'),
        release(tag: 'v0.9.0', prerelease: true),
      ]),
    );

    final latest = await source.latestStable();

    expect(latest?.version.text, '0.1.0+4');
  });

  test('修订号更高时盖过构建号', () async {
    adapter.onGet(
      '/repos/$githubRepository/releases',
      (server) => server.reply(200, [
        release(tag: 'v0.1.0+99'),
        release(tag: 'v0.2.0', name: 'v0.2.0+3'),
      ]),
    );

    expect((await source.latestStable())?.version.text, '0.2.0+3');
  });
}

final tag = 'v0.2.0';
