import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/dialogue_block.dart';
import '../data/fake_transcription_data_source.dart';
import '../utils/safe_change_notifier.dart';

// ============================================================
// 转写详情 ViewModel (MVVM)
// 状态: frame + tab + dialogues + chat + playback + generation
//
// 继承 SafeChangeNotifier: 持有 _playbackTimer (每秒 setState 推进度) +
// 各种 async 生成流程,dispose() 会取消 timer 但偶发回调仍可能 fire,
// notifyListeners() 由基类守护,避免 "used after disposed" 闪退。
// ============================================================
class TranscriptionDetailViewModel extends SafeChangeNotifier {
  // 当前 frame ('01' - '22')
  String _activeFrame = '10';
  String get activeFrame => _activeFrame;
  set activeFrame(String v) {
    _activeFrame = v;
    notifyListeners();
  }

  // 是否处于 "转写未生成" 占位页 (Figma 1218:6792)
  // 当 fileStatus == 'pending' 时启用, 点击 "生成" 进入正常流程
  bool _isUngenerated = false;
  bool get isUngenerated => _isUngenerated;
  set isUngenerated(bool v) {
    _isUngenerated = v;
    notifyListeners();
  }

  bool _isConsoleOpen = true;
  bool get isConsoleOpen => _isConsoleOpen;
  set isConsoleOpen(bool v) {
    _isConsoleOpen = v;
    notifyListeners();
  }

  // 播放
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  int _currentTime = 25;
  int get currentTime => _currentTime;
  final int _totalDuration = 3416;
  int get totalDuration => _totalDuration;
  String _activeTab = 'transcription'; // 'transcription' | 'summary'
  String get activeTab => _activeTab;
  set activeTab(String v) {
    _activeTab = v;
    notifyListeners();
  }

  // 生成
  String _selectedGenOption = 'auto';
  String get selectedGenOption => _selectedGenOption;
  set selectedGenOption(String v) {
    _selectedGenOption = v;
    notifyListeners();
  }

  String _customTemplate = '智能纪要';
  String get customTemplate => _customTemplate;
  set customTemplate(String v) {
    _customTemplate = v;
    notifyListeners();
  }

  String _customAudioLanguage = '中文简体-普通话';
  String get customAudioLanguage => _customAudioLanguage;
  set customAudioLanguage(String v) {
    _customAudioLanguage = v;
    notifyListeners();
  }

  String _customAiModel = '自动';
  String get customAiModel => _customAiModel;
  set customAiModel(String v) {
    _customAiModel = v;
    notifyListeners();
  }

  String _customTranslationLanguage = '不翻译';
  String get customTranslationLanguage => _customTranslationLanguage;
  set customTranslationLanguage(String v) {
    _customTranslationLanguage = v;
    notifyListeners();
  }

  String _activeSubScreen = 'none';
  String get activeSubScreen => _activeSubScreen;
  set activeSubScreen(String v) {
    _activeSubScreen = v;
    notifyListeners();
  }

  int _generationProgress = 0;
  int get generationProgress => _generationProgress;
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // 文件菜单
  String _renameValue = '';
  String get renameValue => _renameValue;
  set renameValue(String v) {
    _renameValue = v;
    notifyListeners();
  }

  bool _isMenuOpen = false;
  bool get isMenuOpen => _isMenuOpen;
  set isMenuOpen(bool v) {
    _isMenuOpen = v;
    notifyListeners();
  }

  bool _isRenameOpen = false;
  bool get isRenameOpen => _isRenameOpen;
  set isRenameOpen(bool v) {
    _isRenameOpen = v;
    notifyListeners();
  }

  bool _isShareOpen = false;
  bool get isShareOpen => _isShareOpen;
  set isShareOpen(bool v) {
    _isShareOpen = v;
    notifyListeners();
  }

  bool _isExportOpen = false;
  bool get isExportOpen => _isExportOpen;
  set isExportOpen(bool v) {
    _isExportOpen = v;
    notifyListeners();
  }

  String _exportSelectedFormat = 'MP3';
  String get exportSelectedFormat => _exportSelectedFormat;
  set exportSelectedFormat(String v) {
    _exportSelectedFormat = v;
    notifyListeners();
  }

