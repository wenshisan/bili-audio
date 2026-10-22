import 'package:bili_audio/domain/update/installer_asset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('installerAssetName', () {
    test('已打包平台对上 Release 文件名', () {
      expect(
        installerAssetName(operatingSystem: 'android', architecture: 'arm64'),
        androidInstaller,
      );
      expect(
        installerAssetName(operatingSystem: 'windows', architecture: 'x64'),
        windowsInstaller,
      );
      expect(
        installerAssetName(operatingSystem: 'macos', architecture: 'arm64'),
        macosArm64Installer,
      );
      expect(
        installerAssetName(operatingSystem: 'linux', architecture: 'x64'),
        linuxAmd64Installer,
      );
      expect(
        installerAssetName(operatingSystem: 'ios', architecture: 'arm64'),
        iosInstaller,
      );
    });

    test('没有安装包的平台返回空', () {
      expect(
        installerAssetName(operatingSystem: 'macos', architecture: 'x64'),
        isNull,
      );
      expect(
        installerAssetName(operatingSystem: 'windows', architecture: 'arm64'),
        isNull,
      );
    });
  });

  test('按扩展名选择打开方式', () {
    expect(installerKind(androidInstaller), InstallerKind.androidApk);
    expect(installerKind(windowsInstaller), InstallerKind.windowsSetup);
    expect(installerKind(macosArm64Installer), InstallerKind.macosDisk);
    expect(installerKind(linuxAmd64Installer), InstallerKind.linuxPackage);
    expect(installerKind(iosInstaller), InstallerKind.iosProfile);
    expect(installerKind('notes.txt'), isNull);
  });
}
