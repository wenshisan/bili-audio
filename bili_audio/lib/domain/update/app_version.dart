/// 应用版本号，对应 pubspec 的 `major.minor.patch` 和可选的 `+build`。
///
/// 远程标签可以写成 `v1.2.3` 或 `1.2.3`。两边都带构建号时才比较构建号；
/// 只有一边有构建号时，只比较主版本、次版本和修订号。
class AppVersion implements Comparable<AppVersion> {
  /// 用已经拆开的数字创建版本。
  const AppVersion(
    this.major,
    this.minor,
    this.patch, {
    this.build = 0,
    this.hasBuild = false,
  });

  /// 主版本号。
  final int major;

  /// 次版本号。
  final int minor;

  /// 修订号。
  final int patch;

  /// 构建号。仅当 [hasBuild] 为 true 时参与比较。
  final int build;

  /// 是否带有 `+build`。
  final bool hasBuild;

  static final RegExp _pattern = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$');

  /// 解析 `v1.2.3`、`1.2.3` 或 `1.2.3+4`。格式不对时返回 `null`。
  static AppVersion? parse(String raw) {
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    final buildText = match.group(4);
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      build: buildText == null ? 0 : int.parse(buildText),
      hasBuild: buildText != null,
    );
  }

  /// 是否比 [other] 新。
  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  /// `1.2.3` 或 `1.2.3+4`。
  String get text =>
      hasBuild ? '$major.$minor.$patch+$build' : '$major.$minor.$patch';

  @override
  int compareTo(AppVersion other) {
    final majorDelta = major.compareTo(other.major);
    if (majorDelta != 0) return majorDelta;
    final minorDelta = minor.compareTo(other.minor);
    if (minorDelta != 0) return minorDelta;
    final patchDelta = patch.compareTo(other.patch);
    if (patchDelta != 0) return patchDelta;
    if (hasBuild && other.hasBuild) return build.compareTo(other.build);
    return 0;
  }

  @override
  String toString() => text;
}
