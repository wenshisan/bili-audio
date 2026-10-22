# 多平台支持与自适应布局开发计划

> 目标：同一套 Flutter 代码覆盖 **Windows、macOS、iOS、iPadOS、Android 手机、Android 平板、Android 车机**。界面按**当前窗口的宽高**自动换布局，窗口被拖拽、分屏、折叠时连续重排。
>
> 与 `docs/dev-tasks.md` 的关系：播放、歌词、登录、缓存仍以该文档为准。本文只补平台能力与布局，不改 domain 层。可执行任务见 `docs/platform-dev-tasks.md`。

## 0. 约定

- **任务编号**：`A{阶段}.{序号}`，如 `A1.2`。
- **估时**：单人日（d），含对应 widget 测试。
- **完成定义**：`flutter analyze` 无新增 warning；每种宽度档至少一条 widget 测试；改动过的页面在该档代表尺寸上无溢出；不新增“手机 / 平板”分支去决定页面结构。
- **布局输入**：`LayoutBuilder` 的约束，或壳层拿到的 `MediaQuery.sizeOf`。不用 `Platform.isX`、不用 `MediaQuery.orientationOf` 决定页面是单栏还是双栏。

## 1. 现状

| 项 | 现在 | 缺口 |
| --- | --- | --- |
| 工程平台 | `android` / `ios` / `windows` / `macos` / `linux` 已创建 | 无 iPad 多任务声明，无车机清单，无尺寸系统 |
| 壳层 | `HomeShell`：内容 + `MiniPlayer` + 底部 `NavigationBar` | 宽窗口仍是手机底栏，列表被拉得很宽 |
| 播放页 | `PlayerPage` 在宽度 `> 720` 时封面与歌词左右分栏 | 阈值写死，与壳层无关；矮窗口仍纵向堆叠 |
| 桌面窗体 | Windows/macOS/Linux 无边框圆角 + 自定义标题栏；`main.dart` 默认 1440×900，最小 800×600 | 最小宽度 800 落在 medium，桌面拖不到 compact；未记住上次尺寸 |
| 播放后端 | Windows：`just_audio_media_kit` + `smtc_windows`；Android/iOS：`just_audio` + `audio_service` | macOS 媒体键与 Now Playing 未单列验收；车机无媒体浏览树 |
| 系统版本 | Android `minSdk 26`；iOS 工程沿用 Flutter 默认 | iPad 分屏、Android 大屏、车机未验收 |

Linux 已在工程里，本计划不新增目标，桌面布局与 Windows/macOS 共用。

## 2. 关键决策

| # | 议题 | 决策 |
| --- | --- | --- |
| A-D1 | 布局看什么 | 只看窗口逻辑像素的宽、高。手机横屏、iPad 分屏、桌面把窗口拉窄，走同一套档位 |
| A-D2 | 车机怎么识别 | 车机是**能力**，不是宽度。来源：Android `UI_MODE_TYPE_CAR`、Automotive 特性、或设置里的“车机布局”。手机横屏只走“矮窗口”变体，不进入车机界面 |
| A-D3 | 车机交付分三条 | ① 国内安卓大屏：同一 APK，车机布局自绘；② Android Auto：手机投射，只暴露媒体浏览，不在车机上画 Flutter；③ Android Automotive OS：后续独立 flavor，驾驶中只保留播放 |
| A-D4 | iPhone 与 iPad | 同一个 iOS target（`TARGETED_DEVICE_FAMILY = 1,2`），不分发两个包 |
| A-D5 | 手机与平板 | 同一个 Android APK。`resizeableActivity` 保持 true，不锁方向 |
| A-D6 | 导航形态 | 紧凑用底部导航；中等及以上用 `NavigationRail`；超大宽度可把正在播放收成右侧常驻栏 |
| A-D7 | 可伸缩 | 中等宽度以上的主从栏用可拖拽分隔条，比例写入设置。窗口变窄到放不下时自动收起次栏，变宽后再恢复 |
| A-D8 | 触控尺寸 | 普通界面点击目标 ≥ 48dp；车机布局 ≥ 76dp。主操作不依赖悬停 |
| A-D9 | 播放与账号 | 各平台共用 `BiliAudioHandler`、仓储和路由。平台差异只留在窗体装饰、媒体会话、权限和车机限制 |

