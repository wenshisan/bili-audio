# 发布与在线升级

安装包由 GitHub Actions 构建，挂到 GitHub Release 上。介绍页和软件里的“检查更新”都读这个 Release。

安装后显示的名称是「音赴光年」。仓库仍是 `wenshisan/bili-audio`，安装包文件名仍以 `bili_audio` 开头，写在 `bili_audio/lib/domain/update/installer_asset.dart`。改这些文件名时，Action、介绍页和这段文档要一起改。仓库需要公开，否则介绍页和未登录的 GitHub API 都下不到文件。

## 安装包

| 平台 | 文件 | 说明 |
| --- | --- | --- |
| Android | `bili_audio-android.apk` | 通用 APK。签名密钥放在 Actions secrets，不进仓库，这样每次构建都能覆盖安装 |
| Windows x64 | `bili_audio-windows-x64-setup.exe` | Inno Setup 安装程序，装到当前用户目录。未做代码签名 |
| Windows 商店 | `bili_audio-windows-x64-store.msix` | 只在 Partner Center 身份齐全时产出。上传到 Microsoft Store，不能双击安装。这个包由商店更新，里面没有“检查更新” |
| Linux x64 | `bili_audio-linux-amd64.deb` | 安装到 `/opt/bili_audio` |
| macOS Apple 芯片 | `bili_audio-macos-arm64.dmg` | 未公证 |
| macOS Intel | `bili_audio-macos-x64.dmg` | 未公证。在 Apple Silicon runner 上交叉编译 x86_64（Intel runner 上 Flutter pub get 会卡住） |
| iOS | `bili_audio-ios.ipa` | 用 Safari 打开介绍页，走 `itms-services` 描述文件安装。签名 secrets 没配时不产出这个文件 |

Windows 若被 SmartScreen 拦住，选择仍要运行。macOS 在“系统设置 → 隐私与安全性”里允许打开。Android 需允许本应用安装未知应用。

## Microsoft Store

