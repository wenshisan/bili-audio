import 'package:bili_audio/data/update/app_release.dart';
import 'package:bili_audio/data/update/app_version_source.dart';
import 'package:bili_audio/data/update/host_platform.dart';
import 'package:bili_audio/data/update/local_update_installer.dart';
import 'package:bili_audio/data/update/release_source.dart';
import 'package:bili_audio/domain/update/app_version.dart';
import 'package:bili_audio/domain/update/installer_asset.dart';
import 'package:bili_audio/features/settings/update_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppRelease _release(String tag, {List<ReleaseAsset>? assets}) {
  final version = AppVersion.parse(tag)!;
  return AppRelease(
    version: version,
    tag: tag,
    notes: '说明',
    pageUrl: 'https://example.test/$tag',
    assets:
        assets ??
        const [
          ReleaseAsset(
            name: androidInstaller,
            downloadUrl: 'https://example.test/$androidInstaller',
            size: 4,
          ),
        ],
  );
}

class _Source implements ReleaseSource {
  _Source(this.release, {this.error});

  final AppRelease? release;
  final Object? error;

  @override
  Future<AppRelease?> latestStable() async {
    final failure = error;
    if (failure != null) throw failure;
    return release;
  }
}

class _Installer implements UpdateInstaller {
  var calls = 0;
  Object? error;

  @override
  Future<void> install(
    ReleaseAsset asset, {
    required void Function(double progress) onProgress,
  }) async {
    calls++;
    onProgress(1);
    final failure = error;
    if (failure != null) throw failure;
  }
}

ProviderContainer _container({
  required ReleaseSource source,
  UpdateInstaller? installer,
}) {
  return ProviderContainer(
    overrides: [
      appVersionSourceProvider.overrideWithValue(
        FixedAppVersionSource(AppVersion.parse('0.1.0+1')!),
      ),
      releaseSourceProvider.overrideWithValue(source),
      updateHostProvider.overrideWithValue(
        const UpdateHost(operatingSystem: 'android', architecture: 'arm64'),
      ),
      if (installer != null)
        updateInstallerProvider.overrideWithValue(installer),
    ],
  );
}

void main() {
  test('没有更新的正式版', () async {
    final container = _container(source: _Source(_release('v0.1.0')));
    addTearDown(container.dispose);

    await container.read(updateControllerProvider.notifier).check();

    expect(
      container.read(updateControllerProvider).phase,
      UpdatePhase.upToDate,
    );
  });

  test('有本机安装包时可以下载', () async {
    final installer = _Installer();
    final container = _container(
      source: _Source(_release('v0.2.0')),
      installer: installer,
    );
    addTearDown(container.dispose);
    final controller = container.read(updateControllerProvider.notifier);

    await controller.check();
    expect(
      container.read(updateControllerProvider).phase,
      UpdatePhase.available,
    );

    await controller.downloadAndInstall();

    expect(installer.calls, 1);
    expect(
      container.read(updateControllerProvider).phase,
      UpdatePhase.launched,
    );
  });

  test('新版本没有本机安装包', () async {
    final container = _container(
      source: _Source(_release('v0.2.0', assets: const [])),
    );
    addTearDown(container.dispose);

    await container.read(updateControllerProvider.notifier).check();

    expect(
      container.read(updateControllerProvider).phase,
      UpdatePhase.unsupported,
    );
  });

  test('检查失败和安装权限失败', () async {
    final denied = _Installer()..error = const InstallPermissionException();
    final container = _container(
      source: _Source(_release('v0.2.0')),
      installer: denied,
    );
    addTearDown(container.dispose);
    final controller = container.read(updateControllerProvider.notifier);
    await controller.check();
    await controller.downloadAndInstall();
    expect(
      container.read(updateControllerProvider).failure,
      UpdateFailure.permission,
    );

    final broken = _container(source: _Source(null, error: StateError('down')));
    addTearDown(broken.dispose);
    await broken.read(updateControllerProvider.notifier).check();
    expect(broken.read(updateControllerProvider).phase, UpdatePhase.failed);
    expect(broken.read(updateControllerProvider).failure, UpdateFailure.check);
  });
}
