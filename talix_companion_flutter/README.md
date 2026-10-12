# Talix Companion Flutter App

原生配套 Android, iOS, Windows & macOS 跨平台 App 完整开发级 Dart 代码仓库。此项目完美复刻了 React 交互模拟器中的 14+14 全保真界面和业务控制逻辑，并新增集成了桌面端（Windows 和 macOS）的高仿手机比例窗口管理器（WindowManager）：
1. **绑定与安全解绑**: 支持搜索蓝牙、扫码绑定及高危数据清除。
2. **多声道降噪选择**: 支持通用、全向会议、面对面访谈与无损原声 4 种物理阵列微调。
3. **空间与存储分析**: 提供双卡/双端空间可视化容量分析与文件批量删除逻辑。
4. **升级拦截防护**: 内置 OTA 固件拉取更新与电池电量防御机制。

---

## 如何直接推送到你的 GitHub 仓库 (Push to GitHub)

你可以通过以下指令将此 Flutter 代码独立发布并推送到你的 GitHub 上：

1. **进入 Flutter 项目文件夹**:
   ```bash
   cd talix_companion_flutter
   ```

2. **初始化本地 Git 仓库**:
   ```bash
   git init
   ```

3. **添加并提交所有文件**:
   ```bash
   git add .
   git commit -m "feat: init Talix Companion App Flutter codebase"
   ```

4. **配置你的 GitHub 远端仓库并推送**:
   ```bash
   git branch -M main
   # 将下方链接替换成你在 GitHub 上新建的空白仓库地址
   git remote add origin https://github.com/你的用户名/你的仓库名.git
   git push -u origin main
   ```

---

## 本地编译运行指南 (Local Build & Run)

powershell -ExecutionPolicy Bypass -File build_release.ps1


本项目现已全面升级，原生支持 **Android, iOS, Windows (Desktop) 和 macOS (Desktop)** 四端平台。

为了让项目能在你的电脑上完美编译并运行，请参见以下步骤：

### 1. 各平台前置准备条件 (Prerequisites)
- **Windows**: 确保你已安装 [Visual Studio 2022](https://visualstudio.microsoft.com/)，并在安装时勾选了 **“使用 C++ 的桌面开发” (Desktop development with C++)** 工作负载以及相关的 Windows SDK。
- **macOS**: 确保你已安装 [Xcode](https://developer.apple.com/xcode/)，并运行过 `sudo xcode-select --install` 补全命令行编译链。
- **Android / iOS**: 安装最新版本的 Android Studio / Xcode 及对应的真机/模拟器。

### 2. 启用 Flutter 桌面端支持 (Enable Desktop Platforms)
在电脑终端运行以下配置，以开启你的电脑平台支持：
```bash
# 开启 Windows 桌面端编译能力
flutter config --enable-windows-desktop

# 开启 macOS 桌面端编译能力
flutter config --enable-macos-desktop
```

### 3. 自动补全原生运行包壳
进入 `talix_companion_flutter` 文件夹，执行：
```bash
flutter create --platforms=windows,macos,android,ios . --org com.talix
```
*提示：该命令会自动补全 Windows / macOS 桌面工程、以及 iOS / Android 移动端工程，且不会改变已有的 `lib/` 文件夹中的核心 Dart 代码和界面。*

### 4. 窗口比例仿真与系统托盘支持（已在代码中内置）
为了让应用在 Windows / macOS 桌面端上运行时拥有高仿实机的高保真视觉观感与驻留体验，项目已在 `lib/main.dart` 中引入了 `window_manager` 和 `system_tray`：
- **手机比例仿真**：桌面端启动时自动将窗口约束为经典的 **390 × 844 (iPhone 14/15)** 经典伴侣比例，居中呈现在桌面上。限制最大和最小尺寸，防止变形。
- **系统驻留托盘**：自动在系统任务栏托盘区域创建图标，注册鼠标单击、双击和右键事件：
  - **单击/双击**：自适应拉起/激活并聚焦主面板窗口，对用户更友好。
  - **右键菜单**：呼出上下文菜单，提供 **“显示主面板 (Show)”**、**“隐藏至后台 (Hide)”** 以及 **“退出伴侣应用 (Exit)”**。

### 5. 安装依赖包
```bash
flutter pub get
```

### 6. 运行与编译调试 (Run & Build)
- **直接本地运行**:
  ```bash
  # 运行于 Windows 桌面
  flutter run -d windows
  
  # 运行于 macOS 桌面
  flutter run -d macos
  
  # 运行于手机/模拟器
  flutter run
  ```
- **编译打包发行版 (Production Release Build)**:
  ```bash
  # 编译 Windows 绿色免安装版 (输出在 build/windows/runner/Release)
  flutter build windows
  
  # 编译 macOS App (输出在 build/macos/Build/Products/Release)
  flutter build macos
  ```

---

## 目录结构说明

```text
talix_companion_flutter/
├── pubspec.yaml                 # 依赖包配置文件 (包含 percent_indicator 等)
├── README.md                    # 本指南说明书
├── .gitignore                   # Flutter 忽略配置文件
└── lib/
    ├── main.dart                # App 程序入口与 Provider 全局状态共享
    └── screens/
        ├── binding_screens.dart  # 设备绑定流程、扫码与绿激光动画、蓝牙雷达页面
        ├── device_settings.dart  # 3D卡片展示、LED控制与智能声道模式微调页面
        ├── file_manager.dart     # 双端存储进度、文件批量物理删除与多选页面
        └── firmware_update.dart  # 电量防御 OTA 升级进度页面
```
