import '../data/recording_item.dart';
import '../services/api/recording_file_api.dart';
import '../utils/app_logger.dart';
import '../utils/safe_change_notifier.dart';

// ============================================================
// 录音流 ViewModel (MVVM)
// 对齐 Figma 1218:2072 #1218:4679 (文件管理设备储存列表)
// 状态: 录音列表 + Tabs + 存储用量 + 删除 + AI 问答
//
// 数据源: RecordingFileApi (来自 power接口需求.csv 第 5 类)
//   - 列表: POST /sl/app/recording-file/list
//   - 删除: POST /sl/app/recording-file/remove
//
// AI 问答 (askAi): 暂时保留硬编码逻辑,将在 AI 域任务中切换为真实 API
//
// 继承 SafeChangeNotifier: refresh() 构造时启动、askAi() 1.5s 延迟、
// confirmDelete() await 期间用户都可能返回上一页导致 dispose(),
// notifyListeners() 调用由基类自动守护,不再抛 "used after disposed"。
// ============================================================
class RecordingsFeedViewModel extends SafeChangeNotifier {
  /// 真实设备序列号 (deviceSN)。为 null 或空字符串时表示「全部文件」。
  /// 对齐左侧导航「文件」分组下动态生成的真实设备子项。
  final String? deviceSN;
  final RecordingFileApi _api = RecordingFileApi.instance;

  // 录音数据
  final List<RecordingItem> _recordings = [];
  List<RecordingItem> get recordings => List.unmodifiable(_recordings);

  // 当前选中的 Tab: 'device' (设备储存) | 'host' (主机储存)
  String _activeTab = 'device';
  String get activeTab => _activeTab;

