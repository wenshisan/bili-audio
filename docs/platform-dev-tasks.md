# 多平台自适应 · 开发任务

> 设计依据：`docs/platform-support-plan.md`。播放、歌词、登录、缓存仍以 `docs/dev-tasks.md` 为准。
>
> 本文只排布局和平台壳的施工顺序。一个任务一个分支：`feat/A{x}.{y}-short-name`。

## 0. 开工前已核对的事实

这些不用重做，任务里写“改”的才动。

| 事实 | 位置 | 对计划的影响 |
| --- | --- | --- |
| 壳层只有底栏 | `lib/features/home/home_shell.dart`、`bottom_nav.dart` | A0.2 在这里换导航，目的地仍是发现 / 资料库 / 我的 |
| 播放页用 `maxWidth > 720` 分栏 | `lib/features/player/player_page.dart` | A1.1 删掉这个魔数 |
| 桌面窗口默认 1440×900，最小 800×600 | `lib/main.dart` 的 `WindowOptions` | 现在拖不到 compact。A2.1 把最小内容区降到约 360×640 |
| 设置是 KV，不必改表结构 | `Settings` 表 + `SettingsDao.get/set` | 分隔比例、车机开关各加一个 key |
| iPhone / iPad 已是同一个 target | `TARGETED_DEVICE_FAMILY = 1,2`，iPad 四向已开 | A4.1 只核对分屏，不新建 target |
| 播放器只有一个 handler | `BiliAudioHandler extends BaseAudioHandler` | 右栏和全屏播放页共用它；Android Auto 在这里补浏览树 |
| 车机 UI 模式尚未读取 | 无 | A5.1 新写，默认自动且非 Android 恒为关 |

完成定义沿用设计文档：`flutter analyze` 无新增 warning；改过的宽度档有 widget 测试；代表尺寸无溢出；页面结构不写 `Platform.isX` 或“是不是平板”。

## 1. 里程碑

| 里程碑 | 内容 | 估时 | 做完能看到什么 |
| --- | --- | --- | --- |
| A0 | 尺寸档位 + 自适应壳 + 分隔条 | 2d | 把窗口从窄拉到宽，底栏变成侧栏，再出现右播放栏 |
| A1 | 搜索、播放、资料库、设置、队列跟随档位 | 3.5d | 大窗口主从栏，矮窗口播放条改为横向 |
| A2 | Windows / macOS 窗口、菜单、快捷键 | 2.5d | 桌面能缩到手机宽度；macOS 控制中心能切歌 |
| A3 | iPhone / Android 手机安全区与横屏 | 1.5d | 横屏不挡系统条，也不进入车机界面 |
| A4 | iPad 分屏、Android 平板 | 2d | 三分之一分屏是底栏，全屏横屏是主从栏 |
| A5 | 车机布局 + Android Auto 浏览树 | 3.5d | 设置打开车机布局后只留大按钮；浏览树能点播歌单 |
| A7 | 代表尺寸与主路径验收 | 1.5d | 与 A2–A5 重叠，不单独排在最后 |
| | **合计** | **16.5d** | |
| A6 | Android Automotive flavor | 2.5d | 不在本轮。有模拟器再开 |

单人顺序：

```
A0.1 → A0.2 → A0.3 → A1.1 → A1.2 → A1.3
        → A2.1 → A2.3 → A2.2
        → A3.1 → A3.2
        → A4.1、A4.2（可换序）
        → A5.1 → A5.2 → A5.3
```

A1 结束后，Windows 上把窗口拉一遍就能验收布局。A2 与 A3 都只依赖 A1，有两台机器时可以并行。A5 必须等 A0.2 的壳层稳定。

## 2. A0 · 尺寸与壳层（2d）

### A0.1 档位函数（0.5d）

新建 `lib/app/adaptive/window_metrics.dart`。输入逻辑像素宽高，输出设计文档第 3 节的 `WindowWidth` / `WindowHeight`。