  // Figma 1218:8625 导出弹窗
  // - 4 个导出项 (audio / transcription / summary / mindmap) 各自独立勾选 + 格式选择
  // - 默认: audio 未选 (录音本身是设备里), 其余 3 项默认勾选
  // - 每项有独立格式 (MP3/TXT/PNG 等), 点击右侧文字打开侧边面板切换
  final List<String> _exportCheckedOptions = ['transcription', 'summary', 'mindmap'];
  List<String> get exportCheckedOptions => List.unmodifiable(_exportCheckedOptions);

  // 每项当前选中的格式
  final Map<String, String> _exportFormats = {
    'audio': 'MP3',
    'transcription': 'TXT',
    'summary': 'TXT',
    'mindmap': 'PNG',
  };
  Map<String, String> get exportFormats => Map.unmodifiable(_exportFormats);

  // 每项可用的格式选项 (Figma 1218:8666 侧边面板: MP3/WAV/Alac 仅针对 audio)
  static const Map<String, List<String>> _exportFormatOptions = {
    'audio': ['MP3', 'WAV', 'Alac'],
    'transcription': ['TXT'],
    'summary': ['TXT'],
    'mindmap': ['PNG'],
  };
  List<String> exportFormatOptionsFor(String key) =>
      List.unmodifiable(_exportFormatOptions[key] ?? const []);

  // 侧边面板: 当前打开的是哪一项的格式选择 (null = 关闭)
  String? _exportOpenPanel;
  String? get exportOpenPanel => _exportOpenPanel;
  void openExportFormatPanel(String key) {
    if ((_exportFormatOptions[key] ?? const []).length <= 1) return; // 单选项不打开
    _exportOpenPanel = key;
    notifyListeners();
  }

  void closeExportFormatPanel() {
    _exportOpenPanel = null;
    notifyListeners();
  }

  void setExportFormat(String key, String format) {
    _exportFormats[key] = format;
    _exportOpenPanel = null;
    notifyListeners();
  }

  void toggleExportOption(String opt) {
    if (_exportCheckedOptions.contains(opt)) {
      _exportCheckedOptions.remove(opt);
    } else {
      _exportCheckedOptions.add(opt);
    }
    notifyListeners();
  }

  // Speaker
  final Map<String, String> _speakerMap = {
    '发言人1': '发言人1',
    '发言人2': '发言人2',
  };
  Map<String, String> get speakerMap => Map.unmodifiable(_speakerMap);

  // 内联编辑发言人: 按段落索引 (int) 区分, 避免同名发言人 (如"发言人1" 出现在多段)
  // 的所有段落同时进入编辑态. 旧字段 _editingSpeakerKey (String?) 保留给 frame '14' 弹窗使用.
  int? _editingSpeakerIndex;
  int? get editingSpeakerIndex => _editingSpeakerIndex;
  set editingSpeakerIndex(int? v) {
    _editingSpeakerIndex = v;
    notifyListeners();
  }

  String? _editingSpeakerKey;
  String? get editingSpeakerKey => _editingSpeakerKey;
  set editingSpeakerKey(String? v) {
    _editingSpeakerKey = v;
    notifyListeners();
  }

  void updateSpeaker(String key, String newName) {
    _speakerMap[key] = newName;
    notifyListeners();
  }

  // Share checklist
  final List<String> _shareCheckedOptions = ['audio', 'transcription', 'summary'];
  List<String> get shareCheckedOptions => List.unmodifiable(_shareCheckedOptions);
  void toggleShareOption(String opt) {
    if (_shareCheckedOptions.contains(opt)) {
      _shareCheckedOptions.remove(opt);
    } else {
      _shareCheckedOptions.add(opt);
    }
    notifyListeners();
  }

  // Editing
  int? _editingIndex;
  int? get editingIndex => _editingIndex;
  set editingIndex(int? v) {
    _editingIndex = v;
    notifyListeners();
  }

