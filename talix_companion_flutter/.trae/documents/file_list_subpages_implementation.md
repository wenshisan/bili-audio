# 文件列表子页面功能实现计划

## Context（背景）

**问题**：当前 `lib/screens/file_manager.dart` 已实现文件列表的基础三栏布局（侧边栏 + 368px 列表 + 详情面板），并通过 `deviceFilter` 状态切换 `全部 / Jay's AI Note / Talix AI Note / 回收站` 四个视图，列表项支持 normal / selected / edit-mode 三种状态。然而与 Figma 设计 node `1218:4159` 中展示的「文件列表子页面」相比，仍缺少以下关键功能：

1. 每个文件项缺少 `更多` 菜单（重新转写 / 重命名 / 分享 / 导出 / 移至回收站）
2. 文件项缺少 `状态徽标`（转写中 / 已完成 / 失败 / 等待同步）
3. 缺少二级 `子标签筛选`（全部 / 转写中 / 已完成 / 失败）
4. 缺少 `搜索框`（按标题实时过滤）

**目标**：基于 Figma 设计 `1218:4159` 中的 24 个子页面框架，更新文件列表、补齐上述 4 个子页面功能，并抽取共享 widgets 复用至 `transcription_detail_screen.dart`，避免代码重复。

**预期成果**：用户在文件列表中点击任一文件项的 `⋮` 按钮即可弹出与详情页一致的操作菜单；状态/筛选/搜索体验与 Figma 设计 1:1 对齐。

---

## 关键文件

| 文件 | 类型 | 说明 |
|---|---|---|
| [file_manager.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/screens/file_manager.dart) | 修改 | 主入口，新增子页面状态/回调/Modal 渲染 |
| [transcription_detail_screen.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/screens/transcription_detail_screen.dart) | 修改 | 复用新抽取的共享 widgets，删除重复的本地实现 |
| [file_list_widgets.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/widgets/file_list_widgets.dart) | 新建 | 共享 widgets：MoreOptionsMenu / RenameFileDialog / ReTranscribeFlow / ShareFileSheet / ExportTypeSheet / StatusBadge / FileSearchField / FileListItem / SubTabFilterChips |
| [main.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/main.dart) | 不修改 | 仅需确认 `FileManagerScreen` 集成方式不变 |

---

## 设计 Token（统一复用现有）

- 主色：`Color(0xFF262626)`（按钮、激活态）
- 文字：`#262626` / `#333333`（主）/`#737373` / `#666666`（次）/`#A1A1A1` / `#999999`（弱）
- 边框：`#E5E5E5`（细分隔）/ `#D1D1D1`（强分隔）/ `#D9D9D9`（图标占位）
- 选中背景：`#EEEEEE`
- 字体：Inter, w400 / w500 / w600 / w900
- 圆角：4（chip）/ 6（按钮）/ 8（卡片）/ 12（输入框）/ 16（卡片）/ 24（Modal）/ 32（底部 sheet）

---

## 实施步骤

### Step 1 — 抽取共享 widgets（无行为变化）

**新建** [file_list_widgets.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/widgets/file_list_widgets.dart)：

1. **MoreOptionsMenu** — 150×auto，白底圆角 16，elevation 10，含 5 项：`重新转写 / 重命名 / 分享 / 导出 / 移至回收站`（最后一项红色 + 分隔线）。
2. **RenameFileDialog** — 居中弹窗 24px padding 圆角 24，含 12px TextField + 44px 高按钮。
3. **ReTranscribeFlow** — 复用现有 frames 03–09 的 auto/custom 流程 + 4 个二级选择 + 生成进度。
4. **ShareFileSheet** — 底部 sheet 圆角 32，含 3 个 checkbox（音频 / 转写 / 纪要）。
5. **ExportTypeSheet** — 二步：先选导出类型（录音 / PDF / AI 纪要 / 思维脑图），录音则进入格式选择（MP3 / WAV / ALAC / FLAC）。
6. **StatusBadge** — 18px 高圆角 9 胶囊，按状态映射颜色（见下文）。
7. **FileSearchField** — 32px 高搜索框，含搜索图标 + 清除按钮。
8. **SubTabFilterChips** — 横向 FilterChip 列表，激活态 `#262626` 背景白色文字。
9. **FileListItem** — 71px 高列表项（封装现有 `_buildFileListItem` 逻辑），新增状态徽标 + 更多图标。

