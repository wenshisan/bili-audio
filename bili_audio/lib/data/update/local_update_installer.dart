import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
class LocalUpdateInstaller implements UpdateInstaller {
  /// 创建安装器。[dio] 为空时使用带 BiliAudio User-Agent 的客户端。
  LocalUpdateInstaller({Dio? dio, this.installApk = _installApk})
    : _dio =
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

  @override
  Future<void> install(
    ReleaseAsset asset, {
    required void Function(double progress) onProgress,
  }) async {
    final kind = installerKind(asset.name);
    if (kind == null) {
      throw const InstallLaunchException('无法识别安装包');
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
        await Process.start('open', [path], mode: ProcessStartMode.detached);
      case InstallerKind.linuxPackage:
        await Process.start('xdg-open', [
          path,
        ], mode: ProcessStartMode.detached);
    }
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
