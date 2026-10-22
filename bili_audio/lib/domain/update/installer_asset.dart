/// 升级读取的 GitHub 仓库，`owner/name`。
const String githubRepository = 'wenshisan/flutter-app-deep';

/// Android 安装包在 Release 里的文件名。
const String androidInstaller = 'bili_audio-android.apk';

/// Windows 安装包在 Release 里的文件名。
const String windowsInstaller = 'bili_audio-windows-x64-setup.exe';

/// Apple 芯片 macOS 安装包在 Release 里的文件名。
const String macosArm64Installer = 'bili_audio-macos-arm64.dmg';

/// Linux x64 安装包在 Release 里的文件名。
const String linuxAmd64Installer = 'bili_audio-linux-amd64.deb';

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
  'linux' when architecture == 'x64' => linuxAmd64Installer,
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
}

/// 根据文件名判断怎么打开安装包。无法识别时返回 `null`。
InstallerKind? installerKind(String assetName) {
  if (assetName.endsWith('.apk')) return InstallerKind.androidApk;
  if (assetName.endsWith('.exe')) return InstallerKind.windowsSetup;
  if (assetName.endsWith('.dmg')) return InstallerKind.macosDisk;
  if (assetName.endsWith('.deb')) return InstallerKind.linuxPackage;
  return null;
}
