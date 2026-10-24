/// 升级读取的 GitHub 仓库，`owner/name`。
const String githubRepository = 'wenshisan/bili-audio';

/// Android 安装包在 Release 里的文件名。
const String androidInstaller = 'bili_audio-android.apk';

/// Windows 安装包在 Release 里的文件名。
const String windowsInstaller = 'bili_audio-windows-x64-setup.exe';

/// Apple 芯片 macOS 安装包在 Release 里的文件名。
const String macosArm64Installer = 'bili_audio-macos-arm64.dmg';

/// Intel macOS 安装包在 Release 里的文件名。
const String macosX64Installer = 'bili_audio-macos-x64.dmg';

/// Linux x64 安装包在 Release 里的文件名。
const String linuxAmd64Installer = 'bili_audio-linux-amd64.deb';

/// iOS 安装包在 Release 里的文件名。
const String iosInstaller = 'bili_audio-ios.ipa';

/// 介绍页上的 iOS 安装清单。用 Safari 打开后，系统按描述文件安装。
const String iosManifestUrl =
    'https://wenshisan.github.io/bili-audio/manifest.plist';

/// iOS 上交给系统安装描述文件的地址。
const String iosInstallUrl =
    'itms-services://?action=download-manifest&url=https%3A%2F%2Fwenshisan.github.io%2Fbili-audio%2Fmanifest.plist';

/// 按操作系统和 CPU 选择 Release 里的安装包文件名。
///
/// [operatingSystem] 使用 `Platform.operatingSystem` 的取值。
/// [architecture] 为 `x64` 或 `arm64`。没有对应安装包时返回 `null`。
String? installerAssetName({
  required String operatingSystem,
  required String architecture,
}) => switch (operatingSystem) {
  'android' => androidInstaller,
  'windows' when architecture == 'x64' => windowsInstaller,
  'macos' when architecture == 'arm64' => macosArm64Installer,
  'macos' when architecture == 'x64' => macosX64Installer,
  'linux' when architecture == 'x64' => linuxAmd64Installer,
  'ios' when architecture == 'arm64' => iosInstaller,
  _ => null,
};

/// 安装包打开方式。
enum InstallerKind {
  /// 调起 Android 安装界面。
  androidApk,

  /// 运行 Windows 安装程序。
  windowsSetup,

  /// 用系统“打开”命令挂载或打开磁盘映像。
  macosDisk,

  /// 交给桌面环境打开软件包。
  linuxPackage,

  /// 打开 iOS 描述文件安装地址，不在应用内下载 IPA。
  iosProfile,
}

/// 根据文件名判断怎么打开安装包。无法识别时返回 `null`。
InstallerKind? installerKind(String assetName) {
  if (assetName.endsWith('.apk')) return InstallerKind.androidApk;
  if (assetName.endsWith('.exe')) return InstallerKind.windowsSetup;
  if (assetName.endsWith('.dmg')) return InstallerKind.macosDisk;
  if (assetName.endsWith('.deb')) return InstallerKind.linuxPackage;
  if (assetName.endsWith('.ipa')) return InstallerKind.iosProfile;
  return null;
}
