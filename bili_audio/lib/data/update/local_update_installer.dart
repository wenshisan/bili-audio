import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/update/installer_asset.dart';
import 'app_release.dart';

/// 把安装包下载到本机并打开。
abstract class UpdateInstaller {
  /// 下载 [asset] 并交给系统安装。
  ///
  /// [onProgress] 收到 0 到 1 的进度。总大小未知时不调用。
  Future<void> install(
    ReleaseAsset asset, {
    required void Function(double progress) onProgress,
  });
}

/// 不下载。测试默认实现。
class NoopUpdateInstaller implements UpdateInstaller {
  /// 创建空安装器。
  const NoopUpdateInstaller();

  @override
  Future<void> install(
    ReleaseAsset asset, {
    required void Function(double progress) onProgress,
  }) async {}
}

/// 系统没有允许本应用安装未知来源的 APK。
class InstallPermissionException implements Exception {
  /// 创建权限异常。
  const InstallPermissionException();
}

/// 下载或打开安装包失败。
class InstallLaunchException implements Exception {
  /// 用原因创建异常。
  const InstallLaunchException(this.message);

  /// 失败原因。
  final String message;

  @override
  String toString() => message;
}

const MethodChannel _installChannel = MethodChannel('bili_audio/install');

/// 下载 Release 附件到临时目录，再按扩展名打开。
///
/// macOS 由沙盒里的本应用下载磁盘映像时，系统会写上
/// `com.apple.quarantine`，并把来源标成 App Sandbox。拖进「应用程序」的
/// 副本因此被拒绝启动。安装时改在沙盒外替换正在运行的应用包，并去掉隔离标记。
class LocalUpdateInstaller implements UpdateInstaller {
  /// 创建安装器。[dio] 为空时使用带 BiliAudio User-Agent 的客户端。
  ///
  /// [runMacShell] 和 [macExecutable] 只给测试替换本机命令和当前应用路径。
  LocalUpdateInstaller({
    Dio? dio,
    this.installApk = _installApk,
    this.runMacShell,
    this.macExecutable,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(minutes: 10),
               headers: const {'User-Agent': 'BiliAudio'},
             ),
           );

  final Dio _dio;

  /// 打开已经落盘的 APK。测试可以换成不走平台通道的实现。
  final Future<void> Function(String path) installApk;

  /// 在沙盒外执行 bash。[administrator] 为真时会弹出系统密码框。
  final Future<ProcessResult> Function(
    String bash, {
    required bool administrator,
  })?
  runMacShell;

  /// 当前可执行文件。为空时用 [Platform.resolvedExecutable]。
  final String? macExecutable;

  @override
  Future<void> install(
    ReleaseAsset asset, {
    required void Function(double progress) onProgress,
  }) async {
    final kind = installerKind(asset.name);
    if (kind == null) {
      throw const InstallLaunchException('无法识别安装包');
    }
    if (kind == InstallerKind.iosProfile) {
      onProgress(1);
      await _openUrl(iosInstallUrl);
      return;
    }
    final root = await getTemporaryDirectory();
    final file = File(p.join(root.path, 'updates', asset.name));
    await file.parent.create(recursive: true);
    if (file.existsSync()) await file.delete();
    try {
      await _dio.download(
        asset.downloadUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );
    } catch (_) {
      if (file.existsSync()) await file.delete();
      throw const InstallLaunchException('下载失败');
    }
    await _open(kind, file.path);
  }

  Future<void> _open(InstallerKind kind, String path) async {
    switch (kind) {
      case InstallerKind.androidApk:
        await installApk(path);
      case InstallerKind.windowsSetup:
        await Process.start(path, const [], mode: ProcessStartMode.detached);
      case InstallerKind.macosDisk:
        await installDownloadedMacDisk(
          path,
          executable: macExecutable,
          runShell: runMacShell,
        );
      case InstallerKind.linuxPackage:
        await _openAndWait('xdg-open', [path]);
      case InstallerKind.iosProfile:
        await _openUrl(iosInstallUrl);
    }
  }
}

