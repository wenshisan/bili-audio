import 'dart:io';

/// 是否打成 Microsoft Store 包。
///
/// 商店负责更新。构建时传入 `--dart-define=MICROSOFT_STORE=true`。
const bool kMicrosoftStore = bool.fromEnvironment('MICROSOFT_STORE');

/// 当前进程是否装在 MSIX 里。松散的 exe 为 false。
///
/// 商店安装和旁加载都会落在包身份下。漏传编译开关时，靠这个判断关掉应用内升级。
final bool isPackagedWindowsApp = _detectPackagedWindowsApp();

/// 显示给用户的产品名。商店和直接安装使用同一个名字。
///
/// 名称里不含 bili、bilibili、哔哩、B站。
const String productName = '音赴光年';

/// 当前安装包显示的产品名。
String productTitle() => productName;

/// 商店包不提供应用内下载安装程序。
///
/// [microsoftStore] 与 [packagedWindowsApp] 只给测试覆盖。不传时看编译开关和包身份。
bool offersInAppUpdate({bool? microsoftStore, bool? packagedWindowsApp}) {
  if (microsoftStore ?? kMicrosoftStore) return false;
  if (packagedWindowsApp ?? isPackagedWindowsApp) return false;
  return true;
}

bool _detectPackagedWindowsApp() {
  if (!Platform.isWindows) return false;
  return windowsExecutableIsPackaged(Platform.resolvedExecutable);
}

/// 商店和旁加载的进程都从 `WindowsApps` 启动。松散 exe 不在这个目录。
bool windowsExecutableIsPackaged(String executablePath) {
  final normalized = executablePath.replaceAll('\\', '/').toLowerCase();
  return normalized.contains('/windowsapps/');
}