  // AI Q&A (Figma 1218:9112)
  // Figma 1218:9130: 右侧悬浮面板 (278x519, top-radius 16, white, shadow)
  // 面板显示与 activeFrame 解耦: 点击 AppBar "Ask AI" 打开, 关闭按钮关闭
  // 打开时主区域仍显示转写/纪要内容, 面板作为 overlay 浮在右侧
  bool _isAskAiOpen = false;
  bool get isAskAiOpen => _isAskAiOpen;

  void openAskAi() {
    if (_isAskAiOpen) return;
    _isAskAiOpen = true;
    notifyListeners();
  }

  void closeAskAi() {
    if (!_isAskAiOpen) return;
    _isAskAiOpen = false;
    notifyListeners();
  }

  void toggleAskAi() {
    _isAskAiOpen = !_isAskAiOpen;
    notifyListeners();
  }

  final List<Map<String, dynamic>> _chatMessages = [];
  List<Map<String, dynamic>> get chatMessages => List.unmodifiable(_chatMessages);
  bool _isAiLoading = false;
  bool get isAiLoading => _isAiLoading;

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    final keyword = extractKeyword(text);
    _chatMessages.add({'role': 'user', 'text': text, 'keyword': keyword});
    _isAiLoading = true;
    notifyListeners();

