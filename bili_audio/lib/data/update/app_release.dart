import '../../domain/update/app_version.dart';

/// GitHub Release 里的一个附件。
class ReleaseAsset {
  /// 用文件名和浏览器下载地址创建附件。
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  /// 文件名，与 Actions 上传的安装包一致。
  final String name;

  /// 公开仓库可直接下载的地址。
  final String downloadUrl;

  /// 字节数。接口没给时为 0。
  final int size;
}

/// 一次可用于升级的正式 Release。
class AppRelease {
  /// 用已经解析的字段创建 Release。
  const AppRelease({
    required this.version,
    required this.tag,
    required this.notes,
    required this.pageUrl,
    required this.assets,
  });

  /// 从标签解析出的版本。
  final AppVersion version;

  /// 标签原文，例如 `v0.2.0`。
  final String tag;

  /// 发布说明。仓库里没写时为空字符串。
  final String notes;

  /// 浏览器里的 Release 页面。
  final String pageUrl;

  /// 该次发布附带的文件。
  final List<ReleaseAsset> assets;

  /// 按文件名查找附件。
  ReleaseAsset? assetByName(String name) {
    for (final asset in assets) {
      if (asset.name == name) return asset;
    }
    return null;
  }

  /// 解析 GitHub Release JSON。
  ///
  /// 草稿、预发布，或标签和标题都不是版本号时返回 `null`。
  /// 标题和标签的主版本、次版本、修订号相同时，采用构建号更大的那一个。
  /// 因此标签 `v0.2.0`、标题 `v0.2.0+6` 的版本是 `0.2.0+6`。
  static AppRelease? fromGithubJson(Map<String, dynamic> json) {
    if (json['draft'] == true || json['prerelease'] == true) return null;
    final tag = json['tag_name'];
    if (tag is! String) return null;
    final name = json['name'];
    final version = _versionOf(tag, name is String ? name : null);
    if (version == null) return null;
    final notes = json['body'];
    final page = json['html_url'];
    return AppRelease(
      version: version,
      tag: tag,
      notes: notes is String ? notes.trim() : '',
      pageUrl: page is String ? page : '',
      assets: _assets(json['assets']),
    );
  }

  static AppVersion? _versionOf(String tag, String? name) {
    final fromTag = AppVersion.parse(tag);
    final fromName = name == null ? null : AppVersion.parse(name);
    if (fromTag == null) return fromName;
    if (fromName == null) return fromTag;
    final sameLine =
        fromName.major == fromTag.major &&
        fromName.minor == fromTag.minor &&
        fromName.patch == fromTag.patch;
    if (sameLine &&
        fromName.hasBuild &&
        (!fromTag.hasBuild || fromName.build > fromTag.build)) {
      return fromName;
    }
    return fromTag;
  }

  static List<ReleaseAsset> _assets(Object? raw) {
    if (raw is! List) return const [];
    final assets = <ReleaseAsset>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final name = item['name'];
      final url = item['browser_download_url'];
      if (name is! String || url is! String) continue;
      final size = item['size'];
      assets.add(
        ReleaseAsset(
          name: name,
          downloadUrl: url,
          size: size is int ? size : 0,
        ),
      );
    }
    return assets;
  }
}
