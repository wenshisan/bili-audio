import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/update/app_release.dart';
import '../../data/update/app_version_source.dart';
import '../../data/update/host_platform.dart';
import '../../data/update/local_update_installer.dart';
import '../../data/update/release_source.dart';
import '../../domain/update/app_version.dart';
import '../../domain/update/installer_asset.dart';

/// 一次升级检查或安装所处的阶段。
enum UpdatePhase {
  /// 还没检查。
  idle,

  /// 正在请求 GitHub。
  checking,

  /// 没有更新的正式版。
  upToDate,

  /// 有更新，并且 Release 里有本机的安装包。
  available,

  /// 有更新，但没有本机可安装的附件。
  unsupported,

  /// 正在下载安装包。
  downloading,

  /// 已经交给系统打开安装包。
  launched,

  /// 检查或下载失败。
  failed,
}

/// 失败发生在哪一步。
enum UpdateFailure {
  /// 检查更新的请求失败。
  check,

  /// 下载或打开安装包失败。
  download,

  /// Android 尚未允许安装未知应用。
  permission,
}

/// 升级界面使用的状态。
class UpdateState {
  /// 创建状态。
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.current,
    this.release,
    this.asset,
    this.progress = 0,
    this.failure,
  });

  /// 当前阶段。
  final UpdatePhase phase;

  /// 本机版本。还没读到时为 `null`。
  final AppVersion? current;

  /// 远程正式版。没有正式版时为 `null`。
  final AppRelease? release;

  /// 准备下载的附件。
  final ReleaseAsset? asset;

  /// 下载进度，0 到 1。
  final double progress;

  /// 最近一次失败。没有失败时为 `null`。
  final UpdateFailure? failure;

  /// 复制并替换给出的字段。[failure] 传入 `null` 会清掉失败。
  UpdateState copyWith({
    UpdatePhase? phase,
    AppVersion? current,
    AppRelease? release,
    ReleaseAsset? asset,
    double? progress,
    Object? failure = _keepFailure,
  }) => UpdateState(
    phase: phase ?? this.phase,
    current: current ?? this.current,
    release: release ?? this.release,
    asset: asset ?? this.asset,
    progress: progress ?? this.progress,
    failure: identical(failure, _keepFailure)
        ? this.failure
        : failure as UpdateFailure?,
  );
}

const Object _keepFailure = Object();

/// 当前版本来源。正式启动时由 bootstrap 换成包信息。
final appVersionSourceProvider = Provider<AppVersionSource>(
  (ref) => FixedAppVersionSource(AppVersion.parse('0.1.0+1')!),
);

/// 升级源。正式启动时换成 GitHub Releases。
final releaseSourceProvider = Provider<ReleaseSource>(
  (ref) => const EmptyReleaseSource(),
);

/// 本机系统与 CPU。测试可覆盖，避免依赖运行测试的机器。
final updateHostProvider = Provider<UpdateHost>((ref) => currentUpdateHost());

/// 下载并打开安装包。
final updateInstallerProvider = Provider<UpdateInstaller>(
  (ref) => const NoopUpdateInstaller(),
);

/// 安装包打开后的退出动作。测试中保持为空操作。
final appQuitProvider = Provider<Future<void> Function()>((ref) => () async {});

/// 检查 GitHub 正式版，并在有安装包时下载打开。
class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  /// 向升级源查询是否有比本机新的正式版。
  Future<void> check() async {
    if (state.phase == UpdatePhase.downloading) return;
    state = UpdateState(phase: UpdatePhase.checking, current: state.current);
    try {
      final current = await ref.read(appVersionSourceProvider).current();
      final release = await ref.read(releaseSourceProvider).latestStable();
      if (release == null || !release.version.isNewerThan(current)) {
        state = UpdateState(phase: UpdatePhase.upToDate, current: current);
        return;
      }
      final host = ref.read(updateHostProvider);
      final name = installerAssetName(
        operatingSystem: host.operatingSystem,
        architecture: host.architecture,
      );
      final asset = name == null ? null : release.assetByName(name);
      state = UpdateState(
        phase: asset == null ? UpdatePhase.unsupported : UpdatePhase.available,
        current: current,
        release: release,
        asset: asset,
      );
    } catch (error, stack) {
      AppLogger.e(
        'update check failed',
        tag: 'update',
        error: error,
        stackTrace: stack,
      );
      state = UpdateState(
        phase: UpdatePhase.failed,
        failure: UpdateFailure.check,
        current: state.current,
      );
    }
  }

  /// 下载当前选中的安装包并打开，然后退出桌面端进程。
  Future<void> downloadAndInstall() async {
    final asset = state.asset;
    if (asset == null || state.phase == UpdatePhase.downloading) return;
    final current = state.current;
    final release = state.release;
    state = UpdateState(
      phase: UpdatePhase.downloading,
      current: current,
      release: release,
      asset: asset,
    );
    try {
      await ref
          .read(updateInstallerProvider)
          .install(
            asset,
            onProgress: (progress) {
              state = state.copyWith(progress: progress);
            },
          );
      state = UpdateState(
        phase: UpdatePhase.launched,
        current: current,
        release: release,
        asset: asset,
        progress: 1,
      );
      await ref.read(appQuitProvider)();
    } on InstallPermissionException {
      state = UpdateState(
        phase: UpdatePhase.available,
        current: current,
        release: release,
        asset: asset,
        failure: UpdateFailure.permission,
      );
    } catch (error, stack) {
      AppLogger.e(
        'update install failed',
        tag: 'update',
        error: error,
        stackTrace: stack,
      );
      state = UpdateState(
        phase: UpdatePhase.available,
        current: current,
        release: release,
        asset: asset,
        failure: UpdateFailure.download,
      );
    }
  }
}

/// 升级状态。
final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);