## 3. 尺寸档位

宽度用 Material 3 窗口等级，单位是逻辑像素。

| 宽度档 | 范围 | 常见来源 |
| --- | --- | --- |
| compact | &lt; 600 | 手机竖屏、iPad Slide Over、桌面窗口拉得很窄 |
| medium | 600–839 | 大手机横屏、小平板竖屏、折叠屏内屏 |
| expanded | 840–1199 | 平板、桌面默认窗口 |
| large | 1200–1599 | 平板横屏、笔记本 |
| extraLarge | ≥ 1600 | 外接显示器、车机超宽屏（是否用车机布局另看 A-D2） |

高度单独分档，只影响纵向密度，不替代宽度档。

| 高度档 | 范围 | 布局变化 |
| --- | --- | --- |
| short | &lt; 500 | 播放页改为横向：封面缩小，歌词改为一行，控制条不换行 |
| regular | 500–899 | 默认 |
| tall | ≥ 900 | 歌词多露几行，列表可多一段预览 |

壳层在 `lib/app/adaptive/` 提供：

```dart
enum WindowWidth { compact, medium, expanded, large, extraLarge }
enum WindowHeight { short, regular, tall }

class WindowMetrics {
  const WindowMetrics(this.width, this.height);
  final WindowWidth width;
  final WindowHeight height;

  bool get usesRail => width != WindowWidth.compact;
  bool get usesMasterDetail =>
      width == WindowWidth.large || width == WindowWidth.extraLarge;
}
```

`WindowMetrics` 从 `BoxConstraints` 计算。页面不要各自写 `maxWidth > 720`。播放页现有的 `720` 阈值在 A1 删掉，改问壳层传入的档位。

建议代表尺寸（widget 测试与手工验收都用这组）：

| 名称 | 尺寸 | 期望 |
| --- | --- | --- |
| 手机竖屏 | 390×844 | compact + tall，底栏 |
| 手机横屏 | 844×390 | expanded + short，横向播放条，**不是**车机布局 |
| 折叠 / 小平板 | 600×800 | medium，Rail |
| 平板竖屏 | 768×1024 | medium，Rail |
| iPad 横屏 | 1194×834 | large，主从栏 |
| 桌面默认 | 1280×800 | large，主从栏 + 标题栏 |
| 桌面拉窄 | 480×800 | compact，回到底栏 |
| 车机宽屏 | 1920×720，且车机能力开启 | 车机布局 |
| 车机矮屏 | 1280×480，且车机能力开启 | 车机布局，歌词仅一行 |

## 4. 各档位界面

### 4.1 壳层

```
compact          medium / expanded         large / extraLarge
┌────────────┐   ┌──┬─────────────┐       ┌──┬──────────┬─────────┐
│  当前页面   │   │  │  当前页面    │       │  │ 列表/详情 │ 正在播放 │
│            │   │R │             │       │R │          │ 封面歌词 │
│ MiniPlayer │   │a │ MiniPlayer  │       │a │          │ 控制     │
│ BottomNav  │   │i │             │       │l │          │          │
└────────────┘   └──┴─────────────┘       └──┴──────────┴─────────┘
```

- **compact**：保持现在的 `HomeShell`（底栏三个目的地：发现、资料库、我的）。迷你播放条在底栏之上。点按进入全屏 `PlayerPage`。
- **medium / expanded**：底栏换成左侧 `NavigationRail`（图标 + 文字）。迷你播放条仍在底部。播放页仍是独立路由。
- **large / extraLarge**：Rail 保持展开。右侧常驻“正在播放”（封面、一行歌词、进度、上一首/播放/下一首）。列表与详情用可拖拽分隔：搜索结果 | 详情，资料库 | 歌单，队列并进播放栏。分隔比例默认 0.62，范围 0.4–0.75，记在设置里。窗口缩回 medium 时收起右栏，不丢播放状态。
- **桌面**：上述结构外套现有 `_DesktopWindowShell`（圆角 + `WindowTitleBar`）。标题栏不参与档位计算，档位用标题栏下面的内容区。
- **车机布局**（仅能力开启时）：隐藏底栏和设置深页。左侧大号播放控制，右侧只留队列或歌词，二选一。不提供拖拽排序。搜索、登录、缓存管理标为停车可用；驾驶态只留播放/暂停、上一首、下一首、音量。

