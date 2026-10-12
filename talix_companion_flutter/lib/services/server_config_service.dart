import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/server_profile.dart';

/// 服务器环境配置中心
///
/// 职责:
///  1. 启动时从 `assets/config/servers.json` 加载内置预置 (Local/Dev/Staging/Production)
///  2. 决定活动 profile — 优先级:
///     a) `assets/config/active_server.json` 中的 `activeServerId` (最高,开发期强制切换)
///     b) SharedPreferences 中保存的上次选择
///     c) 第一个内置 profile (兜底)
///  3. 暴露 [profiles] / [active] / [activeSource] 给 UI 与 ApiClient
///  4. [setActive] 仅写入 SharedPreferences,不会回写 override 文件 —
///     override 文件始终是启动期"强制入口",UI 切换仅对当前会话生效 (便于回归)
///
/// 监听者包括:
///  - ApiClient (更新 dio.options.baseUrl)
///  - AuthViewModel (server 切换通常应清空 token 重新登录)
///  - 任何需要 rebuild 的 UI (e.g. me_profile_screen 顶部 chip)
class ServerConfigService extends ChangeNotifier {
  ServerConfigService._();
  static final ServerConfigService instance = ServerConfigService._();

  static const String _activeIdKey = 'active_server_profile_id';
  static const String _builtinAssetPath = 'assets/config/servers.json';

  /// 启动期 override 文件 — 路径与 [activeServerOverrideAssetPath] getter 保持一致,
  /// 供测试代码和 UI 检查使用。
  static const String _activeOverrideAssetPath =
      'assets/config/active_server.json';

  /// 供外部 (例如 dev tools / 测试) 读取 override 资产路径
  String get activeServerOverrideAssetPath => _activeOverrideAssetPath;

  /// 当前活动 profile 的来源 — UI 可据此显示角标提示用户
  ActiveServerSource _activeSource = ActiveServerSource.fallback;
  ActiveServerSource get activeSource => _activeSource;

  List<ServerProfile> _profiles = const [];
  ServerProfile? _active;
  bool _ready = false;

  List<ServerProfile> get profiles => List.unmodifiable(_profiles);
  ServerProfile? get active => _active;
  bool get isReady => _ready;

  /// 启动时调用一次
  Future<void> initialize() async {
    if (_ready) return;

    // 1. 加载内置预置
    final raw = await rootBundle.loadString(_builtinAssetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _profiles = list.map(ServerProfile.fromJson).toList();

    // 2. 解析活动 profile — 优先级: override > SharedPreferences > 第一个内置
    final prefs = await SharedPreferences.getInstance();
    final overrideId = await _readOverrideId();
    final savedId = prefs.getString(_activeIdKey);

    String? targetId;
    if (overrideId != null && _profiles.any((p) => p.id == overrideId)) {
      targetId = overrideId;
      _activeSource = ActiveServerSource.override;
      // 同步到 SharedPreferences,保证 UI 切换逻辑统一从 prefs 读
      await prefs.setString(_activeIdKey, overrideId);
    } else if (savedId != null && _profiles.any((p) => p.id == savedId)) {
      targetId = savedId;
      _activeSource = ActiveServerSource.persisted;
    } else {
      targetId = _profiles.first.id;
      _activeSource = ActiveServerSource.fallback;
    }

    _active = _profiles.firstWhere(
      (p) => p.id == targetId,
      orElse: () => _profiles.first,
    );

    _ready = true;
    notifyListeners();
  }

  /// 切换活动服务器
  ///
  /// 仅更新内存与 SharedPreferences,**不会**回写 override 文件。
  /// 下次启动时如果 override 文件仍指向其他 server,会再次被强制切换回去。
  /// 调用方需负责清空 token / 取消挂起请求等副作用。
  Future<void> setActive(String id) async {
    if (_active?.id == id) return;
    final next = _profiles.firstWhere(
      (p) => p.id == id,
      orElse: () => _active ?? _profiles.first,
    );
    _active = next;
    _activeSource = ActiveServerSource.persisted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeIdKey, id);
    notifyListeners();
  }

  /// 读取并解析 override 文件中的 `activeServerId` 字段。
  ///
  /// 文件不存在 / 解析失败 / 字段缺失或为空 — 均返回 null (调用方按 SharedPreferences 兜底)。
  Future<String?> _readOverrideId() async {
    try {
      final raw = await rootBundle.loadString(_activeOverrideAssetPath);
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final v = json['activeServerId'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    } catch (_) {
      // 文件不存在、JSON 解析失败、字段类型错 — 一律静默忽略
      return null;
    }
  }
}

/// 活动 profile 的来源 — UI 可据此显示 "配置文件覆盖" / "上次选择" 角标
enum ActiveServerSource {
  /// 来自 `assets/config/active_server.json` 强制覆盖
  override,

  /// 来自 SharedPreferences 中保存的上次选择
  persisted,

  /// 兜底 — 使用 profiles 列表的第一个
  fallback,
}
