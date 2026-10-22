import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'bili-audio'**
  String get appTitle;

  /// No description provided for @navDiscover.
  ///
  /// In zh, this message translates to:
  /// **'发现'**
  String get navDiscover;

  /// No description provided for @navLibrary.
  ///
  /// In zh, this message translates to:
  /// **'歌单'**
  String get navLibrary;

  /// No description provided for @navMine.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navMine;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索歌曲、歌手'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'输入关键词开始搜索'**
  String get searchEmpty;

  /// No description provided for @searchNoResult.
  ///
  /// In zh, this message translates to:
  /// **'没有找到相关结果'**
  String get searchNoResult;

  /// No description provided for @searchHistory.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史'**
  String get searchHistory;

  /// No description provided for @searchClearHistory.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get searchClearHistory;

  /// No description provided for @searchTooLong.
  ///
  /// In zh, this message translates to:
  /// **'超过 15 分钟'**
  String get searchTooLong;

  /// No description provided for @searchLoadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get searchLoadMore;

  /// No description provided for @errorRiskControl.
  ///
  /// In zh, this message translates to:
  /// **'请求过于频繁，请稍后再试'**
  String get errorRiskControl;

  /// No description provided for @errorNeedLogin.
  ///
  /// In zh, this message translates to:
  /// **'需要登录'**
  String get errorNeedLogin;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络错误，请检查连接'**
  String get errorNetwork;

  /// No description provided for @errorNotFound.
  ///
  /// In zh, this message translates to:
  /// **'视频不存在或不可播放'**
  String get errorNotFound;

  /// No description provided for @errorCopyright.
  ///
  /// In zh, this message translates to:
  /// **'该视频因版权限制无法播放'**
  String get errorCopyright;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'出错了：{message}'**
  String errorUnknown(String message);

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @actionPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get actionPlay;

  /// No description provided for @actionPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get actionPause;

  /// No description provided for @actionPlayNext.
  ///
  /// In zh, this message translates to:
  /// **'下一首播放'**
  String get actionPlayNext;

  /// No description provided for @actionAddToPlaylist.
  ///
  /// In zh, this message translates to:
  /// **'加入歌单'**
  String get actionAddToPlaylist;

  /// No description provided for @actionAddToQueue.
  ///
  /// In zh, this message translates to:
  /// **'加入播放队列'**
  String get actionAddToQueue;

  /// No description provided for @addedToQueue.
  ///
  /// In zh, this message translates to:
  /// **'已加入播放队列'**
  String get addedToQueue;

  /// No description provided for @addedToPlaylist.
  ///
  /// In zh, this message translates to:
  /// **'已加入「{name}」'**
  String addedToPlaylist(String name);

  /// No description provided for @playCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次播放'**
  String playCount(int count);

  /// No description provided for @pageInfo.
  ///
  /// In zh, this message translates to:
  /// **'P{index}/{total}：{title}'**
  String pageInfo(int index, int total, String title);

  /// No description provided for @nothingPlaying.
  ///
  /// In zh, this message translates to:
  /// **'暂无播放'**
  String get nothingPlaying;

  /// No description provided for @modeSequential.
  ///
  /// In zh, this message translates to:
  /// **'顺序播放'**
  String get modeSequential;

  /// No description provided for @modeListLoop.
  ///
  /// In zh, this message translates to:
  /// **'列表循环'**
  String get modeListLoop;

  /// No description provided for @modeSingleLoop.
  ///
  /// In zh, this message translates to:
  /// **'单曲循环'**
  String get modeSingleLoop;

  /// No description provided for @modeShuffle.
  ///
  /// In zh, this message translates to:
  /// **'随机播放'**
  String get modeShuffle;

  /// No description provided for @modeSmartShuffle.
  ///
  /// In zh, this message translates to:
  /// **'智能随机'**
  String get modeSmartShuffle;

  /// No description provided for @queueTitle.
  ///
  /// In zh, this message translates to:
  /// **'播放队列'**
  String get queueTitle;

  /// No description provided for @queueEmpty.
  ///
  /// In zh, this message translates to:
  /// **'队列为空'**
  String get queueEmpty;

  /// No description provided for @queueClear.
  ///
  /// In zh, this message translates to:
  /// **'清空（保留当前）'**
  String get queueClear;

  /// No description provided for @queueSaveAsPlaylist.
  ///
  /// In zh, this message translates to:
  /// **'保存为歌单'**
  String get queueSaveAsPlaylist;

  /// No description provided for @queueReorderDisabled.
  ///
  /// In zh, this message translates to:
  /// **'随机模式下不能调整顺序'**
  String get queueReorderDisabled;

  /// No description provided for @queueRemove.
  ///
  /// In zh, this message translates to:
  /// **'从队列移除'**
  String get queueRemove;

  /// No description provided for @queueSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'在队列中搜索'**
  String get queueSearchHint;

  /// No description provided for @queueSearchNoResult.
  ///
  /// In zh, this message translates to:
  /// **'队列中没有匹配的歌曲'**
  String get queueSearchNoResult;

  /// No description provided for @playerSpeed.
  ///
  /// In zh, this message translates to:
  /// **'倍速'**
  String get playerSpeed;

  /// No description provided for @playerSleepTimer.
  ///
  /// In zh, this message translates to:
  /// **'定时停止'**
  String get playerSleepTimer;

  /// No description provided for @playerViewOriginalTitle.
  ///
  /// In zh, this message translates to:
  /// **'查看原始标题'**
  String get playerViewOriginalTitle;

  /// No description provided for @playerEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑歌名/歌手'**
  String get playerEditTitle;

  /// No description provided for @playerLyricsPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'暂无歌词'**
  String get playerLyricsPlaceholder;

  /// No description provided for @sleepOff.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get sleepOff;

  /// No description provided for @sleepMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟'**
  String sleepMinutes(int minutes);

  /// No description provided for @sleepAfterCurrent.
  ///
  /// In zh, this message translates to:
  /// **'播完当前'**
  String get sleepAfterCurrent;

  /// No description provided for @sleepAfterNext.
  ///
  /// In zh, this message translates to:
  /// **'播完下一首'**
  String get sleepAfterNext;

  /// No description provided for @sleepRemaining.
  ///
  /// In zh, this message translates to:
  /// **'{time} 后停止'**
  String sleepRemaining(String time);

  /// No description provided for @fieldSongName.
  ///
  /// In zh, this message translates to:
  /// **'歌名'**
  String get fieldSongName;

  /// No description provided for @fieldArtist.
  ///
  /// In zh, this message translates to:
  /// **'歌手'**
  String get fieldArtist;

  /// No description provided for @originalTitle.
  ///
  /// In zh, this message translates to:
  /// **'原始标题'**
  String get originalTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有歌单'**
  String get libraryEmpty;

  /// No description provided for @libraryCreate.
  ///
  /// In zh, this message translates to:
  /// **'新建歌单'**
  String get libraryCreate;

  /// No description provided for @libraryRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get libraryRename;

  /// No description provided for @libraryDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'删除歌单「{name}」？'**
  String libraryDeleteConfirm(String name);

  /// No description provided for @playlistName.
  ///
  /// In zh, this message translates to:
  /// **'歌单名称'**
  String get playlistName;

  /// No description provided for @playlistTrackCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 首'**
  String playlistTrackCount(int count);

  /// No description provided for @playlistPlayAll.
  ///
  /// In zh, this message translates to:
  /// **'播放全部'**
  String get playlistPlayAll;

  /// No description provided for @playlistShuffle.
  ///
  /// In zh, this message translates to:
  /// **'随机播放'**
  String get playlistShuffle;

  /// No description provided for @playlistEmpty.
  ///
  /// In zh, this message translates to:
  /// **'歌单里还没有歌曲'**
  String get playlistEmpty;

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'播放历史'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有播放记录'**
  String get historyEmpty;

  /// No description provided for @historyClear.
  ///
  /// In zh, this message translates to:
  /// **'清空历史'**
  String get historyClear;

  /// No description provided for @historyToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get historyYesterday;

  /// No description provided for @historyThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get historyThisWeek;

  /// No description provided for @historyEarlier.
  ///
  /// In zh, this message translates to:
  /// **'更早'**
  String get historyEarlier;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get settingsAccount;

  /// No description provided for @settingsNotLoggedIn.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get settingsNotLoggedIn;

  /// No description provided for @settingsPlayback.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get settingsPlayback;

  /// No description provided for @settingsQuality.
  ///
  /// In zh, this message translates to:
  /// **'默认音质'**
  String get settingsQuality;

  /// No description provided for @settingsQualityGuestHint.
  ///
  /// In zh, this message translates to:
  /// **'未登录时最高 132K'**
  String get settingsQualityGuestHint;

  /// No description provided for @settingsCache.
  ///
  /// In zh, this message translates to:
  /// **'缓存'**
  String get settingsCache;

  /// No description provided for @settingsCacheLimit.
  ///
  /// In zh, this message translates to:
  /// **'缓存上限'**
  String get settingsCacheLimit;

  /// No description provided for @settingsCacheUsage.
  ///
  /// In zh, this message translates to:
  /// **'已用 {used} / {limit}'**
  String settingsCacheUsage(String used, String limit);

  /// No description provided for @settingsCacheManage.
  ///
  /// In zh, this message translates to:
  /// **'管理缓存'**
  String get settingsCacheManage;

  /// No description provided for @settingsAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get settingsThemeMode;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @settingsSeedColor.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get settingsSeedColor;

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get settingsLicenses;

  /// No description provided for @cacheTitle.
  ///
  /// In zh, this message translates to:
  /// **'缓存管理'**
  String get cacheTitle;

  /// No description provided for @cacheSummary.
  ///
  /// In zh, this message translates to:
  /// **'已缓存 {count} 首，共 {size}'**
  String cacheSummary(int count, String size);

  /// No description provided for @cacheClearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空未收藏的缓存'**
  String get cacheClearAll;

  /// No description provided for @cacheClearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'将删除所有未加入歌单的缓存文件'**
  String get cacheClearConfirm;

  /// No description provided for @cacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清理 {count} 个文件'**
  String cacheCleared(int count);

  /// No description provided for @lyricsLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在匹配歌词…'**
  String get lyricsLoading;

  /// No description provided for @lyricsUncertain.
  ///
  /// In zh, this message translates to:
  /// **'找到可能的歌词，请确认'**
  String get lyricsUncertain;

  /// No description provided for @lyricsPick.
  ///
  /// In zh, this message translates to:
  /// **'选择歌词'**
  String get lyricsPick;

  /// No description provided for @lyricsNoLyrics.
  ///
  /// In zh, this message translates to:
  /// **'无歌词'**
  String get lyricsNoLyrics;

  /// No description provided for @lyricsMarkNone.
  ///
  /// In zh, this message translates to:
  /// **'标记为无歌词'**
  String get lyricsMarkNone;

  /// No description provided for @lyricsRematch.
  ///
  /// In zh, this message translates to:
  /// **'重新匹配'**
  String get lyricsRematch;

  /// No description provided for @lyricsOffset.
  ///
  /// In zh, this message translates to:
  /// **'歌词偏移'**
  String get lyricsOffset;

  /// No description provided for @lyricsOffsetValue.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String lyricsOffsetValue(String seconds);

  /// No description provided for @lyricsCandidate.
  ///
  /// In zh, this message translates to:
  /// **'{title} - {artist}（{score}%）'**
  String lyricsCandidate(String title, String artist, int score);

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'登录哔哩哔哩'**
  String get loginTitle;

  /// No description provided for @loginScan.
  ///
  /// In zh, this message translates to:
  /// **'使用哔哩哔哩 App 扫描二维码'**
  String get loginScan;

  /// No description provided for @loginWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待扫描…'**
  String get loginWaiting;

  /// No description provided for @loginScanned.
  ///
  /// In zh, this message translates to:
  /// **'已扫描，请在手机上确认'**
  String get loginScanned;

  /// No description provided for @loginExpired.
  ///
  /// In zh, this message translates to:
  /// **'二维码已过期'**
  String get loginExpired;

  /// No description provided for @loginRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get loginRetry;

  /// No description provided for @loginSuccess.
  ///
  /// In zh, this message translates to:
  /// **'登录成功'**
  String get loginSuccess;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定退出登录？'**
  String get logoutConfirm;

  /// No description provided for @loginPrompt.
  ///
  /// In zh, this message translates to:
  /// **'当前音质受限，登录后可使用更高音质'**
  String get loginPrompt;

  /// No description provided for @settingsCarLayout.
  ///
  /// In zh, this message translates to:
  /// **'车机布局'**
  String get settingsCarLayout;

  /// No description provided for @carLayoutAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get carLayoutAuto;

  /// No description provided for @carLayoutOn.
  ///
  /// In zh, this message translates to:
  /// **'始终开启'**
  String get carLayoutOn;

  /// No description provided for @carLayoutOff.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get carLayoutOff;

  /// No description provided for @carShowQueue.
  ///
  /// In zh, this message translates to:
  /// **'队列'**
  String get carShowQueue;

  /// No description provided for @carShowLyrics.
  ///
  /// In zh, this message translates to:
  /// **'歌词'**
  String get carShowLyrics;

  /// No description provided for @updateTitle.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get updateTitle;

  /// No description provided for @updateCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前 {version}'**
  String updateCurrent(String version);

  /// No description provided for @updateChecking.
  ///
  /// In zh, this message translates to:
  /// **'正在检查更新'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本'**
  String get updateUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'可更新到 {version}'**
  String updateAvailable(String version);

  /// No description provided for @updateAvailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'新版本 {version}'**
  String updateAvailableTitle(String version);

  /// No description provided for @updateUnsupportedTitle.
  ///
  /// In zh, this message translates to:
  /// **'没有适合这个系统的安装包'**
  String get updateUnsupportedTitle;

  /// No description provided for @updateUnsupportedShort.
  ///
  /// In zh, this message translates to:
  /// **'有新版本，但没有本机安装包'**
  String get updateUnsupportedShort;

  /// No description provided for @updateDownloading.
  ///
  /// In zh, this message translates to:
  /// **'正在下载 {percent}%'**
  String updateDownloading(int percent);

  /// No description provided for @updateLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后'**
  String get updateLater;

  /// No description provided for @updateDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载并安装'**
  String get updateDownload;

  /// No description provided for @updateInstallIos.
  ///
  /// In zh, this message translates to:
  /// **'通过描述文件安装'**
  String get updateInstallIos;

  /// No description provided for @updateLaunchedIos.
  ///
  /// In zh, this message translates to:
  /// **'已打开安装页。请按系统提示安装，然后到「设置 → 通用 → VPN 与设备管理」信任描述文件'**
  String get updateLaunchedIos;

  /// No description provided for @updateLaunched.
  ///
  /// In zh, this message translates to:
  /// **'已打开安装包，请按系统提示完成安装'**
  String get updateLaunched;

  /// No description provided for @updateCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败'**
  String get updateCheckFailed;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载或打开安装包失败'**
  String get updateDownloadFailed;

  /// No description provided for @updatePermission.
  ///
  /// In zh, this message translates to:
  /// **'请先允许本应用安装未知应用，然后重试'**
  String get updatePermission;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