```dart
class WindowMetrics {
  const WindowMetrics(this.width, this.height);
  final WindowWidth width;
  final WindowHeight height;

  bool get usesRail => width != WindowWidth.compact;
  bool get usesMasterDetail =>
      width == WindowWidth.large || width == WindowWidth.extraLarge;
  bool get isShort => height == WindowHeight.short;
}
```

`usesCarLayout` 不放在这里。车机由 A5.1 的能力开关决定。

测试 `test/app/window_metrics_test.dart`，逐条锁住：

| 输入 | 宽度档 | 高度档 |
| --- | --- | --- |
| 390×844 | compact | tall |
| 844×390 | expanded | short |
| 600×800 | medium | regular |
| 768×1024 | medium | tall |
| 1194×834 | large | regular |
| 1280×800 | large | regular |
| 480×800 | compact | regular |
| 1920×720 | extraLarge | regular |
| 1280×480 | large | short |

**验收**：844×390 是 expanded + short。此任务不产生车机布局。

### A0.2 自适应壳（1d）

改 `lib/features/home/home_shell.dart`。用内容区 `LayoutBuilder` 取 `WindowMetrics`，不要用整窗 `MediaQuery.sizeOf`（桌面标题栏会占掉一截高度）。

| 档位 | 导航 | 播放 |
| --- | --- | --- |
| compact | 现有 `BottomNav` | 底部 `MiniPlayer`，点按仍 `push /player` |
| medium、expanded | `NavigationRail`，目的地与底栏相同 | 底部 `MiniPlayer` |
| large、extraLarge | 展开的 Rail | 右侧常驻播放栏，不再 push 全屏 `/player` |

播放栏只读 `BiliAudioHandler`，不新建第二套播放状态。桌面圆角壳继续留在 `lib/app/app.dart` 的 `_DesktopWindowShell`，包在壳外面。

测试：`test/features/home/home_shell_test.dart` 用 `MediaQuery` 或父约束钉住 390、800、1280 三档，断言能找到 `NavigationBar`、`NavigationRail`、右栏标记三者之一。

**验收**：三档导航形态正确。此任务可以先放占位右栏，A1.1 再放上真控件。

### A0.3 分隔条（0.5d）

新建 `lib/app/adaptive/split_view.dart`。只在 `usesMasterDetail` 时使用。拖拽范围 0.4–0.75，默认 0.62。

比例写入设置键 `layout.split_ratio`，走现有 `SettingsDao.set`，不升 `schemaVersion`。宽度降到 large 以下时不显示分隔条，键保留。

**验收**：拖到两端松手，重启后比例仍在；缩到 800 再拉回 1280，比例回来。

## 3. A1 · 页面跟随档位（3.5d）

依赖 A0。页面从壳层Inherited 或参数拿 `WindowMetrics`，禁止再写死宽度阈值。

### A1.1 播放页（1d）

改 `player_page.dart`，删掉 `c.maxWidth > 720`。

| 条件 | 布局 |
| --- | --- |
| compact，且高度不是 short | 封面在上，歌词在下 |
| expanded 及以上，高度不是 short | 封面与歌词左右分 |
| short | 横向：小封面、一行歌词、控制不换行 |
| large 及以上 | 同一组控件放进 A0.2 的右栏 |

把封面、进度、控制抽成右栏和全屏页都能用的 widget，放在 `lib/features/player/widgets/`。

**验收**：390×844、844×390、1280×800 无溢出。点歌词仍能 seek。

### A1.2 搜索与资料库（1.5d）

改 `search_page.dart`、`library_page.dart`、`playlist_detail_page.dart`。

- compact：保持单列。
- medium / expanded：列表或网格限宽，网格 `maxCrossAxisExtent` 约 180，文字列 `maxWidth` 约 840。
- large 及以上：左列表、右详情。歌单曲目直接画在右栏，窄宽度仍 `push /playlist/:id`。

**验收**：1280 宽连续点两首，路由栈不多推一层 `/player`。390 宽点歌行为与现在一致。