商店只收 MSIX。第一次上架要在 [Partner Center](https://partner.microsoft.com/dashboard) 里手动提交；这台构建机没有商店账号，不能代为送审。

1. 用开发者账号新建应用，类型选 MSIX，保留名称 `音赴光年`。不要保留 `bili-audio`、`哔哩` 或 `B站`。名称里出现这些字样，审核会把它当成对方的应用；写“第三方”或“与官方无关”也不能抵消。名称三个月不用会被收回。
2. 打开该应用的 Product management → Product identity，抄下三项，设成仓库 Actions secrets：`MSSTORE_IDENTITY_NAME`（Package/Identity/Name）、`MSSTORE_PUBLISHER`（以 `CN=` 开头）、`MSSTORE_PUBLISHER_DISPLAY_NAME`。三项都要和页面上的大小写一致。
3. 推送到 `main` 后，Windows 任务会额外打出 `bili_audio-windows-x64-store.msix`。三个 secrets 都没配时跳过，安装程序照旧发布。只配了一部分时，Windows 任务失败。
4. 在 Partner Center 新建提交，把这个 msix 传到 Packages。商店会重新签名，所以这个文件不能在本机双击安装。
5. 同一份提交里还要填：免费或定价、市场、年龄分级、至少一张截图、隐私政策网址。应用会联网并保存登录凭据，没有隐私政策地址过不了审核。商店列表的名称用 `音赴光年`。简短说明：「音赴光年。在电脑上听音频。可以搜索、看歌词、做本地歌单、随机播放，听过的曲目会留在本机。」详细说明先写播放、歌词、歌单、随机和离线缓存，最后再写一句：登录使用的是用户自己的哔哩哔哩账号，凭据只在本机；音赴光年由个人独立开发并发布，与哔哩哔哩没有合作、赞助或授权关系。不要把产品写成「哔哩哔哩播放器」或「第三方客户端」。
6. Submission options 会问为什么需要 `runFullTrust`。这是 Win32 桌面程序，窗口、托盘、系统媒体控制和本机凭据存储都要完整信任。

商店包用 `--dart-define=MICROSOFT_STORE=true` 编译，设置里不再检查 GitHub 更新，升级走商店。直接下载的 exe 不受影响。版本第四位用构建号：`0.1.0+2` 的商店版本是 `0.1.0.2`，每次提交都要比上一包大。

本地在配好那三个环境变量后，于 `bili_audio` 目录执行 `powershell -File packaging/windows/build-msix.ps1`。

Android 签名用四个 Actions secrets：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_PASSWORD`、`ANDROID_KEY_ALIAS`。没配时 APK 用 debug 签名，换一台构建机后就不能覆盖安装。本地要打同一把签名时，把 keystore 放到 `bili_audio/android/app/ci-release.keystore`（已被 gitignore），并写 `bili_audio/android/key.properties`：

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=ci-release.keystore
```

iOS 描述文件安装用三个 Actions secrets：`IOS_CERTIFICATE_P12_BASE64`（分发证书 p12 的 base64）、`IOS_CERTIFICATE_PASSWORD`、`IOS_PROVISIONING_PROFILE_BASE64`（`.mobileprovision` 的 base64）。可选 `IOS_EXPORT_METHOD`，默认 `ad-hoc`。描述文件里要包含要安装的设备。企业签名则把导出方式设为 `enterprise`。

介绍页上的 iOS 按钮打开 `https://wenshisan.github.io/bili-audio/manifest.plist`。装完后到「设置 → 通用 → VPN 与设备管理」信任该描述文件。应用内升级在 iPhone 上打开同一条安装地址，不在应用里下载 IPA。

## Actions

- `.github/workflows/release.yml`：推送到 `main` 且改动了 `bili_audio/` 或该 workflow 时构建上表的安装包。构建号比 pubspec 和已发布 Release 里出现过的都大 1，并发布非预发布标签 `vX.Y.Z+N`（`X.Y.Z` 来自 pubspec）。同时把同一批文件更新到预发布标签 `continuous`。iOS 只在签名 secrets 齐全时产出 IPA。
- `.github/workflows/release-tag.yml`：推送不带构建号的 `v*` 标签（例如 `v0.2.0`）时走同一套构建。版本名用标签，构建号同样加 1，Release 标题写成 `v0.2.0+N`。带 `+` 的标签是构建自己打的，不会再触发一次构建。
- 也可以在 Actions 页手动运行 Build installers。每次运行都会再加一。

`continuous` 是预发布，不会成为 GitHub 的 Latest。`vX.Y.Z+N` 才会。

## 介绍页

`.github/workflows/pages.yml` 把 `site/index.html` 部署到 GitHub Pages：

`https://wenshisan.github.io/bili-audio/`

页面先请求 Latest 正式版；没有正式版，或正式版里没有安装包时，改用 `continuous`。按钮在第一次构建完成前会 404。页首有一段循环播放的功能演示。下载区有二维码，内容是 `https://wenshisan.github.io/bili-audio/get.html`：Android 打开后下载 APK，iPhone 在 Safari 里走描述文件安装。窄屏不显示这个二维码，直接用下面的按钮。

iOS 按钮只在 Release 里已经有 `bili_audio-ios.ipa` 时可以点，并且只在 iPhone 的 Safari 里开始安装。安装清单 `manifest.plist` 在每次部署介绍页时重写：优先用正式版里的 IPA 地址，否则用 `continuous`。安装包构建成功后会再部署一次介绍页，让清单跟上新文件。

## 应用内升级

设置里有“检查更新”。进入主界面时也会查一次；车机布局下不弹窗。升级对话框只显示 Release 说明里的「更新日志」：相对上一正式版的提交说明。安装包表格和构建日志仍写在 Release 页面，应用里不显示。已经发出、正文里没有这一节的构建说明也不会出现在对话框里。

数据来自 GitHub Releases 最近 100 条。草稿和预发布（包括 `continuous`）跳过，在剩下的里面取版本号最高的一条。标签必须是 `v1.2.3`、`1.2.3`，或带构建号的 `v1.2.3+4`。比较规则：

- 先比主版本、次版本、修订号。
- 本地和远程都带 `+构建号` 时，再比构建号。
- 只有一边有构建号时，忽略构建号。因此本地 `0.1.0+1` 和标签 `v0.1.0` 视为同一版。

有更新且 Release 里有本机文件时，下载到临时目录再打开：

- Android：调起系统安装界面。若还不能安装未知应用，会先打开系统授权页。
- Windows：运行下载的安装程序。
- macOS：在沙盒外挂载磁盘映像，替换当前应用并去掉隔离标记，然后重新打开。沙盒里直接清除失败时，系统会要求输入密码。
- Linux：`xdg-open` 打开 deb。
- iOS：打开介绍页上的描述文件安装地址。Windows ARM 没有对应附件，只说明有新版本并给出发布页地址。

推送到 `main` 就会发出客户端能看到的升级。pubspec 仍是 `0.1.0+1` 时，第一次这样构建的安装包和标签是 `v0.1.0+2`，之后每次加一。安装包里的版本和标签一致：应用比较构建号，Android 的 versionCode 和 Linux 包版本也会变高，系统才允许覆盖安装。

要改主版本、次版本或修订号时，先改 `bili_audio/pubspec.yaml` 的 `version` 再推送。也可以打不带构建号的标签，例如 `git tag v0.2.0 && git push origin v0.2.0`。标签名要和希望写进安装包的 `major.minor.patch` 一致，并带前缀 `v`。之后的 main 构建仍用 pubspec 里的版本名，所以改过标签后也要把 pubspec 改到同一条版本线上，否则后续构建号虽然更大，版本名却更旧，客户端不会把它当成升级。