    Timer(const Duration(milliseconds: 1500), () {
      String answer;
      if (text.contains('阻力') ||
          text.contains('研发') ||
          text.contains('时间') ||
          text.contains('上市')) {
        answer =
            '关于$keyword的会议记录如下：\n原定上市时间为 9月1日，但研发端存在质量缺陷。研发反馈，$keyword的核心水追踪（hydration tracking）算法在高温高湿极端环境测试下有 10% 测量精度下降。大家最终决议：推迟两周上市，集中修复精度硬性质量指标，保全首发产品口碑。';
      } else {
        answer =
            '针对您的提问"$text"，AI分析了对白后为您解答：\n根据录音中 00:15 发言记录，我们发现$keyword 的核心议题。';
      }
      _chatMessages.add({
        'role': 'assistant',
        'text': answer,
        'keyword': keyword,
        'linkTime': 15,
      });
      _isAiLoading = false;
      _activeFrame = '22';
      notifyListeners();
    });
  }

  // 关键词提取 (用于高亮显示)
  String extractKeyword(String query) {
    const knownKeywords = [
      '智能水杯',
      '上市时间',
      '水追踪',
      'hydration tracking',
      '水合追踪',
      'OTA',
      'KOL',
      '研发',
    ];
    for (final kw in knownKeywords) {
      if (query.contains(kw)) return kw;
    }
    return query.length > 4 ? query.substring(0, 4) : query;
  }

  // ===== Frame Navigation ('01' to '22') =====
  void goToFrame(String frameId) {
    _activeFrame = frameId;
    if (frameId == '01') {
      _isPlaying = false;
      _isMenuOpen = false;
      _isRenameOpen = false;
      _isShareOpen = false;
      _isExportOpen = false;
    } else if (frameId == '02') {
      _isMenuOpen = true;
      _isRenameOpen = false;
      _isShareOpen = false;
      _isExportOpen = false;
    } else if (frameId == '03') {
      _isMenuOpen = false;
      _selectedGenOption = 'auto';
    } else if (frameId == '04') {
      _selectedGenOption = 'custom';
      _activeSubScreen = 'none';
    } else if (frameId == '05') {
      _selectedGenOption = 'custom';
      _activeSubScreen = 'template';
    } else if (frameId == '06') {
      _selectedGenOption = 'custom';
      _activeSubScreen = 'audioLang';
    } else if (frameId == '07') {
      _selectedGenOption = 'custom';
      _activeSubScreen = 'aiModel';
    } else if (frameId == '08') {
      _selectedGenOption = 'custom';
      _activeSubScreen = 'translateLang';
    } else if (frameId == '09') {
      _generationProgress = 20;
      _isGenerating = true;
      _simulateProgress();
    } else if (frameId == '10') {
      _isPlaying = false;
      _currentTime = 25;
      _customTranslationLanguage = '不翻译';
      _activeTab = 'transcription';
      _isMenuOpen = false;
      _isRenameOpen = false;
      _isShareOpen = false;
      _isExportOpen = false;
    } else if (frameId == '11') {
      if (!_bookmarkedLines.contains(1)) _bookmarkedLines.add(1);
      _activeTab = 'transcription';
    } else if (frameId == '12') {
      _customTranslationLanguage = 'English (US)';
      _currentTime = 25;
      _activeTab = 'transcription';
    } else if (frameId == '13') {
      _activeTab = 'transcription';
      _editingIndex = 1;
    } else if (frameId == '14') {
      _activeTab = 'transcription';
      _editingSpeakerKey = '发言人1';
    } else if (frameId == '15') {
      _activeTab = 'summary';
      _isMenuOpen = false;
      _isRenameOpen = false;
      _isShareOpen = false;
      _isExportOpen = false;
    } else if (frameId == '16') {
      _activeTab = 'summary';
      _isMenuOpen = true;
      _isRenameOpen = false;
      _isShareOpen = false;
      _isExportOpen = false;
    } else if (frameId == '17') {
      _activeTab = 'transcription';
      _isRenameOpen = true;
    } else if (frameId == '18') {
      _isShareOpen = true;
    } else if (frameId == '19') {
      _isExportOpen = true;
      _exportOpenPanel = null;
    } else if (frameId == '21') {
      _chatMessages.clear();
      _isAiLoading = false;
      _isAskAiOpen = true;
    } else if (frameId == '22') {
      _chatMessages.clear();
      _isAiLoading = false;
      _chatMessages.addAll([
        {
          'role': 'user',
          'text': '智能水杯',
          'keyword': '智能水杯',
        },
        {
          'role': 'assistant',
          'text': '关于智能水杯的会议记录如下：\n05-06 产品组会：用户增长测试与方案讨论',
          'keyword': '智能水杯',
          'linkTime': 15,
        }
      ]);
      _isAskAiOpen = true;
    } else if (frameId == '23') {
      _chatMessages.clear();
      _isAiLoading = true;
      _chatMessages.addAll([
        {
          'role': 'user',
          'text': '智能水杯',
          'keyword': '智能水杯',
        }
      ]);
      _isAskAiOpen = true;
    }
    notifyListeners();
  }

  void _simulateProgress() {
    if (!_isGenerating) return;
    Timer(const Duration(milliseconds: 250), () {
      if (!_isGenerating) return;
      _generationProgress += 15;
      if (_generationProgress >= 100) {
        _isGenerating = false;
        _generationProgress = 0;
        goToFrame('10');
      } else {
        _simulateProgress();
        notifyListeners();
      }
    });
  }

  // 书签
  final List<int> _bookmarkedLines = [1];
  List<int> get bookmarkedLines => List.unmodifiable(_bookmarkedLines);
  void toggleBookmark(int line) {
    if (_bookmarkedLines.contains(line)) {
      _bookmarkedLines.remove(line);
    } else {
      _bookmarkedLines.add(line);
    }
    notifyListeners();
  }

  // Dialogues
  late List<DialogueBlock> _dialogues;
  List<DialogueBlock> get dialogues => List.unmodifiable(_dialogues);

  String? initialTitle;

  TranscriptionDetailViewModel({this.initialTitle = ''}) {
    _renameValue = initialTitle ?? '';
    _dialogues = [];
    _loadData();
  }

  void _loadData() {
    if (kDebugMode) {
      _dialogues = FakeTranscriptionDataSource.getDemoDialogues();
    } else {
      _dialogues = [];
    }
  }

  void updateDialogueText(int index, String newText) {
    if (index < 0 || index >= _dialogues.length) return;
    _dialogues[index].text = newText;
    notifyListeners();
  }

  // ===== Playback =====
  Timer? _playbackTimer;
  void togglePlay() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_currentTime < _totalDuration) {
          _currentTime++;
          notifyListeners();
        } else {
          _isPlaying = false;
          _playbackTimer?.cancel();
          notifyListeners();
        }
      });
    } else {
      _playbackTimer?.cancel();
    }
    notifyListeners();
  }

  void seekTo(int sec) {
    _currentTime = sec.clamp(0, _totalDuration);
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