### A1.3 设置、登录、队列（1d）

- `settings_page.dart`、`cache_page.dart`：外层 `ConstrainedBox(maxWidth: 640)` + `Center`。
- `login_page.dart`：compact 上下排，medium 及以上二维码与说明左右排。
- `queue_page.dart`：大宽度放进播放栏下方；compact / medium 仍走 `/queue`。随机模式下的不可拖拽逻辑保持不变。

**验收**：1280×800 设置项不贴两边。队列拖拽在非车机布局下仍可用。

## 4. A2 · Windows 与 macOS（2.5d）

依赖 A1。播放后端不动：Windows 继续 `just_audio_media_kit` + `WindowsMediaBridge`，macOS 继续 `just_audio` + `audio_service`。

### A2.1 窗口尺寸（1d）

改 `lib/main.dart` 的 `WindowOptions`：

- `minimumSize` 改为 `Size(360, 640)`，让桌面能进入 compact。
- 默认尺寸保持 1280×800 这一档（现在是 1440×900，可改为 1280×800，或维持 1440×900，只要落在 large）。
- 关闭前把位置和大小写入设置键 `window.x`、`window.y`、`window.w`、`window.h`；下次启动在屏幕内则恢复。
- macOS 进入全屏时去掉 `_DesktopWindowShell` 的 8px 圆角，退出全屏再加回。

**验收**：缩到最小是底栏且无溢出条；重启后尺寸还在。

### A2.2 macOS 媒体会话与菜单（1d）

核对 `audio_service` 在 macOS 上是否把播放、暂停、上下首、进度送到控制中心。缺回调就补在 handler 的现有广播路径上，不另写一套桥。

菜单栏命令与 A2.3 共用同一组动作：播放/暂停、上一首、下一首、设置。

**验收**：控制中心能看到歌名和播放状态，菜单能切歌。本机不是 macOS 时，这条标为未测，不标通过。

### A2.3 键盘快捷键（0.5d）

在 `BiliAudioApp` 外包 `Shortcuts` / `Actions`，桌面和 iPad 外接键盘共用：

| 键 | 动作 |
| --- | --- |
| 空格 | 播放 / 暂停 |
| 左 / 右 | seek 5 秒 |
| 上 / 下 或媒体上下首 | 切歌 |
| Ctrl/Cmd+F | 聚焦搜索 |

焦点在 `TextField`、`EditableText` 时这些键不拦截。

**验收**：搜索框里按空格不暂停；搜索框外空格暂停。

## 5. A3 · 手机（1.5d）

依赖 A1。不改通知栏和锁屏的实现，只回归。

### A3.1 安全区与横屏（1d）

迷你条、底栏、播放控制放在 `SafeArea` 内，避开 Home Indicator、手势条和刘海。横屏只触发 `isShort`，不打开车机布局。

不锁 `screenOrientation`。Android `configChanges` 已含 `screenSize|smallestScreenSize|screenLayout`，保持。

**验收**：390×844 与 844×390 控件不被系统条挡住。旋转或折叠后仍是同一首，进度不回零。

### A3.2 系统控件回归（0.5d）

iOS 锁屏控制中心切歌一次，Android 通知栏切歌一次。

**验收**：切歌后前台标题、进度、歌词行跟上。没有对应真机则记入 A7 的未测表。

## 6. A4 · 平板（2d）

依赖 A1。不打第二个包。

### A4.1 iPad 多任务（1d）

确认 `Info.plist` 没有 `UIRequiresFullScreen = true`（当前没有，不要加上）。iPad 四向旋转已经开启。

用窗口约束补测试，不靠 `UIDevice.userInterfaceIdiom`：

| 场景 | 约略尺寸 | 期望 |
| --- | --- | --- |
| Slide Over / 三分屏 | 320×800 或 375×800 | compact，底栏 |
| 二分屏 | 507×800 左右，或实测宽度 | 宽度 &lt; 600 为底栏，≥ 600 为 Rail |
| 全屏横屏 | 1194×834 | large，主从栏 |