路由仍用现在的 `go_router`。宽屏把 `/player` 显示在右栏，而不是再 push 一层全屏；返回栈语义不变，窄屏依然 push `/player`。

### 4.2 页面

| 页面 | compact | medium / expanded | large+ | 车机 |
| --- | --- | --- | --- | --- |
| 搜索 | 单列列表 | 单列，封面略大；结果区 `maxWidth` 约 840，避免一行字拉满 | 左列表右详情；详情里可直接播放 | 停车态：大搜索框 + 大行高列表。驾驶态不进入 |
| 播放 | 封面在上、歌词在下、控制在底 | 封面与歌词左右分（现有宽屏形态，改走档位） | 作为右栏，不再独占全屏 | 封面缩小，控制按钮 ≥ 76dp，歌词一行 |
| 队列 | 全屏列表 | 全屏列表 | 附在播放栏下方，可拖拽排序 | 只显示接下来 5 首，无拖拽 |
| 资料库 / 歌单 | 单列 | 网格，`maxCrossAxisExtent` 约 180 | 左歌单右曲目 | 停车态大行高；驾驶态不编辑 |
| 设置 / 登录 | 单列全屏 | 内容 `maxWidth` 640 居中 | 同中等宽度，不拉成双栏表单 | 驾驶态入口隐藏 |
| 迷你播放条 | 封面 + 标题 + 播放 | 同左，加上下一首 | 被右栏替代，底部不再重复一条 | 不显示 |

文字缩放、系统字体、安全区（刘海、Home Indicator、桌面标题栏）都算进约束。列表用 `ListView.builder` / `GridView.builder`。

### 4.3 输入

| 输入 | 要求 |
| --- | --- |
| 触控 | 普通 ≥ 48dp，车机 ≥ 76dp |
| 鼠标 | 桌面列表行悬停高亮；主路径仍能单指或单击完成 |
| 键盘 | 桌面与 iPad 外接键盘：空格播放/暂停，左右方向键 seek 5 秒，上下首切歌，`Ctrl/Cmd+F` 聚焦搜索。快捷键不拦截文本框 |
| 车机旋钮 | 本阶段不做方向盘旋钮映射，播放走媒体会话 |

## 5. 平台能力（与布局分开）

布局全部走第 3、4 节。下面只列各系统要补的工程与系统集成。

### 5.1 Windows

已有：`window_manager`、托盘、`just_audio_media_kit`、SMTC。

要补：

- 最小内容区约 360×640，默认 1280×800，记住上次尺寸和位置。
- 缩放时按档位重排，不锁比例。
- 媒体键与任务栏 SMTC 保持现有 `WindowsMediaBridge`。
- 高 DPI 用 Flutter 逻辑像素，不按物理像素写死尺寸。

### 5.2 macOS

播放用 `just_audio` 的 Darwin 后端，不引入 `media_kit`。媒体控制走 `audio_service` 的 `MPRemoteCommandCenter`（控制中心、触控栏、媒体键）。

要补：

- 自定义标题栏与红绿灯对齐，全屏时隐藏标题栏圆角壳。
- 沙盒保持开启。已有网络客户端权限；缓存目录继续用应用容器，用户自选目录再补 security-scoped bookmark。
- 菜单栏：播放/暂停、上一首、下一首、设置。与键盘快捷键同一套命令。
- 最低系统与现工程一致（开发任务里为 macOS 12）。

### 5.3 iOS（iPhone）

已有后台音频模式声明。要补并核对：

- `UIBackgroundModes: audio` 在真机锁屏、控制中心可用。
- 不锁方向。横屏走 short 高度变体。
- 安全区：底部迷你条和底栏避开 Home Indicator；顶部避开灵动岛。
- 来电、闹钟打断后能恢复（与开发任务 M4.5 同一验收）。

