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
    bool prerelease = false,
  }) => {
    'tag_name': tag,
    'name': tag,
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
      '/repos/$githubRepository/releases/latest',
      (server) => server.reply(200, release()),
    );

    final latest = await source.latestStable();

    expect(latest, isNotNull);
    expect(latest!.version.text, '0.2.0');
    expect(latest.notes, '修复播放');
    expect(latest.assetByName(androidInstaller)?.downloadUrl, contains(tag));
  });

  test('还没有正式版时返回空', () async {
    adapter.onGet(
      '/repos/$githubRepository/releases/latest',
      (server) => server.reply(404, {'message': 'Not Found'}),
    );

    expect(await source.latestStable(), isNull);
  });

  test('预发布和非版本标签不当作升级', () async {
    adapter.onGet(
      '/repos/$githubRepository/releases/latest',
      (server) =>
          server.reply(200, release(tag: 'continuous', prerelease: true)),
    );
    expect(await source.latestStable(), isNull);
  });
}

final tag = 'v0.2.0';
