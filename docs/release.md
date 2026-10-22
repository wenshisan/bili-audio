# 发布与在线升级

安装包由 GitHub Actions 构建，挂到 GitHub Release 上。介绍页和软件里的“检查更新”都读这个 Release。

仓库：`wenshisan/flutter-app-deep`。Release 附件名写在 `bili_audio/lib/domain/update/installer_asset.dart`，改名时 Action、介绍页和这段文档要一起改。仓库需要公开，否则介绍页和未登录的 GitHub API 都下不到文件。

## 安装包

| 平台 | 文件 | 说明 |
| --- | --- | --- |
| Android | `bili_audio-android.apk` | 通用 APK。签名密钥放在 Actions secrets，不进仓库，这样每次构建都能覆盖安装 |
| Windows x64 | `bili_audio-windows-x64-setup.exe` | Inno Setup 安装程序，装到当前用户目录。未做代码签名 |
| Linux x64 | `bili_audio-linux-amd64.deb` | 安装到 `/opt/bili_audio` |
| macOS Apple 芯片 | `bili_audio-macos-arm64.dmg` | 未公证。Intel Mac 暂不打包 |
| iOS | 无 | 没有 Apple 开发者证书，打不出可安装的 IPA |

Windows 若被 SmartScreen 拦住，选择仍要运行。macOS 在“系统设置 → 隐私与安全性”里允许打开。Android 需允许本应用安装未知应用。

Android 签名用四个 Actions secrets：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_PASSWORD`、`ANDROID_KEY_ALIAS`。没配时 APK 用 debug 签名，换一台构建机后就不能覆盖安装。本地要打同一把签名时，把 keystore 放到 `bili_audio/android/app/ci-release.keystore`（已被 gitignore），并写 `bili_audio/android/key.properties`：

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=ci-release.keystore
```

## Actions

- `.github/workflows/release.yml`：推送到 `main` 且改动了 `bili_audio/` 或该 workflow 时，构建上表四个包，并更新预发布标签 `continuous`。
- `.github/workflows/release-tag.yml`：推送 `v*` 标签（例如 `v0.2.0`）时走同一套构建，发布为正式版，并标成 Latest。
- 也可以在 Actions 页手动运行 Build installers。

`continuous` 是预发布，不会成为 GitHub 的 Latest。正式版才会。

## 介绍页

`.github/workflows/pages.yml` 把 `site/index.html` 部署到 GitHub Pages：

`https://wenshisan.github.io/flutter-app-deep/`

页面先请求 Latest 正式版；没有正式版，或正式版里没有安装包时，改用 `continuous`。按钮在第一次构建完成前会 404。

## 应用内升级

设置里有“检查更新”。进入主界面时也会查一次；车机布局下不弹窗。

数据来自：

`GET https://api.github.com/repos/wenshisan/flutter-app-deep/releases/latest`

只认非预发布，所以 `continuous` 不会提示升级。标签必须是 `v1.2.3` 或 `1.2.3`。比较规则：

- 先比主版本、次版本、修订号。
- 本地和远程都带 `+构建号` 时，再比构建号。
- 只有一边有构建号时，忽略构建号。因此本地 `0.1.0+1` 和标签 `v0.1.0` 视为同一版。

有更新且 Release 里有本机文件时，下载到临时目录再打开：

- Android：调起系统安装界面。若还不能安装未知应用，会先打开系统授权页。
- Windows：运行下载的安装程序。
- macOS：`open` 磁盘映像。
- Linux：`xdg-open` 打开 deb。
- iOS、Intel Mac、Windows ARM 没有对应附件，只说明有新版本并给出发布页地址。

发一个用户能在软件里看到的升级：

1. 提高 `bili_audio/pubspec.yaml` 的 `version`。
2. 提交并推送到 `main`。
3. 打标签并推送，例如 `git tag v0.2.0 && git push origin v0.2.0`。

标签名要和 pubspec 的 `major.minor.patch` 一致，并带前缀 `v`。
