# BiliAudio 开发进度总结

## 已完成功能 (226 tests, 0 warnings, 0 errors)

### 基础架构 (M0)
- ✅ M0.3: Drift 数据库 (9表4DAO, 外键约束, 用户编辑分离)
- ✅ M0.4: 应用外壳 (go_router, 主题控制, 桌面窗口, 系统托盘)

### 数据层 (M1-M2)
- ✅ M1.3: 标题清洗器 + 规则配置加载
- ✅ M1.6: 播放队列 (顺序/循环/随机/智能随机, 持久化)
- ✅ M1.7: LRU 淘汰策略
- ✅ M2.1: 网络客户端 (Header/Cookie/Wbi/限频/重试/错误映射)
- ✅ M2.2: 搜索API (HTML清洗, 时长解析, 15分钟过滤)
- ✅ M2.3: 视频详情API (多分P, >15min过滤)
- ✅ M2.4: 音频流地址API (音质选择, 访客132K上限, 备用URL)
- ✅ M2.5: 流地址管理器 (10分钟过期边界, 并发去重, CDN 403刷新)
- ✅ M2.6: 仓储层 (Bili + Fake实现, 标题清洗集成, 用户编辑保护)
- ✅ M2.7: 风控降级 (3次/分钟→60秒冷却, -412退避重试, guarded请求)

### 缓存与播放 (M3)
- ✅ M3.1/M3.3/M3.4: AudioHandler + 队列集成
  - AudioEngine 抽象隔离 just_audio 平台依赖
  - 只加载当前曲, 预解析下一首地址
  - 二次播放已缓存曲目: 0 网络请求
  - 单曲循环手动切歌仍前进
  - 随机模式按历史回退
  - 队列快照 500ms防抖写入, 启动恢复不自动播放
- ✅ M3.2: 音频缓存下载
  - CacheDownloadTask: 顺序写.tmp, Range断点续传
  - CDN 403时刷新地址后重试
  - 播放端通过read()跟随已下载部分实现边听边存
  - CacheDownloadManager: 同cacheKey只存在一个任务
  - CachingStreamAudioSource: 缓存命中直接读文件, 否则流式返回并后台写满
- ✅ M3.5: 缓存配置 (自定义目录, 迁移工具)
- ✅ M3.6: 定时停止 (倒计时 + 播完当前/下一首)

### 平台集成 (M4)
- ✅ M4.1: Android (AudioServiceActivity, 前台服务, minSdk 26)
- ✅ M4.2: iOS (后台音频), macOS (网络entitlement)
- ✅ M4.3: Windows (media_kit + SMTC媒体控制)
- ✅ D3: Linux media_kit (MPRIS延后: dbus版本冲突)

## 待实现功能

### M6 UI (需 Riverpod 提供商层 + 各功能页面)
- [ ] **providers.dart**: 全局依赖注入
  - `dbProvider`, `httpProvider`, `titleCleanerProvider`
  - `searchRepoProvider`, `videoRepoProvider`, `streamManagerProvider`
  - `audioHandlerProvider` (需在main中初始化AudioService后覆盖)
  - `currentTrackProvider`, `playbackStateProvider`
- [ ] **features/search**: 搜索页面
  - 关键词输入 + 搜索结果列表
  - 点击曲目→解析视频详情→setTracks开始播放
  - 超长视频过滤提示
- [ ] **features/player**: 播放器页面
  - 封面、进度条、播放控制 (播放/暂停/上一曲/下一曲)
  - 歌曲信息 (歌名/歌手/时长/BV号)
  - 播放模式切换 (顺序/循环/随机)
  - 队列管理 (查看/删除/重排)
- [ ] **features/library**: 本地库 (播放列表管理)
- [ ] **features/history**: 播放历史
  - `HistoryDao.recordPlay(bvid, cid, position, completion)` (handler集成)
  - 历史列表展示 + 续播
- [ ] **features/settings**: 设置页面
  - 默认音质选择
  - 缓存上限/自定义目录 + 迁移进度UI
  - 主题色/模式切换 (已有controller, 需UI)
  - 清洗规则禁用管理
- [ ] **features/cache**: 缓存管理
  - 已缓存列表 + 大小展示
  - 批量清理/批量缓存
  - 空间不足提示 (overQuota)
- [ ] **widgets/mini_player**: 底部迷你播放器
  - 封面 + 歌名/歌手 + 播放/暂停/下一首
  - 点击展开到播放器页面

### 其他待办
- [ ] **i18n**: l10n.yaml + ARB文件 (M0.4要求所有文案走ARB)
- [ ] **Windows SMTC**: WindowsMediaBridge接入main (监听playbackState同步)
- [ ] **错误处理**: UI展示handler.errors流 (登录需求/风控冷却)
- [ ] **登录模块**: Cookie管理 + 扫码登录 (需访问高音质时提示)
- [ ] **网络连接检测**: connectivity_plus集成, 离线提示
- [ ] **桌面媒体键**: macOS MPRemoteCommandCenter (需手动实现)
- [ ] **Linux MPRIS**: audio_service_mpris (需解决dbus冲突或换connectivity检测库)

## 技术债务与风险
1. **StreamAudioSource实验性API**: 已标注D5, 需跟进just_audio升级回归测试
2. **MPRIS与connectivity_plus冲突**: dbus 0.7 vs 0.8版本不兼容
3. **Windows SMTC未接入**: 代码已写未在main中初始化
4. **无i18n**: 当前硬编码中文, 需迁移到ARB
5. **无登录态**: 高音质功能受限, 需扫码登录模块
6. **缺UI集成测试**: 现有226个单元测试, 无widget/integration测试

## 文件统计
- **Dart代码**: ~100个文件
- **单元测试**: 226 passed
- **分析警告**: 0 (experimental_member_use已文档化抑制)
- **Git提交**: 26 commits

## 下一步优先级
1. **providers.dart** + **mini_player**: 打通播放基础交互
2. **search页面**: 实现搜索→播放闭环
3. **player页面**: 完整播放控制界面
4. **settings页面**: 暴露已有后端配置能力
5. **i18n迁移**: 提取硬编码文案到ARB
6. **登录模块**: Cookie持久化 + 扫码登录

---
Generated: 2024-01-XX
Tests: `flutter test` → 226 passed
Analyze: `flutter analyze` → No issues found