Future<void> _openAndWait(String executable, List<String> args) async {
  final opened = await Process.run(executable, args);
  if (opened.exitCode == 0) return;
  final err = '${opened.stderr}'.trim();
  throw InstallLaunchException(err.isEmpty ? '无法打开安装包' : err);
}

/// 去掉沙盒下载写上的 `com.apple.quarantine`。
///
/// 属性不存在时直接返回。沙盒内的进程往往清不掉这个标记，调用方不能把它当成
/// 安装已经成功。
Future<void> clearMacDownloadQuarantine(String path) async {
  if (!Platform.isMacOS) return;
  final result = await Process.run('/usr/bin/xattr', [
    '-d',
    'com.apple.quarantine',
    path,
  ]);
  if (result.exitCode == 0) return;
  final err = '${result.stderr}';
  if (err.contains('No such xattr')) return;
}

/// 由可执行文件路径得到 `.app` 包。不在标准包结构里时返回 `null`。
String? macRunningAppBundle([String? executable]) {
  final exe = executable ?? Platform.resolvedExecutable;
  final macosDir = p.dirname(exe);
  final contents = p.dirname(macosDir);
  final bundle = p.dirname(contents);
  if (p.basename(macosDir) != 'MacOS') return null;
  if (p.basename(contents) != 'Contents') return null;
  if (!p.basename(bundle).endsWith('.app')) return null;
  return bundle;
}

/// 这次更新要替换的应用包。
///
/// 从系统转存目录启动时，那个路径只读，改写到「应用程序」。
String macUpdateDestination({
  String? executable,
  String applicationsDir = '/Applications',
}) {
  final bundle = macRunningAppBundle(executable);
  final translocation = '${p.separator}AppTranslocation${p.separator}';
  if (bundle == null || bundle.contains(translocation)) {
    return p.join(applicationsDir, 'bili_audio.app');
  }
  return bundle;
}

/// 挂载磁盘映像、替换 [destination]，并在沙盒外去掉隔离标记。
///
/// 成功后等当前进程退出，再重新打开应用。隔离标记清不掉时以退出码 2 结束，
/// 且不会先动已经装好的应用。
String macReplaceAppScript({
  required String dmgPath,
  required String destination,
}) {
  final dmg = _bashQuote(dmgPath);
  final dest = _bashQuote(destination);
  return '''
set -eu
dmg=$dmg
dest=$dest
parent=\$(dirname "\$dest")
base=\$(basename "\$dest")
mount=\$(mktemp -d)
stage="\$parent/.\$base.update.\$\$"
cleanup() {
  if [[ -n "\${mount:-}" ]]; then
    hdiutil detach "\$mount" -force >/dev/null 2>&1 || true
    rmdir "\$mount" 2>/dev/null || true
  fi
  if [[ -n "\${stage:-}" && -d "\$stage" ]]; then
    rm -rf "\$stage"
  fi
}
trap cleanup EXIT
xattr -dr com.apple.quarantine "\$dmg" 2>/dev/null || true
xattr -dr com.apple.provenance "\$dmg" 2>/dev/null || true
hdiutil attach "\$dmg" -mountpoint "\$mount" -nobrowse -readonly -quiet
src="\$mount/bili_audio.app"
if [[ ! -d "\$src" ]]; then
  echo "磁盘映像里没有 bili_audio.app" >&2
  exit 1
fi
rm -rf "\$stage"
ditto "\$src" "\$stage"
xattr -dr com.apple.quarantine "\$stage" 2>/dev/null || true
xattr -dr com.apple.provenance "\$stage" 2>/dev/null || true
if xattr -pr com.apple.quarantine "\$stage" 2>/dev/null | grep -q .; then
  echo "隔离标记无法清除" >&2
  exit 2
fi
backup="\$parent/.\$base.previous.\$\$"
if [[ -e "\$dest" ]]; then
  rm -rf "\$backup"
  mv "\$dest" "\$backup"
fi
if ! mv "\$stage" "\$dest"; then
  if [[ -e "\$backup" ]]; then
    mv "\$backup" "\$dest" || true
  fi
  echo "无法替换应用" >&2
  exit 1
fi
if [[ "\$(id -u)" -eq 0 ]]; then
  owner=\$(stat -f '%Su' /dev/console)
  chown -R "\$owner:staff" "\$dest"
  uid=\$(stat -f '%u' /dev/console)
  nohup launchctl asuser "\$uid" /bin/sh -c 'sleep 2; /usr/bin/open "\$1"' _ "\$dest" >/dev/null 2>&1 &
else
  nohup /bin/sh -c 'sleep 2; /usr/bin/open "\$1"' _ "\$dest" >/dev/null 2>&1 &
fi
''';
}

