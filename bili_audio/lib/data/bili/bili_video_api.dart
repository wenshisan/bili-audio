import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/bili_http.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_error.dart';
import '../../domain/entities/video.dart';

/// Bilibili 视频详情 API (M2.3)
class BiliVideoApi {
  BiliVideoApi(this._http);

  final BiliHttp _http;

  /// 获取视频详情
  ///
  /// 返回视频基本信息和所有分P，按 ≤ 15min 过滤分P
  Future<Result<Video>> getVideoInfo(String bvid) async {
    try {
      final response = await _http.dio.get<Map<String, dynamic>>(
        '/x/web-interface/view',
        queryParameters: {'bvid': bvid},
        options: Options(extra: {'wbi': true}),
      );

      final data = response.data!['data'] as Map<String, dynamic>;

      // 解析分P列表，过滤超过 15 分钟的
      final pagesData = data['pages'] as List<dynamic>?;
      if (pagesData == null || pagesData.isEmpty) {
        AppLogger.w('view $bvid has no pages', tag: 'video');
        return const Result.failure(AppError.notFound());
      }

      final pages = <VideoPage>[];
      final dropped = <String>[];
      for (final raw in pagesData) {
        if (raw is! Map) {
          dropped.add('bad-json');
          continue;
        }
        final page = _parsePageInfo(Map<String, dynamic>.from(raw));
        if (page == null) {
          dropped.add('unparsed');
          continue;
        }
        if (page.duration.inSeconds > 900) {
          dropped.add('p${page.pageIndex}=${page.duration.inSeconds}s');
          continue;
        }
        pages.add(page);
      }
      AppLogger.d(
        'view $bvid title="${data['title']}" raw=${pagesData.length} '
        'kept=${pages.length}'
        '${dropped.isEmpty ? '' : ' dropped=${dropped.join(',')}'}',
        tag: 'video',
      );

      if (pages.isEmpty) {
        return const Result.failure(
          AppError.notFound(), // 所有分P都超过15分钟
        );
      }

      final owner = data['owner'] as Map<String, dynamic>?;
      final stat = data['stat'] as Map<String, dynamic>?;

      final video = Video(
        bvid: bvid,
        title: data['title'] as String? ?? '',
        uploader: owner?['name'] as String? ?? '',
        uploaderMid: owner?['mid'] as int? ?? 0,
        cover: data['pic'] as String? ?? '',
        pages: pages,
        viewCount: stat?['view'] as int?,
        publishTime: data['pubdate'] as int?,
      );

      return Result.success(video);
    } on DioException catch (e) {
      final error = e.error;
      AppLogger.e('view $bvid failed', tag: 'video', error: error ?? e);
      if (error is AppError) {
        return Result.failure(error);
      }
      return Result.failure(
        AppError.network(message: 'Get video info failed', cause: e),
      );
    } catch (e, st) {
      AppLogger.e('view $bvid failed', tag: 'video', error: e, stackTrace: st);
      return Result.failure(
        AppError.unknown(
          message: 'Video info error: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// 分P列表，不过滤时长。搜索结果据此把多 P 拆开。
  Future<Result<List<VideoPage>>> getPageList(String bvid) async {
    try {
      final response = await _http.dio.get<Map<String, dynamic>>(
        '/x/player/pagelist',
        queryParameters: {'bvid': bvid},
      );

      final data = response.data!['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        AppLogger.w('pagelist $bvid empty', tag: 'video');
        return const Result.failure(AppError.notFound());
      }

      final pages = data
          .map((p) => _parsePageInfo(p as Map<String, dynamic>))
          .whereType<VideoPage>()
          .toList();
      if (pages.isEmpty) {
        AppLogger.w('pagelist $bvid unparsed raw=${data.length}', tag: 'video');
        return const Result.failure(AppError.notFound());
      }
      final brief = pages
          .take(12)
          .map((p) => 'p${p.pageIndex}:${p.duration.inSeconds}s')
          .join(',');
      AppLogger.d(
        'pagelist $bvid count=${pages.length} [$brief'
        '${pages.length > 12 ? ',…' : ''}]',
        tag: 'video',
      );
      return Result.success(pages);
    } on DioException catch (e) {
      final error = e.error;
      AppLogger.e('pagelist $bvid failed', tag: 'video', error: error ?? e);
      if (error is AppError) return Result.failure(error);
      return Result.failure(
        AppError.network(message: 'Get page list failed', cause: e),
      );
    } catch (e, st) {
      AppLogger.e(
        'pagelist $bvid failed',
        tag: 'video',
        error: e,
        stackTrace: st,
      );
      return Result.failure(
        AppError.unknown(
          message: 'Page list error: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// 获取视频标签
  Future<Result<List<String>>> getVideoTags(String bvid) async {
    try {
      final response = await _http.dio.get<Map<String, dynamic>>(
        '/x/tag/archive/tags',
        queryParameters: {'bvid': bvid},
      );

      final data = response.data!['data'] as List<dynamic>?;
      final tags =
          data
              ?.map((t) => (t as Map<String, dynamic>)['tag_name'] as String?)
              .where((t) => t != null)
              .cast<String>()
              .toList() ??
          [];

      return Result.success(tags);
    } catch (e) {
      // 标签获取失败不阻塞，返回空列表
      AppLogger.w('tags $bvid failed: $e', tag: 'video');
      return const Result.success([]);
    }
  }

  VideoPage? _parsePageInfo(Map<String, dynamic> json) {
    try {
      final cid = json['cid'] as int?;
      final page = json['page'] as int?;
      final part = json['part'] as String?;
      final duration = json['duration'] as int?;

      if (cid == null || page == null || part == null || duration == null) {
        AppLogger.w(
          'page missing fields cid=$cid page=$page part=$part duration=$duration',
          tag: 'video',
        );
        return null;
      }

      return VideoPage(
        cid: cid,
        title: part,
        duration: Duration(seconds: duration),
        pageIndex: page,
      );
    } catch (e) {
      AppLogger.w('page parse failed: $e', tag: 'video');
      return null;
    }
  }
}
