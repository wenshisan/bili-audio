import 'package:dio/dio.dart';

import '../../models/auth_models.dart';
import '../../utils/app_logger.dart';
import 'api_client.dart';

/// 业务 API 基类 — 统一封装 POST/GET/PUT/DELETE + 业务码解析 + 异常包装
///
/// 业务响应统一形态 (与 [ApiResult] 一致):
/// ```
/// { "code": 0, "data": <T>, "msg": "..." }
/// ```
/// - `code == 0` 视为业务成功, [fromData] 解析 `data` 字段
/// - `code != 0` 抛 [ApiException] 携带业务码与消息
/// - HTTP 4xx/5xx 抛 [ApiException] 携带 httpStatus
/// - Dio 异常 (超时 / 连接失败) 抛 [ApiException] 携带可读消息
///
/// 子类只需:
/// 1. 继承本类
/// 2. 覆盖 [apiPrefix] (如 [AuthApi] 用 `/app-api` + 业务子路径;如需独立前缀可重写)
/// 3. 覆盖 [logTag] (用于 [AppLogger] 的子标签,默认 `api`)
/// 4. 在公开方法内调用 [post] / [get] / [put] / [delete] 并提供 [fromData]
///
/// 设计要点:
/// - 路径不要重复写 `/app-api` 前缀,基类会自动拼接
/// - 路径必须以 `/` 开头,例如 `/sl/app/recording-device/list`
/// - [fromData] 为 null 时只校验 `code==0`,不解析 `data` (适合只关心成功/失败的接口)
abstract class BaseApiService {
  /// API 业务前缀,默认与 [AuthApi] 对齐使用 `/app-api`。
  /// 子类可覆盖为独立网关 (如 `/app-api-2`)。
  String get apiPrefix => '/app-api';

  /// 日志子标签 — 区分各业务域 (auth / device / file / ...),默认 `api`。
  String get logTag => 'api';

  Dio get _dio => ApiClient.instance.dio;

  // =================== POST / GET / PUT / DELETE ===================

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? fromData,
  }) async {
    final fullPath = '$apiPrefix$path';
    final startMs = DateTime.now().millisecondsSinceEpoch;
    AppLogger.d('→ POST $fullPath', logTag);
    try {
      final resp = await _dio.post(
        fullPath,
        data: data,
        queryParameters: query,
      );
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.d('← POST $fullPath status=${resp.statusCode} (${elapsed}ms)',
          logTag);
      return _unwrap(resp, fromData);
    } on DioException catch (e) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.w(
        'POST $fullPath failed: type=${e.type} (${elapsed}ms) msg=${e.message}',
        logTag,
      );
      throw _wrapDio(e);
    } catch (e, st) {
      AppLogger.e('POST $fullPath unexpected error', logTag, e, st);
      rethrow;
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic raw)? fromData,
  }) async {
    final fullPath = '$apiPrefix$path';
    final startMs = DateTime.now().millisecondsSinceEpoch;
    AppLogger.d('→ GET $fullPath', logTag);
    try {
      final resp = await _dio.get(fullPath, queryParameters: query);
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.d('← GET $fullPath status=${resp.statusCode} (${elapsed}ms)',
          logTag);
      return _unwrap(resp, fromData);
    } on DioException catch (e) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.w(
        'GET $fullPath failed: type=${e.type} (${elapsed}ms) msg=${e.message}',
        logTag,
      );
      throw _wrapDio(e);
    } catch (e, st) {
      AppLogger.e('GET $fullPath unexpected error', logTag, e, st);
      rethrow;
    }
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? fromData,
  }) async {
    final fullPath = '$apiPrefix$path';
    final startMs = DateTime.now().millisecondsSinceEpoch;
    AppLogger.d('→ PUT $fullPath', logTag);
    try {
      final resp = await _dio.put(
        fullPath,
        data: data,
        queryParameters: query,
      );
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.d('← PUT $fullPath status=${resp.statusCode} (${elapsed}ms)',
          logTag);
      return _unwrap(resp, fromData);
    } on DioException catch (e) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.w(
        'PUT $fullPath failed: type=${e.type} (${elapsed}ms) msg=${e.message}',
        logTag,
      );
      throw _wrapDio(e);
    } catch (e, st) {
      AppLogger.e('PUT $fullPath unexpected error', logTag, e, st);
      rethrow;
    }
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? fromData,
  }) async {
    final fullPath = '$apiPrefix$path';
    final startMs = DateTime.now().millisecondsSinceEpoch;
    AppLogger.d('→ DELETE $fullPath', logTag);
    try {
      final resp = await _dio.delete(
        fullPath,
        data: data,
        queryParameters: query,
      );
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.d('← DELETE $fullPath status=${resp.statusCode} (${elapsed}ms)',
          logTag);
      return _unwrap(resp, fromData);
    } on DioException catch (e) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startMs;
      AppLogger.w(
        'DELETE $fullPath failed: type=${e.type} (${elapsed}ms) msg=${e.message}',
        logTag,
      );
      throw _wrapDio(e);
    } catch (e, st) {
      AppLogger.e('DELETE $fullPath unexpected error', logTag, e, st);
      rethrow;
    }
  }

  // =================== 内部 helper ===================

  T _unwrap<T>(Response<dynamic> resp, T Function(dynamic raw)? fromData) {
    final status = resp.statusCode ?? 0;
    if (status >= 400) {
      AppLogger.w('HTTP $status: ${resp.statusMessage ?? '请求失败'}', logTag);
      throw ApiException(
        'HTTP $status: ${resp.statusMessage ?? '请求失败'}',
        httpStatus: status,
      );
    }
    final body = resp.data;
    if (body is! Map<String, dynamic>) {
      AppLogger.w('响应格式错误: body=${body.runtimeType}', logTag);
      throw ApiException('响应格式错误', httpStatus: status);
    }

    // 先检查业务错误码,避免在错误响应时尝试解析 data
    final code = (body['code'] as num?)?.toInt() ?? -1;
    final msg = body['msg'] as String?;
    if (code != 0) {
      AppLogger.w('业务错误 code=$code msg=$msg', logTag);
      throw ApiException(msg ?? '业务错误', code: code);
    }

    // 业务成功时才解析 data
    final result = ApiResult.fromJson(body, fromData);
    if (fromData == null) {
      // 业务只需要确认成功
      return null as T;
    }
    if (result.data == null) {
      AppLogger.w('响应数据为空 code=${result.code}', logTag);
      throw ApiException('响应数据为空', code: result.code);
    }
    return result.data as T;
  }

  ApiException _wrapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      AppLogger.w('Dio timeout: ${e.message}', logTag);
      return const ApiException('网络超时,请稍后重试');
    }
    if (e.type == DioExceptionType.connectionError) {
      AppLogger.w('Dio connection error: ${e.message}', logTag);
      return ApiException('网络连接失败: ${e.message ?? ''}');
    }
    AppLogger.w('Dio other: ${e.message}', logTag);
    return ApiException('请求失败: ${e.message ?? ''}');
  }

  Map<String, dynamic> asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const ApiException('数据格式错误');
  }
}