/// 用沙盒外的 shell 安装已经落盘的 macOS 磁盘映像。
///
/// 沙盒里直接执行时会失败或清不掉隔离标记，这时改用管理员权限再试一次。
/// 用户取消密码框时抛出 [InstallLaunchException]。
Future<void> installDownloadedMacDisk(
  String dmgPath, {
  String? executable,
  Future<ProcessResult> Function(String bash, {required bool administrator})?
  runShell,
}) async {
  final destination = macUpdateDestination(executable: executable);
  final bash = macReplaceAppScript(dmgPath: dmgPath, destination: destination);
  final runner = runShell ?? _runOutsideAppSandbox;
  var result = await runner(bash, administrator: false);
  if (result.exitCode != 0 && _macShellNeedsAdministrator(result)) {
    AppLogger.w(
      'mac update outside sandbox failed, retrying with administrator: ${result.stderr}',
      tag: 'update',
    );
    result = await runner(bash, administrator: true);
  }
  if (result.exitCode != 0) {
    throw InstallLaunchException(_macInstallFailureMessage(result));
  }
}

/// 删掉更新时留在应用旁边的旧副本。
///
/// 旧进程还占着这些文件时删除会失败，下次启动再试。
/// [executable] 为空且当前不是 macOS 时直接返回。
Future<void> deletePreviousMacAppBundles({String? executable}) async {
  if (executable == null && !Platform.isMacOS) return;
  final bundle = macRunningAppBundle(executable);
  if (bundle == null) return;
  final parent = Directory(p.dirname(bundle));
  if (!parent.existsSync()) return;
  await for (final entity in parent.list()) {
    final name = p.basename(entity.path);
    if (!name.startsWith('.bili_audio.app.previous.')) continue;
    try {
      await entity.delete(recursive: true);
    } catch (_) {}
  }
}

String _bashQuote(String value) => "'${value.replaceAll("'", r"'\''")}'";

bool _macShellNeedsAdministrator(ProcessResult result) {
  if (result.exitCode == 0) return false;
  final err = '${result.stderr}';
  if (err.contains('磁盘映像里没有')) return false;
  if (err.contains('User canceled') ||
      err.contains('用户取消') ||
      err.contains('-128')) {
    return false;
  }
  return true;
}

String _macInstallFailureMessage(ProcessResult result) {
  final err = '${result.stderr}'.trim();
  if (err.contains('User canceled') ||
      err.contains('用户取消') ||
      err.contains('-128')) {
    return '已取消安装';
  }
  if (err.isEmpty) return '无法安装更新';
  return err;
}

Future<ProcessResult> _runOutsideAppSandbox(
  String bash, {
  required bool administrator,
}) async {
  final privilege = administrator ? ' with administrator privileges' : '';
  final source =
      '''
on run argv
  do shell script "bash -c " & quoted form of (item 1 of argv)$privilege
end run
''';
  final process = await Process.start('/usr/bin/osascript', ['-', bash]);
  process.stdin.write(source);
  await process.stdin.close();
  final stdout = await process.stdout.transform(utf8.decoder).join();
  final stderr = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;
  return ProcessResult(process.pid, exitCode, stdout, stderr);
}

Future<void> _openUrl(String url) async {
  try {
    await _installChannel.invokeMethod<void>('openUrl', url);
  } on PlatformException catch (error) {
    throw InstallLaunchException(error.message ?? error.code);
  }
}

Future<void> _installApk(String path) async {
  try {
    await _installChannel.invokeMethod<void>('installApk', {'path': path});
  } on PlatformException catch (error) {
    if (error.code == 'permission') throw const InstallPermissionException();
    throw InstallLaunchException(error.message ?? error.code);
  }
}
