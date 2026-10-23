import 'package:dio/dio.dart';

import '../../domain/update/installer_asset.dart';
import 'app_release.dart';

/// 读取可用于升级的正式版本。
abstract class ReleaseSource {
  /// 最近发布里版本号最高的非预发布版本。
  ///
  /// 还没有这种版本时返回 `null`。
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

/// 从 GitHub Releases 读取可以升级到的版本。
///
/// 请求最近 100 条 Release，跳过草稿和预发布（例如 `continuous`），
/// 在剩下的版本里取最高的一个。推送到 main 的构建会发布 `vX.Y.Z+N`，
/// 构建号每次加一，因此高于已经安装的包。
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
      final response = await _dio.get<dynamic>(
        '/repos/$repository/releases',
        queryParameters: const {'per_page': 100},
      );
      final data = response.data;
      if (data is! List) return null;
      AppRelease? best;
      for (final item in data) {
        if (item is! Map) continue;
        final json = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item);
        final release = AppRelease.fromGithubJson(json);
        if (release == null) continue;
        if (best == null || release.version.isNewerThan(best.version)) {
          best = release;
        }
      }
      return best;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      final code = error.response?.statusCode;
      throw UpdateCheckException(code == null ? '网络错误' : 'GitHub 返回 $code');
    }
  }
}