### 5.4 iPadOS

与 iPhone 同一个包。

- `UIRequiresFullScreen = false`，支持 Split View、Slide Over、Stage Manager。分屏宽度落到哪一档就用哪一档，禁止用 `UIDevice.userInterfaceIdiom == pad` 选布局。
- 四向旋转。
- 指针悬停与键盘快捷键同 4.3。
- 最低版本需能开多任务（iPadOS 13+；若工程最低版本低于 13，提到 13，不单为 iPad 再升一档）。

### 5.5 Android 手机

已有前台媒体服务、通知权限、`audio_service`。

- 不锁 `screenOrientation`，`configChanges` 继续包含 `screenSize|smallestScreenSize|screenLayout`。
- 手势导航和刘海用 `SafeArea` / `MediaQuery.padding`。
- 折叠屏展开、分屏时重新计算档位，播放不中断。
- 通知栏与锁屏控制维持 M4.1，本计划不重做。

### 5.6 Android 平板

同一个 APK，无 `tablet` flavor。

- `resizeableActivity` 不为 false。
- 不在清单里用 `compatible-screens` 排除大屏。
- 外接键鼠走 4.3。
- 验收用平板模拟器或 `adb` 调整窗口，而不是再打一个包。

### 5.7 Android 车机

三条路径，UI 规则共用第 4 节的车机布局。

**路径 1 · 安卓大屏车机（本计划要交付的自绘界面）**

很多车机是横屏 Android，不是 Android Automotive。安装普通 APK 后：

- 若系统报告 `UI_MODE_TYPE_CAR`，自动进入车机布局。
- 识别不到时，设置中提供“车机布局”开关，默认关。
- 目标分辨率按 1280×480、1280×720、1920×720、1920×1080 验收。
- 只解码音频，不申请视频播放相关界面。

**路径 2 · Android Auto（手机投射）**

车机屏幕不跑 Flutter。补齐 `MediaBrowserService` 可浏览树：正在播放、本地歌单、最近播放。搜索与登录留在手机上。`AndroidManifest` 里已有 `MediaBrowserService` 与媒体按钮接收器，本路径在其上升级浏览内容，不新开 Activity。

**路径 3 · Android Automotive OS（后续，A6）**

独立 flavor `automotive`：

- `uses-feature android.hardware.type.automotive` 仅这个 flavor 为 `required=true`，避免手机包被当成车机专用。
- 启动入口使用车机 launcher 类别。
- 驾驶中：播放控制 + 媒体浏览。搜索、扫码登录、缓存与设置仅停车态。
- 不在驾驶中申请新的运行时权限。
- 手机与平板 flavor 不带 automotive 特性。

车机不主动申请忽略电池优化（与开发任务 D9 一致）。

## 6. 任务拆分

合计约 **16.5d**。A0、A1 是后面所有平台的前置。A2 与 A3 可并行。A6 不计入对内可用版本。

```
A0 尺寸与壳层 ─ A1 页面重排 ─┬─ A2 桌面窗口
                            ├─ A3 手机安全区与系统栏
                            ├─ A4 iPad / Android 平板多窗口
                            └─ A5 车机布局 + Android Auto
A6 Automotive flavor（后续）
A7 验收矩阵贯穿 A1 之后
```

### A0 · 尺寸系统（2d）

#### A0.1 `WindowMetrics`（0.5d）

- `lib/app/adaptive/window_metrics.dart`：按第 3 节把约束分成宽、高两档。
- 纯函数，widget 测试覆盖第 3 节表格里的每一个代表尺寸。
- **验收**：844×390 判定为 expanded + short，且 `usesCarLayout` 默认 false。

#### A0.2 自适应壳（1d）

- `HomeShell` 改为按 `WindowMetrics` 切换底栏 / Rail / 右播放栏。
- 右栏出现时，`/player` 不再覆盖全屏。
- 桌面标题栏仍包在壳外。
- **验收**：390 宽见底栏；800 宽见 Rail；1280 宽见右播放栏。拖动桌面窗口跨越断点时播放不停止。

#### A0.3 可拖拽分隔（0.5d）