  // ===== 加载状态 =====
  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void setActiveTab(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  // 存储用量 (Figma 1218:4763-4771)
  // 设备储存: 3.6GB / 16GB; 主机储存: 0 / 0 (mocked)
  // 注: 后端暂未提供 storage 用量接口,继续使用占位值
  final double _usedGB = 3.6;
  final double _totalGB = 16.0;
  double get usedGB => _usedGB;
  final double _hostUsedGB = 0.0;
  final double _hostTotalGB = 0.0;

  String get usedText => _activeTab == 'device'
      ? '${_usedGB.toStringAsFixed(1)}GB / ${_totalGB.toStringAsFixed(0)}GB'
      : '${_hostUsedGB.toStringAsFixed(1)}GB / ${_hostTotalGB.toStringAsFixed(1)}GB';

  double get usagePercent {
    if (_activeTab == 'device') {
      if (_totalGB <= 0) return 0;
      return (_usedGB / _totalGB).clamp(0.0, 1.0);
    }
    if (_hostTotalGB <= 0) return 0;
    return (_hostUsedGB / _hostTotalGB).clamp(0.0, 1.0);
  }

  // AI 问答 (保留向后兼容,后续会切换到 AiApi)
  String _activeQuery = '';
  String get activeQuery => _activeQuery;

  bool _isChatOpen = false;
  bool get isChatOpen => _isChatOpen;
  bool _aiLoading = false;
  bool get aiLoading => _aiLoading;
  String _aiResponse = '';
  String get aiResponse => _aiResponse;

  // 待删除的录音 ID
  String? _deleteTargetId;
  String? get deleteTargetId => _deleteTargetId;

  RecordingsFeedViewModel({this.deviceSN}) {
    refresh();
  }

  // ===== 数据加载 =====

  /// 从后端拉取录音文件列表。
  /// [deviceSN] 非空时按真实设备序列号过滤 (对齐左侧导航「文件」分组
  /// 下动态生成的真实设备子项)。
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.getFileList(page: 0, deviceSN: deviceSN);
      _recordings
        ..clear()
        ..addAll(resp.items.map(_toRecordingItem));
    } catch (e, st) {
      AppLogger.e('recordings feed load failed', 'recordings-feed', e, st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 把 RecordingFile 转为 RecordingItem (供 1218:4697 表格使用)
  RecordingItem _toRecordingItem(dynamic file) {
    // 直接基于 RecordingFile 已有字段构造 (字段语义一致)
    return RecordingItem(
      id: file.id,
      title: file.title,
      dateText: file.dateText.contains(' ') ? file.dateText.split(' ').first : file.dateText,
      timeText: file.dateText.contains(' ') ? file.dateText.split(' ').last : '',
      duration: file.duration ?? '',
      syncStatus: _mapSyncStatus(file.fileStatus),
      transcription: '',
      fileSize: '',
    );
  }

  String _mapSyncStatus(String? fileStatus) {
    switch (fileStatus) {
      case 'completed':
        return 'synced';
      case 'transcribing':
        return 'transcribing';
      case 'waiting':
        return 'waiting';
      case 'failed':
        return 'failed';
      case 'pending':
        return 'synced';
      default:
        return 'synced';
    }
  }

  // 当前可见列表 (回收站已独立路由到 RecycleBinScreen, 此处不处理)
  List<RecordingItem> get visibleRecordings => _recordings;

  // ===== Commands =====

  void askAi(String query) {
    if (query.trim().isEmpty) return;
    _isChatOpen = true;
    _aiLoading = true;
    _activeQuery = query;
    _aiResponse = '';
    notifyListeners();

    // Simulated local smart assistant response (AI 域任务会替换为真实 askQuestion)
    Future.delayed(const Duration(milliseconds: 1500), () {
      // 用户可能在 1.5s 延迟期间返回上一页 → ViewModel 已被 dispose
      // 这里早退避免做无用功 (notifyListeners 已被基类守护,
      // 但 _aiLoading/_aiResponse 赋值仍然是无用的)
      if (isDisposed) return;
      _aiLoading = false;
      if (query.contains('总结') || query.contains('Q2') || query.contains('5月6日')) {
        _aiResponse =
            '【Talix AI 智能总结: Q2 运营及用户转化率研讨会】\n\n会议于 2026年5月6日 14:30 举行,核心成果如下:\n\n• 📈 业务大盘: Q2 季度用户活跃上涨 25%,付费转化率稳定在 4.8%,各项关键指标表现强劲。\n• ⚙️ 痛点解法: 为解决注册摩擦,确定于 6 月份接入「一键免密闪登」模块,计划降低 15% 的潜在流量滑落。\n• 🎙️ 硬件配合: 确认了 Talix 硬件离线录音音频自动双端传输协议通过验收,极大保障了数据的本地化及隐私防护。\n\n您是否想深入了解具体哪个汇报人的细节发言?';
      } else if (query.contains('算法') || query.contains('降噪') || query.contains('5月5日')) {
        _aiResponse =
            '【Talix AI 智能分析: 智能拾音硬件多声道算法评审】\n\n本次算法评审聚焦在两点核心微调:\n\n1. 🔍 「面对面访谈」模式定向滤波:将原本的全向拾音算法压缩为「前向 60° 指向性夹角阵列」,使得物理降噪在后向及侧向人声背景干扰中取得巨大成效。\n2. 📡 蓝牙多包流控制:升级了滑动重传 ARQ 模型,即使在大流量和弱网环境下也彻底杜绝音频断帧和偏音问题。\n\n已建议硬件极客组将此稳定固件打包至 v1.0.1 立即向测试团队发布。';
      } else {
        _aiResponse =
            '您好!我是您的 Talix AI 助手。我已经为您通读了硬件内的所有会议转写纪要。关于您提问的「$query」,您可以参考 5月6日 Q2 运营研讨会中的第二项流量治理决议,或者 5月5日 的降噪算法模型改进计划。请问需要我为您展开更详细的内容吗?';
      }
      notifyListeners();
    });
  }

  void closeChat() {
    _isChatOpen = false;
    _aiResponse = '';
    notifyListeners();
  }

  // ===== Delete (Figma 1218:4711 ic:outline-delete) =====
  void requestDelete(String id) {
    _deleteTargetId = id;
    notifyListeners();
  }

  void cancelDelete() {
    _deleteTargetId = null;
    notifyListeners();
  }

  /// 确认删除 — POST /sl/app/recording-file/remove
  Future<void> confirmDelete() async {
    final id = _deleteTargetId;
    if (id == null) return;
    try {
      await _api.removeFiles([id]);
      _recordings.removeWhere((item) => item.id == id);
      _deleteTargetId = null;
      notifyListeners();
    } catch (e, st) {
      AppLogger.e('recordings feed delete failed: $id', 'recordings-feed', e, st);
      _error = e.toString();
      _deleteTargetId = null;
      notifyListeners();
    }
  }
}
