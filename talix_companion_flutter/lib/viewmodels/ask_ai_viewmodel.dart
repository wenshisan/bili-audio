import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/api/ai_api.dart';
import '../utils/app_logger.dart';

// ============================================================
// Ask AI ViewModel (MVVM - Figma 1218:9580/9725/9652)
// 状态: 输入框文本 + 加载中 + 当前查询 (topic chip) + AI 响应
// 状态机: home (无 query) → loading (submit) → response
//
// API 接入: askQuestion + getQuestionList (power接口需求(2).csv 第 10 类)
// 失败兜底: AI 调用失败时返回 "AI 暂时无法回答,请稍后再试" 文案
//
// 兼容说明: 旧版 hardcoded 的 `suggestions` / `topicPrefix` / `suffix` 字段
// 保留,屏幕侧代码无须改动。
// ============================================================
class AskAiViewModel extends ChangeNotifier {
  String _chatInput = '';
  String get chatInput => _chatInput;
  set chatInput(String v) {
    if (_chatInput == v) return;
    _chatInput = v;
    notifyListeners();
  }

  // 当前提交的查询 (用于 loading/response 状态的 topic chip)
  String _activeQuery = '';
  String get activeQuery => _activeQuery;

  // 加载状态 (Figma 1218:9725)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // AI 响应 (Figma 1218:9652)
  String? _response;
  String? get response => _response;
  bool get hasResponse => _response != null;

  // 推荐问题列表 (来自 getQuestionList,首屏显示 3 个)
  List<String> _suggestedQuestions = const [
    '下次会议前需要准备什么?',
    '列出所有待办事项?',
    '总结市场部的反馈?',
  ];
  // 兼容旧 API: 旧版 `suggestions` 是 static List<String> 常量,
  // 这里改用 instance getter,旧调用方不变
  List<String> get suggestions => _suggestedQuestions;

  // 当前选中的文件 ID 列表(默认空,Ask AI 屏顶部"选择文件"按钮会修改)
  final List<String> _selectedFileIds = [];
  List<String> get selectedFileIds => List.unmodifiable(_selectedFileIds);

  // Figma 1218:9717: topic chip 默认文本
  static const String defaultTopic = '智能水杯';

  // 兼容旧 API: 旧版用 topicPrefix + suffix 拼接示例响应,
  // 新版响应来自真实 API;保留以防屏幕侧直接引用
  static const String topicPrefix = '关于';
  static const String suffix = '的会议记录如下:\n05-06 产品组会:用户增长测试与方案讨论';

  // API 兜底文本
  static const String _fallbackResponse = 'AI 暂时无法回答,请稍后再试。';

  final AiApi _api = AiApi.instance;

  AskAiViewModel() {
    // 进入页面时拉取推荐问题(异步,不阻塞 UI)
    _refreshQuestions();
  }

  /// 提交查询 — 走真实 API (power接口需求(2).csv 第 10 类 askQuestion)
  Future<void> submitQuery(String query) async {
    if (query.trim().isEmpty) return;
    AppLogger.d('submit: $query (files=${_selectedFileIds.length})', 'AskAi');
    _activeQuery = query;
    _isLoading = true;
    _response = null;
    notifyListeners();

    try {
      final resp = await _api.askQuestion(
        fileList: List<String>.from(_selectedFileIds),
        question: query,
      );
      _response =
          resp.answer.isNotEmpty ? resp.answer : _fallbackResponse;
    } catch (e, st) {
      AppLogger.e('askQuestion failed: $query', 'AskAi', e, st);
      _response = _fallbackResponse;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 刷新推荐问题 (getQuestionList)
  Future<void> _refreshQuestions() async {
    try {
      final list = await _api.getQuestionList(
        fileList: List<String>.from(_selectedFileIds),
      );
      if (list.isNotEmpty) {
        _suggestedQuestions = list.map((e) => e.title).toList();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.w('getQuestionList failed: $e', 'AskAi');
      // 失败时保留默认建议
    }
  }

  /// 用户切换"选择文件"时调用
  void setSelectedFiles(List<String> fileIds) {
    _selectedFileIds
      ..clear()
      ..addAll(fileIds);
    notifyListeners();
    // 重新拉推荐问题
    _refreshQuestions();
  }
}