- 大宽度主从栏分隔条，比例持久化到现有设置存储。
- 宽度降到 large 以下时写入的比例保留，但不显示分隔条。
- **验收**：拖到 0.4 与 0.75 附近松手，重启后比例仍在；缩窄再拉宽，比例回来。

### A1 · 页面跟随档位（3.5d）

#### A1.1 播放页（1d）

- 删除 `maxWidth > 720`。compact + regular/tall：上封面下歌词。expanded 及以上：左右分栏。short：横向紧凑条。
- **验收**：代表尺寸无溢出；歌词点击跳转仍可用。

#### A1.2 搜索与资料库（1.5d）

- compact 单列；medium 起网格或限宽列表；large 起主从栏。
- 歌单详情在大宽度显示在右侧，窄宽度仍走 `/playlist/:id`。
- **验收**：搜索“周杰伦”在 390 与 1280 都能点播；主从栏点另一首不新开一层路由堆栈。

#### A1.3 设置、登录、队列（1d）

- 表单 `maxWidth` 640 居中。队列在大宽度并入播放栏，窄宽度仍是 `/queue`。
- 登录二维码在 medium 及以上与说明左右排列，compact 上下排列。
- **验收**：设置项不贴到 4K 窗口两侧；队列拖拽只在非车机布局可用。

### A2 · Windows 与 macOS（2.5d）

#### A2.1 窗口尺寸（1d）

- `window_manager`：最小尺寸、默认尺寸、记忆位置。macOS 全屏切换圆角壳。
- **验收**：缩到最小仍是 compact 布局且无黄黑溢出条；重启恢复上次大小。

#### A2.2 macOS 媒体会话与菜单（1d）

- 核对 `audio_service` 在 macOS 上的播放/暂停/上下首/进度。
- 菜单栏命令与 A1 的键盘快捷键共用。
- **验收**：控制中心显示歌名、封面、播放状态；菜单与媒体键都能切歌。

#### A2.3 键盘快捷键（0.5d）

- 桌面与 iPad 同一张快捷键表（见 4.3）。焦点在 `TextField` 时不抢键。
- **验收**：搜索框打字空格不触发暂停；搜索框外空格暂停。

### A3 · iPhone 与 Android 手机（1.5d）

#### A3.1 安全区与横屏（1d）

- 迷你条、底栏、播放控制避开系统插入区域。
- 横屏使用 short 变体，不打开车机布局。
- **验收**：390×844 与 844×390 无遮挡；折叠或旋转时曲目不重置。

#### A3.2 后台与打断回归（0.5d）

- iOS 锁屏控制中心、Android 通知栏各测一次切歌。
- **验收**：锁屏切歌后，前台进度与歌词跟上。

### A4 · iPadOS 与 Android 平板（2d）

#### A4.1 iPad 多任务（1d）

- 关闭强制全屏，允许四向旋转。
- 在全屏、1/2 分屏、1/3 分屏各记一档截图或 widget 测试约束。
- **验收**：1/3 分屏为 compact 底栏；全屏横屏为 large 主从栏。Slide Over 不溢出。

#### A4.2 Android 大屏（1d）

- 清单确认可调整大小、不锁方向、不排除大屏。
- 平板横屏、竖屏、分屏三档手工通过。
- **验收**：与 iPad 同一宽度时导航形态一致（同为 Rail 或同为底栏）。

### A5 · 车机布局与 Android Auto（3.5d）

#### A5.1 车机能力开关（0.5d）

- 读取 Android 车载 UI 模式；其他平台恒为 false。
- 设置项“车机布局”可强制开/关/自动。自动为默认。
- **验收**：手机横屏在“自动”下仍是普通 short 布局；开关打开后同一窗口变成车机布局。

#### A5.2 车机播放界面（1.5d）

- 按 4.1、4.2 的车机列实现。按钮 ≥ 76dp。驾驶相关入口只保留运输控制。
- 搜索、登录、设置、缓存在强制车机布局下从导航移除（本阶段用开关模拟驾驶态；A6 再接系统的停车/驾驶限制）。
- **验收**：1280×720 与 1920×480 无溢出；三步内可以暂停和切歌。

