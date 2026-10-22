import 'package:dio/dio.dart';

import '../../domain/update/installer_asset.dart';
import 'app_release.dart';

/// 读取可用于升级的正式版本。
abstract class ReleaseSource {
  /// 最新的非预发布版本。还没有任何正式版本时返回 `null`。
  Future<AppRelease?> latestStable();
}

/// 不访问网络。测试和未注入真实源时使用。
class EmptyReleaseSource implements ReleaseSource {
  /// 创建空的升级源。
  const EmptyReleaseSource();

  @override
  Future<AppRelease?> latestStable() async => null;
}

/// 检查更新失败。
class UpdateCheckException implements Exception {
  /// 用已经适合展示的原因创建异常。
  const UpdateCheckException(this.message);

  /// 失败原因。
  final String message;

  @override
  String toString() => message;
}

/// 从 GitHub Releases 读取最新正式版。
///
/// 请求 `GET /repos/{owner}/{name}/releases/latest`。预发布标签
/// （例如 `continuous`）不会出现在这个接口里。
class GithubReleaseSource implements ReleaseSource {
  /// 创建客户端。[dio] 为空时访问 `https://api.github.com`。
  GithubReleaseSource({Dio? dio, this.repository = githubRepository})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.github.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {
                'Accept': 'application/vnd.github+json',
                'User-Agent': 'BiliAudio',
                'X-GitHub-Api-Version': '2022-11-28',
              },
            ),
          );

  /// `owner/name`。
  final String repository;

  final Dio _dio;

  @override
  Future<AppRelease?> latestStable() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/repos/$repository/releases/latest',
      );
      final data = response.data;
      if (data == null) return null;
      return AppRelease.fromGithubJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      final code = error.response?.statusCode;
      throw UpdateCheckException(code == null ? '网络错误' : 'GitHub 返回 $code');
    }
  }
}
