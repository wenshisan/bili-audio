/// 是否打成 Microsoft Store 包。
///
/// 商店负责更新。构建时传入 `--dart-define=MICROSOFT_STORE=true`。
const bool kMicrosoftStore = bool.fromEnvironment('MICROSOFT_STORE');

/// 显示给用户的产品名。商店和直接安装使用同一个名字。
///
/// 名称里不含 bili、bilibili、哔哩、B站。
const String productName = '音赴光年';

/// 当前安装包显示的产品名。
String productTitle() => productName;

/// 商店包不提供应用内下载安装程序。
bool offersInAppUpdate({bool microsoftStore = kMicrosoftStore}) =>
    !microsoftStore;