**状态徽标颜色映射**：
- 转写中：`#FFF7ED` 背景 / `#F97316` 文字 + `hourglass_top` 图标
- 已完成：`#ECFDF5` / `#10B981` + `check_circle` 图标
- 失败：`#FEF2F2` / `#EF4444` + `error_outline` 图标
- 等待同步：`#F3F4F6` / `#6B7280` + `cloud_queue` 图标

**修改** [transcription_detail_screen.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/screens/transcription_detail_screen.dart)：
- 替换 `_buildEllipsisDropdown` 为 `MoreOptionsMenu`
- 替换 `_buildRenameOverlay` 为 `RenameFileDialog`
- 替换 `_buildShareOverlay` 为 `ShareFileSheet`
- 替换 export 流程为 `ExportTypeSheet`
- 替换 re-transcribe 流程为 `ReTranscribeFlow`

**验证**：运行 app，打开文件，验证所有 Modal（rename/share/export/re-transcribe/auto/custom）行为完全一致。

### Step 2 — 扩展 `RecordingFile` 数据模型

修改 [file_manager.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/screens/file_manager.dart#L4-L20) 中的 `RecordingFile`：

```dart
String status;          // 'transcribing' | 'completed' | 'failed' | 'synced' | 'waiting'
String? sourceLabel;    // '设备储存' | '主机储存'（仅在 'all' 视图显示小 chip）
String? failureReason;  // 失败原因
String? duration;       // '56:12'
```

为 3 个 demo 列表（`_trashFiles` / `_deviceFiles` / `_phoneFiles`）中的文件赋予不同状态，确保筛选有数据可过滤。

**验证**：`flutter analyze` 通过；列表渲染无变化。

### Step 3 — 在 `FileListItem` 增加状态徽标

- 元数据行（日期 · 大小）右侧插入 `StatusBadge`。
- 当 `_activeTab == 'all'` 时，标题上方显示小 chip `设备` / `手机`。

**验证**：列表项正确显示彩色状态徽标。

### Step 4 — 添加搜索框 + 子标签筛选

在 [file_manager.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/screens/file_manager.dart) 的 `build` 方法中，tab 行与文件列表之间插入：

1. **搜索框** — 32px 高，圆角 6，含 `search_rounded` 图标 + 清除按钮，placeholder `搜索文件标题`。
2. **子标签筛选** — 横向 4 个 FilterChip：`全部 / 转写中 / 已完成 / 失败`。

新增状态字段：
```dart
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
String _activeListFilter = 'all'; // 'all' | 'transcribing' | 'completed' | 'failed'
```

`_buildFileList` 改造为同时按 `_searchQuery`（标题 contains，不区分大小写）和 `_activeListFilter` 过滤；不匹配的行 opacity 0.35。

**验证**：输入搜索词实时过滤；点击子标签正确筛选。

### Step 5 — 文件项的「更多」菜单

替换 [file_manager.dart](file:///c:/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/screens/file_manager.dart#L321-L332) 中现有的 `IconButton(Icons.delete_outline)` 为 `IconButton(Icons.more_horiz)`。

点击后在该列表项 `Stack` 内 cell-local 渲染 `MoreOptionsMenu`（避免全局锚点计算）：

```dart
return Stack(
  children: [
    _buildFileListItem(file, ...),
    if (_menuTargetFileId == file.id)
      Positioned(top: 28, right: 12, child: MoreOptionsMenu(...)),
  ],
);
```

新增状态字段：
```dart
String? _menuTargetFileId;        // 当前打开菜单的文件 id
String? _renameTargetId;
String? _shareTargetId;
String? _exportTargetId;
String? _reTranscribeTargetId;
String _reTranscribeStep;         // 'auto' | 'custom' | 'template' | ...
String _selectedTemplate = '智能纪要';
String _selectedAudioLang = '中文简体-普通话';
String _selectedAiModel = '自动';
String _selectedTranslateLang = '不翻译';
```

5 个操作回调：
- `_onReTranscribe(file)` — 打开 `ReTranscribeFlow`
- `_onRename(file)` — 打开 `RenameFileDialog`，保存后 `setState(() => file.title = newName)`
- `_onShare(file)` — 打开 `ShareFileSheet`，确认后 `_showToast('已生成分享链接')`
- `_onExport(file)` — 打开 `ExportTypeSheet`，确认后 `_showToast('已导出: ...')`
- `_onMoveToTrash(file)` — 移入 `_trashFiles`（标题加 `已删除: ` 前缀），从原列表移除，若该文件正被选中则 `_closeDetails()`

**验证**：5 个操作均能正确打开对应 Modal；移至回收站后该文件出现在回收站。

### Step 6 — 在 `build` 中组装 Stack 覆盖层

将 [file_manager.dart](file:///c:/Users/LSM/Documents/Code/flutter-app-tlx/talix_companion_flutter/lib/screens/file_manager.dart#L505-L589) 的 `Scaffold.body` 改为：

```dart
Stack(
  children: [
    Row(... 现有三栏 ...),
    if (_menuTargetFileId != null) _buildMoreOptionsMenu(),
    if (_renameTargetId != null) RenameFileDialog(...),
    if (_shareTargetId != null) ShareFileSheet(...),
    if (_exportTargetId != null) ExportTypeSheet(...),
    if (_reTranscribeTargetId != null) ReTranscribeFlow(...),
  ],
)
```

确保同一时间只有一个 Modal 打开（打开新 Modal 前清空其他 `_xxxTargetId`）。

### Step 7 — 空态差异化

修改 `_buildFileList` 中的空态：
- `全部`：保持现有 `暂无录音文件`
- `转写中`：`hourglass_top` + `没有正在转写的文件`
- `已完成`：`check_circle_outline` + `没有已完成的转写`
- `失败`：`error_outline` + `没有失败的任务`

---

## 复用现有代码

- 现有 `_buildFileListItem` 主体（file_manager.dart#L224-L337）的 71px stacked 布局 → 抽取至 `FileListItem`
- 现有 `_showDeleteConfirmation` 中的样式 → 作为新增 Modal 的样式参考
- 现有 `transcription_detail_screen.dart` 中的 22 frames 状态机 → 仅替换 Modal 实现，业务状态保留
- 现有 `_showToast`（在 detail 屏）→ 复制至 `file_list_widgets.dart` 共用

---

## 验证

### 1. 静态检查
```powershell
cd c:\Users\LSM\Documents\Code\flutter-app-tlx\talix_companion_flutter
flutter analyze
```

### 2. 编译运行
```powershell
flutter run -d windows
```

### 3. 手动验证（按 Figma 子页面逐个对照）
- [ ] 默认文件列表（无选中）— 与 Figma frame 1218:6792 一致
- [ ] 选中态高亮（#EEEEEE 背景）— 与 frame 1218:7335 一致
- [ ] 编辑模式多选 + 复选框 — 与 frame 1218:6954 一致
- [ ] 状态徽标（4 种颜色）— 与 frame 1218:7061 一致
- [ ] 子标签筛选（全部/转写中/已完成/失败）— 切换有效
- [ ] 搜索框 — 输入实时过滤
- [ ] 每行 `⋮` 菜单 — 弹出 5 项操作
- [ ] 重新转写流程 — 4 步选择 + 生成进度
- [ ] 重命名弹窗 — 保存后标题更新
- [ ] 分享底部 sheet — 3 个 checkbox
- [ ] 导出选择（类型 + 音频格式）— 两步选择
- [ ] 移至回收站 — 文件消失并出现在回收站
- [ ] 详情页 Modal（rename/share/export/re-transcribe）— 与列表中行为一致（验证共享 widgets 复用成功）

### 4. 回归测试
- 三栏布局在 `>=750px` 窗口正常
- 移动端窄屏布局（bottom nav）下文件列表仍可访问
- 切换 deviceFilter（全部 / Jay's / Talix / 回收站）状态保持
- 删除多选文件弹窗仍工作（保留现有 `_showDeleteConfirmation` 或替换为新 Modal）