#### A5.3 Android Auto 浏览树（1.5d）

- 在现有 `AudioService` 上提供可浏览节点：正在播放、歌单、最近播放。
- 车机端使用系统媒体 UI，不嵌入 Flutter 画面。
- **验收**：桌面机用媒体浏览测试工具或 Android Auto 桌面端能列出歌单并点播。没有测试机时，用单元测试断言浏览树结构，并在文档记下未上真车。

### A6 · Android Automotive（后续，2.5d，不含在 16.5d 内）

#### A6.1 flavor 与清单（1d）

- `automotive` flavor，单独 applicationId 后缀，automotive feature required。
- 手机 flavor 不声明该 feature 为必需。

#### A6.2 驾驶限制（1.5d）

- 能读到停车/驾驶状态时：驾驶中只留 A5.2 的控制；停车恢复搜索和登录。
- 读不到状态时保持 A5 的手动开关，不猜测车速。
- **验收**：Automotive 模拟器冷启动进播放；模拟驾驶时搜索入口不可用；模拟停车后恢复。

### A7 · 验收（1.5d，与 A2–A5 重叠进行）

- widget 测试固定第 3 节代表尺寸，断言导航类型（底栏 / Rail / 右栏 / 车机控制）和“无溢出”。
- 每个要交付的系统至少手跑一条主路径：搜索 → 播放 → 切歌 → 锁屏或系统媒体控件（车机则为大按钮切歌）。
- 记录未测设备。测不到的格子不能标通过。

## 7. 验收矩阵

| 场景 | Windows | macOS | iPhone | iPad | Android 手机 | Android 平板 | 安卓车机大屏 | Android Auto |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 按窗口换布局 | 缩放窗口 | 缩放窗口 | 竖屏/横屏 | 全屏与分屏 | 竖屏/横屏/折叠 | 竖屏/横屏/分屏 | 车机开关 + 目标分辨率 | 不画 Flutter UI |
| 播放与切歌 | 应用内 + SMTC | 应用内 + 控制中心 | 应用内 + 锁屏 | 同 iPhone | 应用内 + 通知 | 同手机 | 大按钮 | 车机系统控件 |
| 后台或最小化继续播 | 最小化 | 最小化 | 锁屏 | 锁屏 / 分屏切走 | 锁屏 | 分屏 | 亮屏长播 | 手机锁屏后车机仍可控 |
| 键盘或指针 | 键盘 | 键盘 | — | 键盘 + 指针 | — | 键鼠（如有） | — | — |

主路径通过标准：从搜索点一首 ≤ 15 分钟的曲目，2 秒内出声；切歌后标题、进度、歌词行一致；跨越一次尺寸断点后仍是同一首、进度不回零。

## 8. 风险

| 风险 | 处理 |
| --- | --- |
| 手机横屏被做成车机 | 车机只由 UI 模式或用户开关开启，宽度不够触发 |
| iPad / 平板用设备类型写死双栏，分屏溢出 | 代码评审拒绝 `idiom == pad`、`smallestScreenWidthDp` 选布局 |
| macOS 沙盒读不到用户自选缓存目录 | A2 不改缓存路径产品行为；要自定义目录时另开 bookmark 任务 |
| 车机系统不是 Automotive，也没有 `UI_MODE_TYPE_CAR` | 靠设置开关；不在宽度上猜测 |
| Android Auto 没有车机或 DHU | A5.3 先锁浏览树单测，真车列为例外 |
| Automotive 上架要求媒体模板，自绘界面可能不合规 | A6 默认媒体会话 + 驾驶限制；自绘只作为大屏 APK 路径，不假设能上 Play 车机分类 |
| 右栏常驻播放和全屏播放两套状态 | 只保留一个 `BiliAudioHandler`；右栏与 `PlayerPage` 共用同一组控件 widget |

## 9. 建议落地顺序

1. A0、A1 先合入，桌面把窗口拉一遍就能看到布局变化。
2. A2、A3、A4 按手头机器并行。
3. A5 在壳层稳定后做。没有车机时用设置开关和代表分辨率验收自绘界面。
4. A6 等有 Automotive 模拟器再开，不阻塞其他六个平台。
