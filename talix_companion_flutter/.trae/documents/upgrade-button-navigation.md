# 升级按钮导航 + 侧边栏卡片联动 实现方案

## Context

用户反馈: `main_frame.dart` 左侧导航栏底部的"升级"按钮当前**没有 onTap**, 点击后无响应. 本次需要:
1. **让点击生效**: 点击"升级"胶囊按钮后, 打开全屏升级订阅页面 (Figma 1218:10594)
2. **入口统一**: "我的"页面内的两处升级入口 (`升级至专业版` 行 + 会员卡的 `免费试用升级版` 按钮) 也改为 push 同一个全屏升级页面, 保持三个入口行为一致
3. **侧边栏联动**: 升级成功后, 侧边栏底部的 `Talix 基础版` 卡片要自动变为 Pro 版 (满进度条 + Pro 文案), 跟随 `MeProfileViewModel.isPremiumUser` 状态

升级页面的 UI 在 `me_profile_screen.dart` 第 658-950 行已经完整实现, 本次把它抽出来作为独立 widget 复用, 避免代码重复.

## 核心架构

- **新建** `lib/screens/upgrade_screen.dart` (~480 行): 包含 `UpgradeScreen` widget + 5 个 public helper class
- **修改** `lib/main_frame.dart` (+~50 行): MainFrame 持有 `MeProfileViewModel`, 升级按钮加 `onTap`, 升级卡片用 `ListenableBuilder` 监听 VM 实现联动
- **修改** `lib/screens/me_profile_screen.dart` (-~450 行): 接受外部 VM 注入, 移除内部升级页面 + helper class, 3 处入口改为 `_openUpgradeScreen()`
- **不改** `lib/viewmodels/me_profile_viewmodel.dart`: 复用现有 `selectedPlan` / `selectedBillingCycle` / `isPremiumUser` 状态, 保证跨页面一致

## 文件改动详细清单

### 1. 新建 `lib/screens/upgrade_screen.dart`

从 `me_profile_screen.dart` 第 658-950 行 + 第 2193-2361 行抽取并改造.

**`UpgradeScreen` widget 关键代码 (节选):**

```dart
class UpgradeScreen extends StatefulWidget {
  final MeProfileViewModel viewModel;
  const UpgradeScreen({super.key, required this.viewModel});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  // 渲染: Scaffold + AppBar ('升级订阅' + 返回箭头) + ListView (与原 me-05 保持一致)
  // AppBar 返回: Navigator.pop(context)
  // 购买成功: vm.isPremiumUser = true; toast 成功; Navigator.pop(context)
}
```

**5 个 helper class 重命名为 public, 放在同文件顶层:**

| 旧名 (me_profile_screen.dart) | 新名 (upgrade_screen.dart) |
|---|---|
| `_PlanBulletRow` | `PlanBulletRow` |
| `_BenefitColumn` | `BenefitColumn` |
| `_PlanCheckColumn` | `PlanCheckColumn` |
| `_ComparisonCheckCell` | `ComparisonCheckCell` |
| `_CheckMarkPainter` | `CheckMarkPainter` |

内部方法 (`_buildPlanCard` / `_buildComparisonTable` / `_buildBillingCycleOption` / `_buildPurchaseButton`) 搬入 `_UpgradeScreenState` 内部, 保持私有, 引用 `widget.viewModel` 代替原 `_viewModel`.

**依赖**:
- `import 'package:flutter/material.dart';`
- `import '../viewmodels/me_profile_viewmodel.dart';`
- `import '../widgets/file_list_widgets.dart' show FigmaTokens, showFileListToast;`

### 2. 修改 `lib/main_frame.dart`

**(a) 顶部新增 import**:
```dart
import 'screens/upgrade_screen.dart';
import 'viewmodels/me_profile_viewmodel.dart';
```

**(b) `MainFrameState` 持有 VM** (line 24 附近):
```dart
class MainFrameState extends State<MainFrame> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  String _fileFilter = 'all';
  // 新增: MainFrame 持有 MeProfileViewModel, 注入 MeProfileScreen + UpgradeScreen
  late final MeProfileViewModel _profileViewModel;

  @override
  void initState() {
    super.initState();
    _profileViewModel = MeProfileViewModel();
  }

  @override
  void dispose() {
    _profileViewModel.dispose();
    super.dispose();
  }
  // ... 现有方法 ...
}
```

**(c) `_buildScreens()` (line 65 附近)**: 注入 VM 给 `MeProfileScreen`
```dart
// 旧: const MeProfileScreen(),
// 新:
MeProfileScreen(viewModel: _profileViewModel), // Index 4
```

