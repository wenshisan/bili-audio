# Agent skills

Cursor 和 Claude 共用同一批 skill。正文在 `.claude/skills/`，已纳入 Git。`.cursor/skills` 是指向这个目录的 Windows 目录联接，不单独保存一份副本。

在本机改 `.claude/skills` 或 `.cursor/skills` 都会改到同一批文件。不要把 skill 再复制到另一边。

## 换电脑

联接不会跟着仓库走。

- `.claude/skills/` 里的 skill 文件在 Git 中，克隆后还在。
- `.cursor/skills` 写在 `.gitignore` 里。它记录的是本机绝对路径（当前为 `D:\Code\flutter-app-deep\.claude\skills`），换盘符或换目录后失效。
- 只拷贝项目文件夹也不要依赖这条联接。路径变了就会断；资源管理器拷贝时还可能把它变成普通目录。

新电脑克隆下来之后，在仓库根目录执行一次：

```powershell
powershell -File scripts/link-cursor-skills.ps1
```

脚本按那台电脑上的仓库位置重新建立联接。

如果 `.cursor/skills` 已经是普通目录，脚本会停下来，避免盖掉或删掉 `.claude/skills`。先删掉这个普通目录，再运行脚本。

这条脚本使用 `mklink /J`，只适用于 Windows。

`scripts/link-cursor-skills.ps1` 和 `.cursor/rules/shared-skills.mdc` 需要提交进仓库，新电脑上才有重建命令和同步约定。联接本身不要提交。
