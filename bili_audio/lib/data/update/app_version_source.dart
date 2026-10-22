import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/update/app_version.dart';

/// 读取当前安装的版本。
abstract class AppVersionSource {
  /// 当前版本。
  Future<AppVersion> current();
}

/// 固定版本。测试，以及还没注入真实来源时使用。
class FixedAppVersionSource implements AppVersionSource {
  /// 始终返回 [version]。
  const FixedAppVersionSource(this.version);

  /// 固定返回的版本。
  final AppVersion version;

  @override
  Future<AppVersion> current() async => version;
}

/// 从平台包信息读取 pubspec 写入的版本。
class PackageAppVersionSource implements AppVersionSource {
  /// 创建来源。
  const PackageAppVersionSource();

  @override
  Future<AppVersion> current() async {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber.trim();
    final raw = build.isEmpty ? info.version : '${info.version}+$build';
    return AppVersion.parse(raw) ?? (throw StateError('无法解析应用版本 "$raw"'));
  }
}
