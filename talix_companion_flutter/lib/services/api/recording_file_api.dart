import '../../data/recording_file.dart';
import '../../data/trash_file.dart';
import '../../utils/api_formatters.dart';
import 'base_api_service.dart';

/// 录音文件管理 API
///
/// 7 个端点 (来自 power接口需求(APP接口需求) (2).csv 第 5 类):
/// - GET    /sl/app/recording-file/list           录音文件列表 (含分页)
/// - POST   /sl/app/recording-file/add            新增录音文件
/// - POST   /sl/app/recording-file/remove         删除录音文件 (移至回收站)
/// - POST   /sl/app/recording-file/update-name    修改录音文件名字
/// - GET    /sl/app/recycled-file/list            回收站文件列表
/// - POST   /sl/app/recycled-file/remove          回收站文件永久删除
/// - POST   /sl/app/recycled-file/recover         回收站文件恢复
///
/// 列表接口的响应中除了 `data.fileList` 还包含 `page` / `totalPage`,
/// 通过 [RecordingFileList] / [TrashFileList] 暴露给调用方,避免 ViewModel 重复解析。
///
/// 注意: CSV(2) 中 list 类接口改为 GET,带 query 参数 (page / pageSize)。
/// 旧 CSV(1) 文档标注为 GET 但实际服务端可能接受 POST,这里以 CSV(2) 为准切到 GET。
class RecordingFileApi extends BaseApiService {
  RecordingFileApi._();
  static final RecordingFileApi instance = RecordingFileApi._();

  @override
  String get apiPrefix => '/app-api';

  @override
  String get logTag => 'file-api';

  // =================== 录音文件 ===================

  /// GET /sl/app/recording-file/list
  /// 录音文件列表 (含分页) — CSV(2) 标注为 GET, query 参数传 page / pageSize
  ///
  /// **不要改回 POST**: 后端 Spring Controller 只接受 GET,POST 会返回 405
  /// "Request method 'POST' not supported"。
  ///
  /// [deviceSN] 可选,传入时按真实设备序列号过滤文件列表 (对齐左侧导航
  /// 「文件」分组下动态生成的真实设备子项)。
  ///
  /// 返回 [RecordingFileList],包含当前页 [items] + 分页元信息 ([page] / [totalPage])
  Future<RecordingFileList> getFileList({
    int page = 0,
    int pageSize = 50,
    String? deviceSN,
  }) async {
    final query = <String, Object>{
      'page': page,
      'pageSize': pageSize,
    };
    if (deviceSN != null && deviceSN.isNotEmpty) {
      query['deviceSN'] = deviceSN;
    }
    return get<RecordingFileList>(
      '/sl/app/recording-file/list',
      query: query,
      fromData: (raw) {
        if (raw is! Map) {
          return const RecordingFileList(items: [], page: 0, totalPage: 0);
        }
        final data = asMap(raw);
        // data 内嵌 fileList
        final inner = (data['data'] is Map)
            ? asMap(data['data'])
            : data;
        final list = (inner['fileList'] is List)
            ? inner['fileList'] as List
            : (inner['list'] is List ? inner['list'] as List : <dynamic>[]);
        final items = list
            .whereType<Map>()
            .map((e) => RecordingFile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final respPage = asInt(inner['page'], fallback: page);
        final respTotalPage = asInt(inner['totalPage'], fallback: 1);
        return RecordingFileList(
          items: items,
          page: respPage,
          totalPage: respTotalPage,
        );
      },
    );
  }

  /// POST /sl/app/recording-file/add
  /// 新增录音文件 — 返回后端下发的 fileId
  Future<String> addFile({
    required String deviceSN,
    required String fileName,
    required int duration,
    required int status,
  }) async {
    return post<String>(
      '/sl/app/recording-file/add',
      data: {
        'deviceSN': deviceSN,
        'fileName': fileName,
        'duration': duration,
        'status': status,
      },
      fromData: (raw) {
        if (raw is Map) {
          return (raw['fileId'] ?? '').toString();
        }
        return raw.toString();
      },
    );
  }

  /// POST /sl/app/recording-file/remove
  /// 删除录音文件 (移至回收站, 接受 fileId 数组批量)
  Future<void> removeFiles(List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    await post(
      '/sl/app/recording-file/remove',
      data: {'fileList': fileIds},
    );
  }

  /// POST /sl/app/recording-file/update-name
  /// 修改录音文件名字
  Future<void> updateFileName({
    required String fileId,
    required String fileName,
  }) async {
    await post(
      '/sl/app/recording-file/update-name',
      data: {
        'fileId': fileId,
        'fileName': fileName,
      },
    );
  }

  // =================== 回收站 ===================

  /// GET /sl/app/recycled-file/list
  /// 回收站文件列表 — CSV(2) 改为 GET
  Future<TrashFileList> getRecycledFileList({int page = 0, int pageSize = 50}) async {
    return get<TrashFileList>(
      '/sl/app/recycled-file/list',
      query: {
        'page': page,
        'pageSize': pageSize,
      },
      fromData: (raw) {
        if (raw is! Map) {
          return const TrashFileList(items: [], page: 0, totalPage: 0);
        }
        final data = asMap(raw);
        final inner = (data['data'] is Map) ? asMap(data['data']) : data;
        final list = (inner['fileList'] is List)
            ? inner['fileList'] as List
            : (inner['list'] is List ? inner['list'] as List : <dynamic>[]);
        final items = list
            .whereType<Map>()
            .map((e) => TrashFile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return TrashFileList(
          items: items,
          page: asInt(inner['page'], fallback: page),
          totalPage: asInt(inner['totalPage'], fallback: 1),
        );
      },
    );
  }

  /// POST /sl/app/recycled-file/remove
  /// 回收站文件永久删除 (接受 fileId 数组批量)
  Future<void> removeRecycledFiles(List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    await post(
      '/sl/app/recycled-file/remove',
      data: {'fileList': fileIds},
    );
  }

  /// POST /sl/app/recycled-file/recover
  /// 回收站文件恢复 (接受 fileId 数组批量)
  Future<void> recoverRecycledFiles(List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    await post(
      '/sl/app/recycled-file/recover',
      data: {'fileList': fileIds},
    );
  }
}

/// 录音文件列表响应 (含分页元信息)
class RecordingFileList {
  final List<RecordingFile> items;
  final int page;
  final int totalPage;

  const RecordingFileList({
    required this.items,
    required this.page,
    required this.totalPage,
  });

  bool get hasMore => page + 1 < totalPage;
}

/// 回收站文件列表响应
class TrashFileList {
  final List<TrashFile> items;
  final int page;
  final int totalPage;

  const TrashFileList({
    required this.items,
    required this.page,
    required this.totalPage,
  });

  bool get hasMore => page + 1 < totalPage;
}