**(d) 新增 `_openUpgradeScreen()` 方法**:
```dart
void _openUpgradeScreen() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => UpgradeScreen(viewModel: _profileViewModel),
    ),
  );
}
```

**(e) `_buildUpgradeCard()` (line 265-354) 改造**: 整体用 `ListenableBuilder` 包裹, 根据 `isPremiumUser` 显示不同状态. "升级"按钮 (line 296-315) 加 `InkWell.onTap: _openUpgradeScreen`.

```dart
Widget _buildUpgradeCard() {
  return ListenableBuilder(
    listenable: _profileViewModel,
    builder: (context, _) {
      final isPro = _profileViewModel.isPremiumUser;
      return Container(
        width: 191,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isPro ? 'Talix Pro 专业版' : 'Talix 基础版',
                    style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 16,
                      fontWeight: FontWeight.w400, color: Color(0xFF000000), height: 1.0,
                    ),
                  ),
                ),
                // 升级按钮 (Pro 版时改为 "管理" 保持点击行为)
                InkWell(
                  onTap: _openUpgradeScreen,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56, height: 24, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD4D4D4), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '升级',
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 10,
                        fontWeight: FontWeight.w400, color: Color(0xFF000000),
                        height: 1.0, letterSpacing: 0.0064,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 进度条
            Container(
              width: double.infinity, height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: isPro ? 1.0 : 0.25,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626), borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPro ? '专业级 AI 会员 • 无限次极速转写' : '剩余220 / 800 分钟',
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w400,
                color: Color(0xFFA1A1A1), height: 1.0, letterSpacing: 0.0117,
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

### 3. 修改 `lib/screens/me_profile_screen.dart`

**(a) 顶部新增 import**:
```dart
import 'upgrade_screen.dart';
```

**(b) `MeProfileScreen` 接受外部 VM** (line 19-25):
```dart
class MeProfileScreen extends StatefulWidget {
  final String initialSubScreen;
  final MeProfileViewModel? viewModel; // 新增: 可选外部注入
  const MeProfileScreen({
    super.key,
    this.initialSubScreen = 'me-01',
    this.viewModel,
  });
  // ...
}
```

**(c) `_MeProfileScreenState` 状态管理** (line 27-59):
```dart
class _MeProfileScreenState extends State<MeProfileScreen> {
  late final MeProfileViewModel _viewModel;
  bool _ownsViewModel = false; // 是否由本页面创建 (决定 dispose)

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = MeProfileViewModel(initialSubScreen: widget.initialSubScreen);
      _ownsViewModel = true;
    }
    _accountNicknameController.text = _viewModel.nickname;
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    // TextEditingController dispose 保持不变
    super.dispose();
  }
  // ...
}
```

**(d) 新增 `_openUpgradeScreen()` 方法** (line 65 附近):
```dart
void _openUpgradeScreen() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => UpgradeScreen(viewModel: _viewModel),
    ),
  );
}
```

**(e) 修改 3 处入口** (从 `_navigate('me-05')` 改为 `_openUpgradeScreen`):
- 第 147 行 (会员卡右侧 "免费试用升级版" 按钮): `onTap: () => _navigate('me-05'),` → `onTap: _openUpgradeScreen,`
- 第 303 行 (`升级至专业版` 设置行): `onTap: () => _navigate('me-05'),` → `onTap: _openUpgradeScreen,`

**(f) 删除以下代码**:
- `_buildActiveScreen` 里的 `case 'me-05': return _buildUpgradeScreen();` (line 104-105)
- 整个 `_buildUpgradeScreen()` 方法 (line 658-761, 共 ~104 行)
- 整个 `_buildPlanCard()` 方法 (line 766-827, 共 ~62 行)
- 整个 `_buildComparisonTable()` 方法 (line 832-857, 共 ~26 行)
- 整个 `_buildBillingCycleOption()` 方法 (line 861-911, 共 ~51 行)
- 整个 `_buildPurchaseButton()` 方法 (line 915-950, 共 ~36 行)
- 5 个 helper class: `_PlanBulletRow` / `_BenefitColumn` / `_PlanCheckColumn` / `_ComparisonCheckCell` / `_CheckMarkPainter` (line 2193-2361, 共 ~169 行)

合计从 `me_profile_screen.dart` 中删除约 **448 行**, 净减重明显.

## 关键设计决策

| 决策 | 选择 | 理由 |
|---|---|---|
| 独立 UpgradeScreen | 是 | 与 RecycleBinScreen 同级, 避免影响 MeProfile tab 状态, 符合用户"独立打开"要求 |
| 共享 ViewModel | 是 | `isPremiumUser` 跨页面 (MeProfile 会员卡 + 侧边栏升级卡 + UpgradeScreen) 状态必须一致, 新建 VM 需要额外同步机制 |
| 私有 helper 重命名 | 提升为 public | 跨文件复用, 命名一致 |
| me-05 路由 | 删除 | 三个入口统一 push UpgradeScreen, 行为一致 |
| 购买后返回 | Navigator.pop | 返回 push 此页的页面 (MainFrame 或 MeProfile) |
| 侧边栏联动 | ListenableBuilder 包裹 | 升级后立即看到 Pro 版状态, 符合用户期望 |
| Pro 版时按钮文案 | 保持"升级" | Pro 用户也能进入升级页查看/切换套餐, 简化实现 |

## 复用现有代码

- `MeProfileViewModel` (`lib/viewmodels/me_profile_viewmodel.dart`): 完全复用, 含 `selectedPlan` / `selectedBillingCycle` / `isPremiumUser`
- `FigmaTokens` (`lib/widgets/file_list_widgets.dart` line 5-31): 复用 `primary` / `textMuted` / `iconPlaceholder` 等颜色常量
- `showFileListToast` (`lib/widgets/file_list_widgets.dart` line 36-44): 复用 toast 工具
- 会员卡联动模式 (`me_profile_screen.dart` line 237-330): 作为侧边栏联动的参考实现

## 验证方法

```powershell
# 1. 静态分析
cd c:\Users\LSM\Documents\Code\flutter-app-tlx\talix_companion_flutter
flutter analyze

