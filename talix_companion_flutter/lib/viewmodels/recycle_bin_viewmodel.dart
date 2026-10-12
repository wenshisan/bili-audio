import '../data/trash_file.dart';
import '../services/api/recording_file_api.dart';
import '../utils/app_logger.dart';
import '../utils/safe_change_notifier.dart';

// ============================================================
// 回收站 ViewModel (MVVM 模式, Figma 1218:9817)
// 职责: 持有 trash 列表 + 搜索 + 恢复/删除/清空命令
// 视图只通过本 ViewModel 暴露的 getter 和命令操作数据
//
// 数据源: RecordingFileApi (来自 power接口需求.csv 第 5 类)
//   - 列表: GET /sl/app/recycled-file/list
//   - 永久删除: POST /sl/app/recycled-file/remove
//   - 恢复: POST /sl/app/recycled-file/recover
//
// 继承 SafeChangeNotifier: 构造时启动 refresh() + 各种恢复/删除/清空
// 命令都涉及网络 IO,用户快速离开屏幕会导致 dispose() 与 in-flight
// 请求完成重叠,notifyListeners() 由基类守护。
// ============================================================
class RecycleBinViewModel extends SafeChangeNotifier {
  final RecordingFileApi _api = RecordingFileApi.instance;

  // ===== 数据 =====
  final List<TrashFile> _files = [];

  /// 用于撤销最近一次永久删除 (清空或单项删除), 软删除前先暂存
  final List<TrashFile> _undoStack = [];

  // ===== 搜索 =====
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ===== Commands 触发后的轻量状态, 供 View 监听弹出提示 =====
  String? _lastActionMessage; // 例如 "已恢复" / "已永久删除"
  String? get lastActionMessage => _lastActionMessage;

  // ===== 加载状态 =====
  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  int _page = 0;
  int _totalPage = 1;
  bool get hasMore => _page + 1 < _totalPage;

  RecycleBinViewModel() {
    refresh();
  }

  // ===== 数据加载 =====

  /// 从后端拉取回收站文件列表
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.getRecycledFileList(page: 0);
      _page = resp.page;
      _totalPage = resp.totalPage;
      _files
        ..clear()
        ..addAll(resp.items);
    } catch (e, st) {
      AppLogger.e('recycled-file list load failed', 'recycle-bin', e, st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 加载下一页
  Future<void> loadMore() async {
    if (_loading || !hasMore) return;
    _loading = true;
    notifyListeners();
    try {
      final resp = await _api.getRecycledFileList(page: _page + 1);
      _page = resp.page;
      _totalPage = resp.totalPage;
      _files.addAll(resp.items);
    } catch (e, st) {
      AppLogger.e('recycled-file load more failed', 'recycle-bin', e, st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ===== 派生 Getters =====

  /// 应用搜索后的可见列表
  List<TrashFile> get visibleFiles {
    if (_searchQuery.isEmpty) return List.unmodifiable(_files);
    final q = _searchQuery.toLowerCase();
    return _files.where((f) => f.title.toLowerCase().contains(q)).toList();
  }

  /// 总数
  int get totalCount => _files.length;

  /// 当前是否为空
  bool get isEmpty => _files.isEmpty;

  /// 通过 id 查找 (在所有文件中, 不受搜索影响)
  TrashFile? findById(String id) {
    for (final f in _files) {
      if (f.id == id) return f;
    }
    return null;
  }

  // ===== Commands =====

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// 恢复单个文件 — POST /sl/app/recycled-file/recover
  Future<void> restoreFile(String id) async {
    final file = findById(id);
    if (file == null) return;
    try {
      await _api.recoverRecycledFiles([id]);
      _files.removeWhere((f) => f.id == id);
      _lastActionMessage = '已恢复「${file.title}」';
      notifyListeners();
    } catch (e, st) {
      AppLogger.e('restoreFile failed: $id', 'recycle-bin', e, st);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 永久删除单个文件 — POST /sl/app/recycled-file/remove
  /// 先暂存到 _undoStack 供后续撤回
  Future<void> deleteFile(String id) async {
    final file = findById(id);
    if (file == null) return;
    try {
      await _api.removeRecycledFiles([id]);
      _files.removeWhere((f) => f.id == id);
      _undoStack
        ..clear()
        ..add(file);
      _lastActionMessage = '已永久删除「${file.title}」';
      notifyListeners();
    } catch (e, st) {
      AppLogger.e('deleteFile failed: $id', 'recycle-bin', e, st);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 清空回收站 (Figma 1218:9931 "清空" 按钮)
  /// 暂存所有文件供一次性撤销
  Future<void> clearAll() async {
    if (_files.isEmpty) return;
    final ids = _files.map((f) => f.id).toList();
    try {
      await _api.removeRecycledFiles(ids);
      _undoStack
        ..clear()
        ..addAll(_files);
      _files.clear();
      _lastActionMessage = '已清空回收站';
      notifyListeners();
    } catch (e, st) {
      AppLogger.e('clearAll failed', 'recycle-bin', e, st);
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 撤销最近一次永久删除 (供 SnackBar 的 action 调用)
  /// 调 POST /sl/app/recycled-file/recover 把暂存的文件恢复
  Future<bool> undoLastDelete() async {
    if (_undoStack.isEmpty) return false;
    final ids = _undoStack.map((f) => f.id).toList();
    try {
      await _api.recoverRecycledFiles(ids);
      _files.insertAll(0, _undoStack);
      _undoStack.clear();
      _lastActionMessage = '已恢复';
      notifyListeners();
      return true;
    } catch (e, st) {
      AppLogger.e('undoLastDelete failed: $ids', 'recycle-bin', e, st);
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 清除最近一次的提示消息 (View 显示 toast 后调用, 避免重复触发)
  void clearLastActionMessage() {
    if (_lastActionMessage == null) return;
    _lastActionMessage = null;
  }
}