`UIApplicationSupportsMultipleScenes` 现在是 false。Split View 不依赖它。Stage Manager 多窗口本轮不打开。

**验收**：三分屏无溢出；全屏横屏是主从栏。

### A4.2 Android 大屏（1d）

核对 `AndroidManifest`：`resizeableActivity` 不为 false，没有 `screenOrientation` 锁，没有 `compatible-screens` 排除大屏。缺省已满足时只加注释，不改行为。

用平板模拟器或可调窗口看竖屏、横屏、分屏。同一宽度档必须和 iPad 同一导航形态。

**验收**：768×1024 是 Rail；1194 宽是主从栏。

## 7. A5 · 车机（3.5d）

依赖 A0.2 和 A1.1。

### A5.1 能力开关（0.5d）

新建 `lib/app/adaptive/car_layout.dart`。

- Android：读 `UiMode` 是否为 car。读不到就当否。
- 其他平台：恒为否。
- 设置键 `layout.car_mode`：`auto` / `on` / `off`，默认 `auto`。
- `on` 强制车机布局；`off` 强制关；`auto` 只在 Android 车载 UI 模式为真时开。

设置页外观分组加一行。文案进 `lib/l10n/app_zh.arb`。

**验收**：844×390 在 `auto` 下仍是普通 short 布局。同一尺寸拨到 `on` 后变成车机布局。

### A5.2 车机播放界面（1.5d）

车机布局打开时：

- 不用底栏，不显示设置、登录、缓存、搜索编辑。
- 左侧大号播放控制，点击目标 ≥ 76dp。
- 右侧队列或一行歌词，二选一。队列最多 5 首，不能拖拽。
- 三步内可以暂停和切歌。

1280×720、1920×480 两个约束做 widget 测试。

**验收**：两个尺寸无溢出。关掉开关后恢复 A1 的普通布局。

### A5.3 Android Auto 浏览树（1.5d）

在 `BiliAudioHandler` 上实现 `audio_service` 的浏览回调。节点只包括：正在播放、本地歌单、最近播放。车机系统画界面，Flutter 不往车机上放 View。

单测断言树结构和点播后 handler 的当前曲目。没有 Desktop Head Unit 或真车时，在 A7 记“浏览树单测通过，投射未测”。

**验收**：单测能从歌单节点触发播放。不新增 Activity。

## 8. A7 · 验收（1.5d，与 A2–A5 同时做）

代表尺寸的导航断言集中在 `test/app/window_metrics_test.dart` 和 `test/features/home/home_shell_test.dart`。每完成一个平台任务，在下表填“通过”或“未测 + 原因”。未测不能写成通过。

| 主路径 | Windows | macOS | iPhone | iPad | Android 手机 | Android 平板 | 车机大屏 | Android Auto |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 搜索一首并出声 | | | | | | | 仅车机开关打开时 | 浏览树点播 |
| 切歌后标题和歌词跟上 | | | | | | | | |
| 跨越一个宽度断点，进度不回零 | | | | | | | | 不适用 |
| 系统媒体控件或大按钮切歌 | SMTC | 控制中心 | 锁屏 | 锁屏 | 通知栏 | 通知栏 | 76dp 按钮 | 系统控件 |

主路径通过线：点一首不超过 15 分钟的曲目，2 秒内出声；切歌后标题、进度、当前歌词行一致。

## 9. 本轮不做

- A6 Automotive flavor、驾驶/停车系统状态。没有模拟器之前不建 flavor。
- Linux 安装包。桌面布局它已经跟着 Windows 走。
- 用宽度猜测车机。没有 `UI_MODE_TYPE_CAR` 时只靠设置开关。
- 方向盘旋钮、Stage Manager 多窗口、macOS 用户自选缓存目录的 bookmark。
- 改 `domain/`、播放队列和音频缓存。