# 2. 编译检查 (Windows 桌面)
flutter build windows --debug
```

**手动点击验证路径** (启动应用后):

1. **侧边栏入口** (基础版状态):
   - 看左下角 `Talix 基础版` 卡片 → 点击 `升级` 胶囊按钮 → 出现全屏升级页面 (AppBar 标题 `升级订阅`)
   - 点 AppBar 返回箭头 → 回到 MainFrame, tab 状态未改变

2. **我的页面入口**:
   - 点侧边栏 `我的` → 点 `升级至专业版` 行 → 出现全屏升级页面 (同样 UI)
   - 返回 → 回到 `我的` 主页
   - 点会员卡右侧 `免费试用升级版` 按钮 → 同样 push 升级页

3. **购买流程**:
   - 进入升级页 → 选套餐 (默认 `专业版`) + 付费方式 (默认 `年付`)
   - 点 `购买` → toast `💳 正在加载安全收银台...` → 1200ms 后 toast `🎉 订阅成功!` → 自动 pop 回到来源页

4. **侧边栏联动验证**:
   - 升级成功后 → 回到 MainFrame → 看到侧边栏升级卡**已自动变为 Pro 版**:
     - 标题: `Talix Pro 专业版`
     - 进度条: 满格 (widthFactor 1.0)
     - 描述: `专业级 AI 会员 • 无限次极速转写`
   - 进入 `我的` → 会员卡也联动显示 Pro 版 (验证状态共享)

5. **MeProfile tab 状态保持**:
   - 在 `我的` 页打开 `账号编辑` (me-02) → 切回 MainFrame → 点侧边栏 `升级` 按钮 → 升级页 pop 后 → 回到 me-02 (而不是 me-01)

6. **退出登录**:
   - 验证 `_ownsViewModel` 标志: 直接 push `MeProfileScreen()` (无 viewModel) 时仍可独立创建/销毁 VM, 向后兼容

## 风险点

1. **VM 持有者变更**: 原来 `MeProfileScreen` 自管 VM, 现在由 `MainFrame` 持有. 通过 `_ownsViewModel` 标志实现向后兼容, 单独 push `MeProfileScreen()` 仍能工作.
2. **侧边栏卡硬编码**: 进度条 0.25 / 描述 `剩余220/800分钟` 改为基于 `isPremiumUser` 动态切换, 实际数据 (分钟数) 仍硬编码, 如要接入真实数据需后续迭代.
3. **Pro 版 "升级" 按钮**: 仍叫 `升级` 文案 (点击后进入升级页, Pro 用户可切换到 `卓越版`), 不增加新文案避免状态判断复杂度.
4. **返回行为**: `Navigator.pop` 依赖 `context` 来源, 由于 push 来自 `MeProfileScreen` 或 `MainFrame`, pop 后都正确回到原页面.
