// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '哔哩哔哩音频播放器';

  @override
  String get navDiscover => '发现';

  @override
  String get navLibrary => '歌单';

  @override
  String get navMine => '我的';

  @override
  String get searchHint => '搜索歌曲、歌手';

  @override
  String get searchEmpty => '输入关键词开始搜索';

  @override
  String get searchNoResult => '没有找到相关结果';

  @override
  String get searchHistory => '搜索历史';

  @override
  String get searchClearHistory => '清空';

  @override
  String get searchTooLong => '超过 15 分钟';

  @override
  String get searchLoadMore => '加载更多';

  @override
  String get errorRiskControl => '请求过于频繁，请稍后再试';

  @override
  String get errorNeedLogin => '需要登录';

  @override
  String get errorNetwork => '网络错误，请检查连接';

  @override
  String get errorNotFound => '视频不存在或不可播放';

  @override
  String get errorCopyright => '该视频因版权限制无法播放';

  @override
  String errorUnknown(String message) {
    return '出错了：$message';
  }

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get actionPlayNext => '下一首播放';

  @override
  String get actionAddToPlaylist => '加入歌单';

  @override
  String get actionAddToQueue => '加入播放队列';

  @override
  String get addedToQueue => '已加入播放队列';

  @override
  String addedToPlaylist(String name) {
    return '已加入「$name」';
  }

  @override
  String playCount(int count) {
    return '$count 次播放';
  }

  @override
  String pageInfo(int index, int total, String title) {
    return 'P$index/$total：$title';
  }

  @override
  String get nothingPlaying => '暂无播放';

  @override
  String get modeSequential => '顺序播放';

  @override
  String get modeListLoop => '列表循环';

  @override
  String get modeSingleLoop => '单曲循环';

  @override
  String get modeShuffle => '随机播放';

  @override
  String get modeSmartShuffle => '智能随机';

  @override
  String get queueTitle => '播放队列';

  @override
  String get queueEmpty => '队列为空';

  @override
  String get queueClear => '清空（保留当前）';

  @override
  String get queueSaveAsPlaylist => '保存为歌单';

  @override
  String get queueReorderDisabled => '随机模式下不能调整顺序';

  @override
  String get playerSpeed => '倍速';

  @override
  String get playerSleepTimer => '定时停止';

  @override
  String get playerViewOriginalTitle => '查看原始标题';

  @override
  String get playerEditTitle => '编辑歌名/歌手';

  @override
  String get playerLyricsPlaceholder => '暂无歌词';

  @override
  String get sleepOff => '关闭';

  @override
  String sleepMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get sleepAfterCurrent => '播完当前';

  @override
  String get sleepAfterNext => '播完下一首';

  @override
  String sleepRemaining(String time) {
    return '$time 后停止';
  }

  @override
  String get fieldSongName => '歌名';

  @override
  String get fieldArtist => '歌手';

  @override
  String get originalTitle => '原始标题';

  @override
  String get libraryEmpty => '还没有歌单';

  @override
  String get libraryCreate => '新建歌单';

  @override
  String get libraryRename => '重命名';

  @override
  String libraryDeleteConfirm(String name) {
    return '删除歌单「$name」？';
  }

  @override
  String get playlistName => '歌单名称';

  @override
  String playlistTrackCount(int count) {
    return '$count 首';
  }

  @override
  String get playlistPlayAll => '播放全部';

  @override
  String get playlistShuffle => '随机播放';

  @override
  String get playlistEmpty => '歌单里还没有歌曲';

  @override
  String get historyTitle => '播放历史';

  @override
  String get historyEmpty => '还没有播放记录';

  @override
  String get historyClear => '清空历史';

  @override
  String get historyToday => '今天';

  @override
  String get historyYesterday => '昨天';

  @override
  String get historyThisWeek => '本周';

  @override
  String get historyEarlier => '更早';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账号';

  @override
  String get settingsNotLoggedIn => '未登录';

  @override
  String get settingsPlayback => '播放';

  @override
  String get settingsQuality => '默认音质';

  @override
  String get settingsQualityGuestHint => '未登录时最高 132K';

  @override
  String get settingsCache => '缓存';

  @override
  String get settingsCacheLimit => '缓存上限';

  @override
  String settingsCacheUsage(String used, String limit) {
    return '已用 $used / $limit';
  }

  @override
  String get settingsCacheManage => '管理缓存';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsThemeMode => '主题模式';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsSeedColor => '主题色';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLicenses => '开源许可';

  @override
  String get cacheTitle => '缓存管理';

  @override
  String cacheSummary(int count, String size) {
    return '已缓存 $count 首，共 $size';
  }

  @override
  String get cacheClearAll => '清空未收藏的缓存';

  @override
  String get cacheClearConfirm => '将删除所有未加入歌单的缓存文件';

  @override
  String cacheCleared(int count) {
    return '已清理 $count 个文件';
  }

  @override
  String get lyricsLoading => '正在匹配歌词…';

  @override
  String get lyricsUncertain => '找到可能的歌词，请确认';

  @override
  String get lyricsPick => '选择歌词';

  @override
  String get lyricsNoLyrics => '无歌词';

  @override
  String get lyricsMarkNone => '标记为无歌词';

  @override
  String get lyricsRematch => '重新匹配';

  @override
  String get lyricsOffset => '歌词偏移';

  @override
  String lyricsOffsetValue(String seconds) {
    return '$seconds 秒';
  }

  @override
  String lyricsCandidate(String title, String artist, int score) {
    return '$title - $artist（$score%）';
  }

  @override
  String get loginTitle => '登录哔哩哔哩';

  @override
  String get loginScan => '使用哔哩哔哩 App 扫描二维码';

  @override
  String get loginWaiting => '等待扫描…';

  @override
  String get loginScanned => '已扫描，请在手机上确认';

  @override
  String get loginExpired => '二维码已过期';

  @override
  String get loginRetry => '重试';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirm => '确定退出登录？';

  @override
  String get loginPrompt => '当前音质受限，登录后可使用更高音质';
}
