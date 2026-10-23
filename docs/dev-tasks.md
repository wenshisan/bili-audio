# bili-audio · 开发任务拆分（技术版）

> 依据 `README.md`（PRD）拆分。任务按“依赖先行、纯逻辑先行、可验证先行”排序，而非按 PRD 章节顺序。

## 0. 约定

- **任务编号**：`M{里程碑}.{序号}`，如 `M1.3`。
- **估时**：单人日（d），含单元测试，不含联调等待。
- **完成定义（DoD）**：`flutter analyze` 0 warning；新增逻辑有单测；`domain/` 下模块覆盖率 ≥ 90%；在 Android + Windows 至少各跑通一次。
- **分支**：`feat/M{x}.{y}-short-name`，一个任务一个 PR。
- **Agent skills**：正文在 `.claude/skills`，Cursor 通过目录联接读取。换电脑后的重建方式见 `docs/skills.md`。

## 1. 关键技术决策（含对 PRD 的澄清）

| # | 议题 | 决策 | 原因 |
| --- | --- | --- | --- |
| D1 | 登录方式 | 使用 **Web 扫码**（`qrcode/generate` + `qrcode/poll`），而非 TV 端 | PRD 描述的 `qrcode_key` 与 SESSDATA/bili_jct Cookie 属于 Web 流程；TV 流程返回 access_key，需 APP 签名 |
| D2 | 音质档位映射 | 64K=30216，132K=30232，192K=30280，Dolby=30250，Hi-Res=30251 | B 站 DASH 无独立 320K 档，PRD 的 “320K” 映射为 Hi-Res/无损档 |
| D3 | 桌面端媒体控制 | Android/iOS/macOS 用 `audio_service`；Linux 用 `audio_service_mpris`；Windows 用 `smtc_windows` 自行桥接 | `audio_service` 官方不支持 Windows |
| D4 | 桌面端播放后端 | Windows/Linux 使用 `just_audio_media_kit` | just_audio 官方无 Windows/Linux 实现 |
| D5 | 边听边存 | 不直接依赖 `LockCachingAudioSource`（实验性 API），自研 `CachingStreamAudioSource`（继承 `StreamAudioSource`），落盘 + 索引写 drift | 需要精确控制缓存路径、完整性校验、LRU 与“已收藏”保护；同时需携带 Referer 头 |
| D6 | 繁简转换 / 拼音 | 内置字符映射表（构建期从 OpenCC 词典生成 `assets/dict/t2s.txt`）+ `lpinyin` | 避免 FFI/原生依赖，纯 Dart 可单测 |
| D7 | 状态管理 | Riverpod 2 + `riverpod_generator`；实体用 `freezed` + `json_serializable` | 统一代码生成链路 |
| D8 | 播放队列 | 自研 `PlaybackQueue`（纯 Dart），播放器每次只加载**当前 + 下一首**两个 source | 不使用 `ConcatenatingAudioSource` 的 shuffle；便于随机回退与持久化 |
| D9 | Doze 豁免 | 只引导用户去系统设置，不主动申请 `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | 该权限有应用商店政策风险 |
| D10 | 歌词时间单位 | 全链路使用 `Duration`，LRC 解析精度到 ms | 偏移量步进 0.1s，避免浮点误差 |
| D11 | 依赖版本 | M0.1 时用 `flutter pub add` 取当时稳定版，写成精确版本（不用 `^`），并提交 `pubspec.lock` | 可复现构建；本文不预设版本号 |
| D12 | 在线升级 | 升级源是 GitHub 上版本号最高的非预发布 Release。推送到 main 会自增构建号并发布 `vX.Y.Z+N`。安装包文件名见 `docs/release.md` | 预发布 `continuous` 只给介绍页提供固定下载地址 |

## 2. 工程结构

```
lib/
├── main.dart                      # 初始化：DB、AudioHandler、ProviderScope
├── app/                           # MaterialApp.router、go_router 路由表、主题
├── core/
│   ├── network/                   # Dio 工厂、拦截器（Cookie/Referer/UA/WBI/限频/重试）
│   ├── storage/                   # 路径管理、SecureStore 封装
│   ├── logging/                   # logger（仅本地）
│   └── utils/                     # Result<T>、debounce、文件工具
├── domain/                        # 纯 Dart，禁止 import flutter
│   ├── entities/                  # Video, Track, Lyrics, Playlist, PlayMode...
│   ├── title/                     # TitleCleaner + 规则模型
│   ├── lyrics/                    # LrcParser, Similarity, LyricsScorer, LyricsProvider 接口
│   ├── queue/                     # PlaybackQueue, ShuffleStrategy
│   └── cache/                     # LruPolicy（纯算法）
├── data/
│   ├── bili/                      # BiliApi（search/view/playurl/login/fav/space/subtitle）
│   ├── lyrics/                    # LrclibProvider, BiliSubtitleProvider, LocalLrcProvider
│   ├── db/                        # drift 表定义、DAO、迁移
│   ├── audio/                     # CachingStreamAudioSource、StreamUrlResolver
│   └── repositories/              # 组合 API + DB 的仓储实现
└── features/
    ├── search/  player/  lyrics/  queue/  library/  settings/  account/  cache/
    └── (每个 feature：providers/  pages/  widgets/)
test/
├── domain/                        # 纯逻辑单测
├── data/                          # 用 http_mock_adapter 回放 API 响应
└── fixtures/
    ├── bili/                      # 录制的接口 JSON（脱敏）
    └── title_cases.csv            # “原始标题 → 歌名/歌手”回归集（≥ 200 条）
```

依赖方向：`features → data → domain`，`core` 被所有层使用；`domain` 不依赖任何其他层。

## 3. 数据模型（核心实体）

```dart
// domain/entities/track.dart
@freezed
class Track with _$Track {
  factory Track({
    required String bvid,
    required int cid,           // 分P标识
    required String title,      // B 站原始标题
    String? cleanedName,        // 清洗后歌名
    String? artist,             // 清洗后歌手
    required Duration duration,
    String? cover,
    String? uploader,
    int? pageIndex,             // 分P序号（1-based）
    int? totalPages,            // 总分P数
  }) = _Track;
  
  String get displayTitle => cleanedName ?? title;
  String get displayArtist => artist ?? uploader ?? '未知';
  String cacheKey(AudioQuality quality) => '${bvid}_${cid}_${quality.id}';
}

// domain/entities/lyrics.dart
@freezed
class Lyrics with _$Lyrics {
  factory Lyrics({
    required List<LyricLine> lines,
    @Default(Duration.zero) Duration offset,  // 用户校准偏移
    String? source,
    double? matchScore,
  }) = _Lyrics;
}

@freezed
class LyricLine with _$LyricLine {
  factory LyricLine({
    required Duration timestamp,
    required String text,
    String? translation,
  }) = _LyricLine;
}

// domain/queue/playback_queue.dart
enum PlayMode { sequential, listLoop, singleLoop, shuffle, smartShuffle }

class PlaybackQueue {
  List<Track> _original;           // 用户添加顺序
  List<Track> _current;            // 当前顺序（可能已打乱）
  int _index = 0;
  PlayMode _mode;
  List<int> _playHistory = [];     // 随机模式下记录播放过的索引

  Track? get current => _index < _current.length ? _current[_index] : null;
  Track? next();       // 根据 mode 计算下一首
  Track? previous();   // 支持随机回退
  void shuffle(ShuffleStrategy strategy);
  void setMode(PlayMode mode);
  Map<String, dynamic> toJson();   // 持久化
  static PlaybackQueue fromJson(Map<String, dynamic> json);
}
```

drift 表（M0.3 建立，后续只做增量迁移）：

| 表 | 主键 | 关键字段 |
| --- | --- | --- |
| `tracks` | `bvid, cid` | 原始标题、清洗结果、`user_edited`、时长、封面、UP 主、分P序号 |
| `playlists` / `playlist_tracks` | `id` / `playlist_id, bvid, cid` | 名称、封面、排序 `position`、`added_at` |
| `play_history` | `id` | `bvid, cid, played_at, position_ms, completion`、来源 |
| `lyrics_cache` | `bvid, cid` | LRC 文本路径、来源、得分、`offset_ms`、`no_lyrics` 标记 |
| `cache_index` | `cache_key` | 文件路径、大小、`complete`、`cached_at`、`last_played_at`、`pinned` |
| `stream_urls` | `bvid, cid, quality` | URL、备用 URL、`expires_at` |
| `queue_snapshot` | 单行 | 原始/当前队列 JSON、索引、模式、随机种子、播放位置 |
| `settings` | `key` | 简单 KV（主题、缓存上限、默认音质等） |

## 4. 里程碑与关键路径

| 里程碑 | 内容 | 估时 | 可演示结果 |
| --- | --- | --- | --- |
| M0 | 工程基建 | 3d | 空壳 App 多端启动，主题切换 |
| M1 | 领域核心（纯 Dart） | 7d | 标题清洗、评分、队列单测全绿 |
| M2 | B 站数据接入 | 6d | 集成测试中搜索 → 取分P → 取音频流 |
| M3 | 播放引擎 + 边听边存 | 6d | 播放一首歌，二次播放 0 网络请求 |
| M4 | 后台播放与系统集成 | 5d | 锁屏/通知栏/媒体键控制 |
| M5 | 歌词接入 | 4d | 播放时自动匹配 LRCLIB 歌词并校准 |
| M6 | 界面与本地库 | 8d | 搜索、播放页、队列、歌单、历史完整流程 |
| M7 | 扫码登录与按需登录 | 3d | 登录后解锁高音质，未登录无弹窗 |
| M8 | MVP 稳定性与发布 | 4d | 验收指标自测报告、多端安装包 |
| | **v0.1 合计** | **46d** | |

并行泳道（2 人时约 28 个工作日）：

```
泳道 A（逻辑/播放）: M0 ─ M1 ──────── M3 ─ M4 ─ M5 ─┐
泳道 B（数据/界面）:      M2 ───── M7 ─ M6 ─────────┴─ M8
```

关键路径：`M0 → M2.3(playurl) → M3.2(缓存音频源) → M4.1(AudioHandler) → M6.3(播放页) → M8`。M1 与 M2 无依赖可并行；UI（M6）可先用 fake repository 开发。

---

## M0 · 工程基建（3d）

### M0.1 工程初始化（0.5d）
- `flutter create --org <org> --platforms android,ios,windows,macos,linux bili_audio`
- 按 D11 引入依赖；配置 `build.yaml`、`analysis_options.yaml`（`flutter_lints` + `strict-casts`、`strict-raw-types`）
- 生成代码（`*.g.dart`、`*.freezed.dart`）**入库**，CI 校验 `build_runner build` 后无 diff
- Android：`minSdk 26`（PRD 要求 8.0+）；iOS：`14.0`；macOS：`12.0`
- **验收**：五端 `flutter build` 通过（iOS/macOS 在 CI 的 macOS runner 上）

### M0.2 CI（0.5d）
- GitHub Actions：`analyze` → `test --coverage` → `domain/` 覆盖率门槛 90%
- 矩阵构建：ubuntu（android apk、linux）、windows、macos（ios no-codesign、macos）
- **验收**：PR 自动跑完全部检查

### M0.3 本地存储（1d）
- `AppDatabase`：创建第 3 节全部表，`schemaVersion = 1`，开启 `drift` 迁移测试（`drift_dev schema dump`）
- `PathManager`：`audio/`、`covers/`、`lyrics/` 子目录；缓存根目录可配置（为 M3.5 自定义路径预留）
- `SecureStore`：封装 `flutter_secure_storage`，只暴露 `readCookies/writeCookies/clear`
- **验收**：DAO CRUD 单测；内存数据库（`NativeDatabase.memory()`）跑通

### M0.4 应用壳（1d）
- `go_router` 路由：`/`（底部导航：发现/歌单/我的）、`/search`、`/player`、`/lyrics`、`/queue`、`/playlist/:id`、`/settings/*`
- 底部常驻迷你播放栏（`ShellRoute`），占位实现
- 主题：`ColorScheme.fromSeed`，预设 6 套种子色 + 跟随系统/浅/深，持久化到 `settings`
- `flutter_localizations` + ARB 骨架（zh-Hans 先行，所有文案从第一天起走 ARB，v1.0 只补翻译）
- **验收**：切换主题与种子色实时生效并在重启后保持

---

## M1 · 领域核心，纯 Dart（7d，可与 M2 并行）

### M1.1 实体与基础类型（0.5d）
- `Video`（bvid、标题、UP、封面、统计、tags、`List<Page>`）、`Page`（cid、分P标题、时长）、`Track`、`Lyrics`、`Playlist`、`AudioQuality`（枚举含 DASH id）
- `Result<T>` / `AppError`（sealed：`Network`、`NeedLogin`、`RiskControl(-412)`、`Copyright`、`NotFound`、`Unknown`）
- **验收**：`freezed` 相等性、JSON 往返单测

### M1.2 文本归一化（0.5d）
- `normalizeForMatch(String)`：全角→半角、繁→简（D6 映射表）、小写、折叠空白、去标点
- `toPinyin(String)`：`lpinyin` 无声调拼音，非中文原样保留
- `normalizeForDisplay(String)`：只做全角→半角与空白折叠，**不做**繁简转换（PRD：显示保持原文）
- **验收**：单测覆盖中日英混排、emoji、全角符号

### M1.3 标题清洗 `TitleCleaner`（2d）
规则文件 `assets/config/title_cleaning_rules.json`：

```json
{
  "version": 1,
  "rules": [
    { "id": "bracket_quality", "type": "remove", "pattern": "[【\\[(（「](?:Hi-?Res|无损|FLAC|320K|DSD)[^】\\])）」]*[】\\])）」]", "enabled": true },
    { "id": "no_lyrics", "type": "flag", "pattern": "伴奏|纯音乐|Instrumental", "flag": "noLyrics" },
    { "id": "sep_dash", "type": "split", "pattern": "\\s[-—]\\s", "order": "title_artist", "priority": 10 }
  ]
}
```

- 规则类型：`remove`（删除匹配内容）、`flag`（打标记）、`split`（拆分歌名/歌手，带优先级和顺序）、`extract`（如 `《(.+?)》`）
- 处理管线：`flag` → `remove`（括号类、前后缀）→ `extract`/`split`（按 priority）→ 规范化 → 兜底
- 兜底链：分P标题（多P且分P标题非 `P1` 类占位）→ tags 中命中的歌手/歌名 → UP 主作为候选歌手
- 输出 `CleanedTitle { name, artist?, artistCandidates, flags, appliedRuleIds }`，保留 `appliedRuleIds` 便于调试与设置页展示
- 用户可禁用的规则通过 `disabledRuleIds` 参数传入，`TitleCleaner` 本身无状态
- 左右顺序判定：分隔符两侧若一侧命中 tags 或已知歌手词表，则该侧为歌手；否则按规则 `order`
- **验收**：
  - PRD 3.1.3 的 5 条示例全部通过
  - `test/fixtures/title_cases.csv` 首批 ≥ 100 条（M8 前补到 ≥ 200），歌名准确率 ≥ 90%
  - 覆盖率 ≥ 90%

### M1.4 LRC 解析（0.5d）
- 支持 `[mm:ss]`、`[mm:ss.xx]`、`[mm:ss.xxx]`、单行多时间戳、`[offset:+/-ms]`、元数据标签
- 逐字歌词：增强 LRC `<mm:ss.xx>` 词级时间戳，解析为 `List<LyricWord>`（v0.3 渲染，解析器 v0.1 就支持）
- 同时间戳的两行合并为“原文 + 翻译”
- `LyricsTimeline.indexAt(Duration position, Duration offset)`：二分查找当前行
- **验收**：畸形 LRC（乱序、空行、无时间戳行）不抛异常

### M1.5 相似度与评分 `LyricsScorer`（1.5d）
- `titleSim = max(1 - lev/maxLen, jaccard(tokens))`；中文串额外算拼音相似度，取最大值
- 分词：中文按字、拉丁按空白/标点，tokens 先过 `normalizeForMatch`
- `artistSim`：双方按 `、` `&` `,` `feat.` `ft.` `x` 拆分后取两两最大值
- `durationSim = max(0, 1 - |Δt| / 10s)`
- `score = 0.55·title + 0.25·artist + 0.20·duration`；歌手缺失时 `score = 0.80·title + 0.20·duration`
- `MatchDecision`：`auto (≥0.80)` / `uncertain (0.60–0.80)` / `manual (<0.60)`，阈值作为参数便于调参
- 回归评估脚本 `tool/eval_lyrics_match.dart`：读取标注集，输出准确率/误匹配率/阈值曲线
- **验收**：边界值单测（0.60、0.80、Δt=10s）；覆盖率 ≥ 90%

### M1.6 播放队列 `PlaybackQueue`（1.5d）
- 状态：`original`、`order`（索引排列）、`cursor`、`mode`、`seed`、`history`（实际播放过的索引栈）
- 基础随机：Fisher–Yates，当前曲目固定在 `order[0]`；一轮耗尽后用 `seed+1` 重新打乱，并避免新一轮首曲与上轮末曲相同
- 智能随机：贪心加权抽样，权重 `w = base × (同歌手紧邻 ? 0.1 : 1) × recencyPenalty(最近 N 首)`，种子化 `Random` 保证可复现
- 分P连续：随机单元为“视频分组”，组内保持分P顺序
- `previous()`：随机模式下从 `history` 回退，而不是 `cursor-1`
- 模式切换：→随机时以当前曲为首重建 `order`；→顺序时 `cursor` 定位到当前曲在 `original` 中的位置
- 编辑：`insertNext`、`append`、`removeAt(s)`、`reorder`（随机模式下拒绝并返回错误）、`clearExceptCurrent`
- `toSnapshot()/fromSnapshot()`：恢复后 `current` 与快照一致
- **验收**：PRD 第 8 节“播放模式正确性”4 条全部写成单测；智能随机 1 万次模拟同歌手连续率 < 10%

### M1.7 LRU 策略 `LruPolicy`（0.5d）
- 输入：条目列表（大小、`lastPlayedAt`、`pinned`）+ 上限 + 待写入大小
- 输出：待删除条目，跳过 `pinned`（歌单内歌曲）与当前播放/正在下载项
- pinned 总量超上限时不删除，返回 `overQuota` 供 UI 提示
- **验收**：单测覆盖空间刚好够、全部 pinned、并发写入预留空间

---

## M2 · B 站数据接入（6d，依赖 M0）

> 所有接口在 `data/bili/` 内隔离，对外只暴露仓储接口；接口响应录制为 fixture，单测离线运行。

### M2.1 网络客户端（1.5d）
- `BiliHttp`：Dio 单例，拦截器顺序：`Header`（UA、`Referer: https://www.bilibili.com`）→ `Cookie`（登录 Cookie + `buvid3`/`buvid4`）→ `Wbi`（按接口标注自动签名）→ `RateLimit`（令牌桶，默认 5 req/s）→ `Retry`（网络错误指数退避，最多 3 次）→ `ErrorMapper`
- `buvid`：首次启动调用 `/x/frontend/finger/spi` 获取 `b_3`/`b_4`，失败时本地生成兜底，持久化
- WBI：从 `/x/web-interface/nav` 的 `wbi_img` 取 `img_key`/`sub_key`，按 64 位混淆表生成 `mixin_key`（取前 32 位）；参数排序、过滤 `!'()*`、追加 `wts`，`w_rid = md5(query + mixin_key)`；key 缓存 24h，签名失败（-403/-352）时强制刷新一次
- `ErrorMapper`：`code` 映射到 `AppError`：`-101 → NeedLogin`，`-403 → NeedLogin/Forbidden`，`-412/-352 → RiskControl`，`-404/62002 → NotFound`，`87008/版权 → Copyright`
- **验收**：WBI 签名对照已知向量单测；拦截器链用 `http_mock_adapter` 测试

### M2.2 搜索（1d）
- `GET /x/web-interface/wbi/search/type?search_type=video&keyword&page&tids`
- 分区：默认 `tids=3`（音乐主分区）；PRD 中的 `28` 是“原创音乐”子分区，作为可选筛选项，设置页可配置分区列表
- 结果清洗：`title` 去除 `<em class="keyword">` 标签并反转义 HTML 实体；`duration` 为 `m:ss` 字符串需解析
- 时长过滤：> 15min 的条目标记 `filtered=true`（UI 灰显或隐藏，由设置决定），不在仓储层直接丢弃
- 分页：`SearchPager`，到达 `numPages` 停止；-412 时退避 2s 重试一次，仍失败返回 `RiskControl`
- **验收**：fixture 回放；过滤边界（15:00 保留，15:01 过滤）

### M2.3 视频详情与分P（0.5d）
- `GET /x/web-interface/view?bvid` → `pages[]`（cid、part、duration）、`owner`、`pic`、`stat`
- `GET /x/tag/archive/tags?bvid` → tags（供 M1.3 兜底），失败不阻塞
- 分P逐个按 ≤ 15min 过滤；全部被过滤则视频不可播放
- 结果写入 `tracks` 表（含 `TitleCleaner` 结果，`user_edited=true` 的记录不覆盖）
- **验收**：单P、多P、部分分P超长三类 fixture

### M2.4 音频流解析（1d）
- `GET /x/player/wbi/playurl?bvid&cid&fnval=4048&fnver=0&fourk=1`
- 候选：`dash.audio[]` + `dash.dolby.audio[]` + `dash.flac.audio`，按 D2 的 id 排序
- 选择策略：`min(用户偏好, 账号可用最高档)`；未登录上限 132K（PRD 的 128K 档）；请求更高档且未登录时返回 `NeedLogin(reason: highQuality)`，由 UI 决定是否弹登录
- 输出 `StreamInfo { url, backupUrls, quality, mime, bandwidth, expiresAt }`；`expiresAt` 从 URL 的 `deadline` 参数解析，缺失时按 `now + 110min`
- **验收**：未登录/已登录/大会员三种 fixture 选择正确档位

### M2.5 流地址管理 `StreamUrlResolver`（1d）
- 读写 `stream_urls` 表；`expiresAt - 10min` 内视为过期
- `resolve(track, quality)`：缓存完整命中时**直接返回本地文件，不请求网络**（PRD 3.5.4）
- `refresh(track)`：同一 track 的并发刷新合并为一个请求（`Map<key, Future>`）
- CDN 403 / 连接失败：依次尝试 `backupUrls`，全部失败再 `refresh` 一次
- **验收**：过期刷新、并发合并、备用地址切换单测

### M2.6 仓储与假实现（0.5d）
- 接口：`SearchRepository`、`VideoRepository`、`StreamRepository`
- `Fake*Repository`：读取 fixture，供 M6 UI 在 M2 完成前开发
- fixture 录制脚本 `tool/record_fixture.dart`：真实请求后脱敏（去除 Cookie、mid）再保存

### M2.7 风控降级（0.5d）
- 全局 `RiskControlGuard`：短时间内 -412 ≥ 3 次进入冷却（60s），冷却期搜索直接返回提示，播放已缓存内容不受影响
- 记录风控事件到本地日志，便于后续调整限频
- **验收**：模拟连续 -412，进入冷却后不再发请求

---

## M3 · 播放引擎 + 边听边存（6d，依赖 M2.3）

### M3.1 AudioHandler 基础（1d）
- `BiliAudioHandler extends BaseAudioHandler`：集成 `audio_service`
- 控制：`play/pause/seek/skipToNext/skipToPrevious/stop/setSpeed/setRepeatMode/setShuffleMode`
- 状态：`PlaybackState`（播放/暂停/缓冲/错误、位置、速度、队列索引），`MediaItem`（当前 track 封面/标题/艺人/分P信息/时长）
- 暂不处理队列（M3.4 集成），仅处理单曲播放
- Android 前台服务：`AndroidConfig(notificationChannelId, notificationId, stopForegroundOnPause=false)`
- iOS 后台音频：`Info.plist` 的 `UIBackgroundModes: audio`
- **验收**：播放一个固定 URL（网络 mp3），通知栏出现并能控制

### M3.2 边听边存 `CachingStreamAudioSource`（2d）
继承 `StreamAudioSource`，实现 `request(int start, int? end)` 钩子：

- 流程：
  1. 检查 `cache_index` 是否完整，完整则读本地文件返回
  2. 否则发送范围请求（`Range: bytes=start-end`，携带 `Referer`）到 CDN
  3. 边读边写临时文件（`.tmp`），更新 `downloaded_bytes`
  4. 完成后改名为正式文件，`complete=true` 写入 `cache_index`，顺带保存封面到 `covers/`
  5. 中断/切歌时临时文件保留，下次断点续传
- LRU 触发：写入前查询 `cache_index` 总大小，超限时调用 M1.7 的 `LruPolicy.selectEviction`，删除文件并移除索引
- Pinned 管理：`CachePinManager`，`playlist_tracks` 内的 `cache_key` 标记为 pinned
- 错误处理：CDN 403 通知 `StreamUrlResolver.refresh`，URL 更新后重新请求
- **验收**：
  - 播放 → 暂停 → 切歌 → 再播，文件完整且不重下载
  - 缓存满时自动清理最旧的未 pinned 项
  - 并发播放两首歌不互相阻塞

### M3.3 just_audio 播放器封装（0.5d）
- `PlayerService`：持有 `AudioPlayer`（桌面端用 `just_audio_media_kit`，Android/iOS 用标准实现）
- 当前只加载一首：`audioSource = CachingStreamAudioSource(...)`
- 播放完成时通知 `PlaybackQueue.next()` 并加载下一首（M3.4 集成）
- 倍速、音量、进度跳转透传
- **验收**：单曲循环播放 30 分钟无崩溃

### M3.4 队列集成（1d）
- `QueueManager`（Riverpod notifier）：持有 `PlaybackQueue`（M1.6）+ `currentTrack` + `mode`
- 操作：`setQueue(tracks, startIndex)`、`addNext`、`remove`、`reorder`、`next/previous`、`setMode`
- 每次 `next/previous` 通知 `PlayerService` 切换 `audioSource`；预加载下一首的 URL
- 模式映射：客户端 `PlayMode` 控制，传给 `just_audio` 的永远是 `LoopMode.off`（单曲循环除外）
- 持久化：每次队列变化时 debounce 500ms 写 `queue_snapshot`，包含播放位置
- 恢复：启动时读快照，`_initQueue` 标志避免自动播放
- **验收**：随机 20 首歌，"上一曲"回退路径正确；重启后队列与位置一致

### M3.5 缓存配置（0.5d）
- 设置：`cacheMaxSize`（默认 1GB）、`cacheDir`（默认 `getApplicationCacheDirectory/audio`，可自定义）
- 自定义路径：移动端弹出目录选择器（`file_picker`），桌面端文本框 + 浏览按钮
- 迁移：更改路径后提示是否迁移已有缓存（后台任务移动文件 + 更新索引）
- **验收**：自定义路径后新缓存写入新目录；迁移后旧文件可删除且播放无异常

### M3.6 定时停止（0.5d）
- `SleepTimer`：15/30/60 分钟、播完当前/下一首，倒计时
- 时间到时 `AudioHandler.pause()` + 通知 UI
- **验收**：设置 5s 定时，5s 后暂停

---

## M4 · 后台播放与系统集成（5d，依赖 M3.1）

### M4.1 Android 通知栏（1d）
- `audio_service` 自动生成通知，自定义 `MediaStyle` 布局：封面（大图）、标题、歌手、分P 序号、进度条（可拖拽）
- 通知操作：播放/暂停、上一曲、下一曲、关闭（`stop`）
- Android 13+ 运行时请求 `POST_NOTIFICATIONS` 权限
- 通知栏歌词（可选）：`setExtras({'android.media.metadata.DISPLAY_SUBTITLE': lrcLine})`，每秒更新
- **验收**：锁屏下通知栏显示完整信息，操作响应 < 0.5s

### M4.2 iOS 锁屏与控制中心（0.5d）
- `MPNowPlayingInfoCenter`：`audio_service` 自动处理，验证封面显示
- 远程控制：播放/暂停、跳转、进度条（iOS 系统控制中心）
- **验收**：iPhone 锁屏界面封面显示；进度条拖动同步

### M4.3 桌面端媒体控制（1.5d）
- **Linux**：`audio_service_mpris` 桥接 D-Bus MPRIS，状态同步到 GNOME/KDE 媒体控件
- **Windows**：`smtc_windows` 集成 `SystemMediaTransportControls`，封装 `AudioHandler` 回调到 SMTC API
- **macOS**：`audio_service` 原生支持 `MPRemoteCommandCenter`
- 媒体键：所有平台的硬件媒体键（播放/暂停、上/下曲）映射到 `AudioHandler` 方法
- **验收**：
  - Linux：`playerctl` 命令能控制播放
  - Windows：任务栏媒体浮窗显示正确，键盘媒体键有效
  - macOS：Touch Bar 媒体控件同步

### M4.4 低功耗优化（1d）
- Android Doze：`audio_service` 的前台服务自动豁免；设置页添加"电池优化豁免引导"按钮（跳转系统设置，不主动申请权限，D9）
- Wake Lock：播放时持有部分唤醒锁（`audio_service` 自动管理），暂停时释放
- 网络优化：缓存命中时不发请求；流 URL 刷新批量合并（M2.5 已实现）
- 耗电测试脚本 `tool/battery_test.dart`：播放 3 小时，读取 Android `dumpsys batterystats`
- **验收**：Android 中端机后台播放 3 小时（WiFi，屏幕关闭，1 小时 1 次切歌），电量下降 < 5%

### M4.5 稳定性测试（1d）
- 长时间播放：循环队列 50 首歌，后台播放 6 小时
- 内存监控：每 10 分钟记录 RSS/VSS，增长 < 20MB 视为通过
- 异常场景：飞行模式切换、蓝牙断连、来电中断、系统音频焦点抢占（闹钟/导航），播放自动暂停并能恢复
- **验收**：6 小时测试无崩溃，日志无 ERROR 级别记录

---

## M5 · 歌词接入（4d，依赖 M1.4/M1.5）

### M5.1 歌词提供者接口（0.5d）
```dart
abstract class LyricsProvider {
  String get name;
  int get priority;  // 数字越小越优先
  Future<List<LyricsCandidate>> search(CleanedTitle title, Duration duration);
}

class LyricsCandidate {
  final Lyrics lyrics;
  final String source;
  final String? originalTitle;
  final double matchScore;
}
```
- 按 priority 排序，依次调用 `search`，首个 `matchScore ≥ 0.80` 停止
- **验收**：抽象类单测用 mock 实现

### M5.2 LRCLIB 提供者（1d）
- `GET https://lrclib.net/api/search?track_name={name}&artist_name={artist}&duration={sec}`
- User-Agent: `Bili-Audio/{version} (contact@example.com)`（避免被反爬），DNS 回落（LRCLIB 偶尔宕机）
- 结果用 M1.5 评分，取分最高的
- 超时 5s，失败返回空列表（不阻塞本地缓存）
- **验收**：fixture 回放；匹配成功率（手工标注 20 条）≥ 75%

### M5.3 本地缓存提供者（0.5d）
- `LocalCacheProvider(priority=0)`：查询 `lyrics_cache` 表，含用户偏移量
- `no_lyrics=true` 的记录直接返回空，避免重复搜索
- **验收**：缓存命中跳过网络请求

### M5.4 歌词管理器（1d）
- `LyricsManager`：组合 `[LocalCache, Lrclib, ...]`，调度搜索
- 结果写入 `lyrics_cache`（路径、来源、得分），匹配失败且手动选择"无歌词"时写 `no_lyrics=true`
- 偏移量调整：`adjustOffset(bvid, cid, delta)`，更新 `offset_ms` 字段
- 手动选择：`setLyrics(bvid, cid, lrcPath, source: 'manual')`
- **验收**：调整偏移后重启恢复正确值；"无歌词"标记下次不搜索

### M5.5 实时同步（1d）
- `LyricsController`（Riverpod）：监听 `PlayerService.position`，每 100ms 调用 `LyricsTimeline.indexAt`
- 输出 `currentLine`/`nextLine`，触发 UI 重建
- 偏移：合并歌词自身 `[offset]` 与用户校准 `offset_ms`
- **验收**：播放测试歌曲，歌词滚动与音频误差 < 0.3s

---

## M6 · 界面与本地库（8d，可复用 Fake 仓储提前开始）

### M6.1 搜索页（1.5d）
- 顶部搜索框（防抖 500ms）+ 历史搜索（本地存储，最多 20 条）
- 结果列表：缩略图（封面 + 时长 + 分P角标）、优化后标题（`displayTitle - displayArtist`）、UP 主、播放量
- 超限条目灰显 + "超过 15 分钟"提示，可在设置中切换"完全隐藏"
- 点击：进入播放页 + 设置队列为搜索结果（从点击项开始）
- 长按：弹出菜单（加入歌单、下一首播放、查看详情）
- 加载状态：骨架屏；风控错误提示"请求过于频繁，请稍后再试"
- **验收**：搜索"周杰伦"，结果显示优化后歌名，点击播放生效

### M6.2 播放页（2d）
- 上半部：封面（圆角卡片，播放时慢速旋转）+ 分P信息（"P{n}/{total}: {pageTitle}"）
- 歌词区：全屏滚动，当前行高亮居中；点击行跳转播放位置
- 进度条：拖拽 + 时间显示（`current / total`）
- 底部控制栏：上一曲、播放/暂停、下一曲、播放模式（图标循环）、队列按钮
- 更多菜单（`...`）：倍速、定时停止、加入歌单、调整歌词偏移、查看原始标题、编辑歌名/歌手
- 调整偏移：滑块 ±5s 范围 0.1s 步进 + 快捷按钮（±0.5s）
- 编辑歌名：弹窗输入，保存后写 `tracks` 表 `user_edited=true`，清除本地歌词缓存（触发重新匹配）
- **验收**：播放一首歌，歌词同步显示；调整偏移后立即生效；编辑歌名后重启保持

### M6.3 队列页（1d）
- 当前播放区：封面 + 歌名，高亮
- 即将播放列表：`ReorderableListView`（顺序模式可拖拽，随机模式禁用）
- 滑动删除单项；批量操作（全选/清空）
- 底部：播放模式切换 + "保存为歌单"
- **验收**：拖拽排序即时生效；切换随机模式后队列重排，"上一曲"回退正确

### M6.4 歌单库页（2d）
- 标签页：本地歌单、播放历史、设置（后两者占位）
- 本地歌单：网格/列表切换，封面取首曲或自定义，显示歌曲数
- 创建歌单：输入名称，封面默认空
- 歌单详情页：
  - 顶部：封面 + 名称 + 编辑（重命名、换封面、删除歌单）
  - 列表：拖拽排序 + 滑动删除 + 长按批量操作
  - 播放全部/随机播放按钮
  - 批量缓存按钮（M3.2 后台下载任务，进度通知）
- 添加到歌单：搜索页/播放页长按 → 选择歌单 → 去重后追加
- **验收**：创建歌单 → 添加 5 首歌 → 拖拽排序 → 播放全部，队列顺序正确

### M6.5 播放历史（1d）
- 时间倒序列表，显示歌名、播放时间、完成度进度条
- 按日期分组（今天/昨天/本周/更早）
- 点击：恢复播放位置（未缓存则重新流式播放）
- 滑动删除、清空历史
- **验收**：播放 3 首歌各听一半，历史页显示 3 条记录，点击恢复位置

### M6.6 设置页（0.5d）
- 分组：账号（占位，M7 填充）、播放（音质、倍速默认、预加载）、缓存（大小、路径、自动清理）、主题（模式、种子色）、关于（版本、开源许可）
- 缓存项：当前用量/上限，"管理缓存"按钮跳转 M6.7
- **验收**：修改设置立即生效并持久化

### M6.7 缓存管理页（v0.2，此处占位 0.5d）
- 占位实现：显示"已缓存 X 首歌，共 Y MB"，清空全部按钮
- 完整实现见 v0.2.3

---

## M7 · 扫码登录与按需登录（3d，依赖 M2.1）

### M7.1 登录 API（1d）
- `POST https://passport.bilibili.com/x/passport-login/web/qrcode/generate` → `{url, qrcode_key}`
- `GET /x/passport-login/web/qrcode/poll?qrcode_key` → 轮询状态码：86101（未扫描）、86090（已扫描待确认)、86038（已过期）、0（成功，返回 `refresh_token` 等）
- 成功后提取 Cookie：`SESSDATA`、`bili_jct`、`DedeUserID`，存入 `SecureStore`
- `GET /x/web-interface/nav` 获取用户信息（昵称、头像、等级），刷新 Dio 的 Cookie
- `logout()`：清除 `SecureStore` + 重建 Dio 实例
- **验收**：真机扫码登录成功，Cookie 持久化；重启后仍处于登录态

### M7.2 登录 UI（1d）
- 设置页"账号"区域：未登录显示"点击登录"，已登录显示头像 + 昵称 + 退出按钮
- 登录页：二维码（`qr_flutter`） + 状态文字（"请用 B 站 APP 扫描" / "已扫描，请确认" / "已过期，点击刷新"）
- 轮询：500ms 间隔，页面关闭时取消；180s 超时显示过期
- 登录成功：Toast 提示，关闭页面
- **验收**：二维码显示正确，扫码后状态切换，成功后设置页显示用户信息

### M7.3 按需登录拦截（1d）
- `LoginGuard`：包装需要登录的操作（播放高音质、查看收藏夹），捕获 `NeedLogin` 错误弹窗
- 高音质弹窗："此音质需要登录，立即登录 / 继续使用低音质"
- 首次启动：无弹窗，不引导登录
- **验收**：未登录状态下搜索、播放、缓存、歌单全流程无阻；点击高音质时弹登录提示

---

## M8 · MVP 稳定性与发布（4d）

### M8.1 标题清洗回归测试（1d）
- 补充 `title_cases.csv` 至 ≥ 200 条（覆盖翻唱、日韩歌、英文歌、纯音乐）
- 运行 `tool/eval_title_cleaner.dart`，歌名准确率 ≥ 90%
- 歌手识别率 ≥ 75%（部分视频确实无歌手信息）
- 误删有效信息率 < 5%

### M8.2 歌词匹配验收（0.5d）
- 手工标注 50 首热门音乐视频的正确歌词来源（LRCLIB ID 或"无歌词"）
- 运行 `tool/eval_lyrics_match.dart`，自动匹配准确率 ≥ 85%，误匹配率 ≤ 5%
- 不确定项（0.60–0.80）需人工确认，视为合格

### M8.3 性能指标验收（1d）
- **冷启动**：`flutter run --profile --trace-startup`，从点击图标到主页显示 < 2s（中端 Android）
- **播放延迟**：搜索结果点击 → 出声，网络正常时 < 1.5s（含流 URL 请求 + 音频解码）
- **分P切换**：下一曲 → 出声 < 0.5s（URL 已预加载）
- **歌词匹配**：触发搜索 → 显示歌词 < 3s
- **内存占用**：后台播放 30 分钟，Android < 100MB，Windows < 150MB（任务管理器 Working Set）
- **缓存准确性**：播放 20 首新歌，全部自动缓存成功；二次播放网络请求数 = 0（抓包验证）
- 用 `DevTools` Timeline、Network Monitor 采集数据，输出报告

### M8.4 多端打包与发布准备（1.5d）
- **Android**：`flutter build apk --split-per-abi`，生成 arm64/x86_64 APK，签名（自签证书）
- **Windows**：`flutter build windows`，用 Inno Setup 打包安装程序
- **Linux**：AppImage 或 Flatpak（可选，先验证命令行运行）
- **macOS / iOS**：本地构建测试，签名需开发者账号（暂不分发）
- README：使用说明（登录、搜索、播放、歌词校准）、免责声明、开源协议（MIT / GPL v3 择一）
- **验收**：五端安装包能在全新环境安装并完成一次完整播放

---

## v0.2 · 完善体验（+10d）

### v0.2.1 收藏夹同步（2d）
- `GET /x/v3/fav/folder/created/list-all` + `/x/v3/fav/resource/list?media_id`
- 过滤：`type=2`（视频）且 `duration ≤ 900s`
- 同步为只读歌单（名称前缀"[B站]"），定期刷新（手动 + 启动时增量）

### v0.2.2 B 站 CC 字幕源（1d）
- `GET /x/player/wbi/v2?bvid&cid` → `subtitle.list[]`
- 下载 JSON 字幕，转 LRC（`from/to` → 时间戳，`content` → 文本）
- 插入 `LyricsProvider` 链，优先级 1.5（在本地缓存与 LRCLIB 之间）

### v0.2.3 缓存管理完整界面（2d）
- 列表：歌名、大小、缓存时间、最后播放时间、是否 pinned
- 筛选：全部/已加入歌单/孤立缓存，按大小/时间排序
- 批量操作：清理未收藏、清理 N 天未播放、导出歌单（JSON）
- 节省流量统计：累计缓存命中次数 × 平均大小

### v0.2.4 历史统计（1.5d）
- 总播放时长、播放次数 Top 10、歌手 Top 5
- 按月热力图（`fl_chart`）
- 导出 CSV

### v0.2.5 音质选择与智能歌单（3.5d）
- 音质设置：WiFi 默认 / 移动网络默认（PRD 3.5.4 网络感知）
- 智能歌单：最近播放（7 天）、最常播放（30 天 Top 50）、本周新增
- 歌单封面自定义：从歌曲选择 / 相册上传

---

## v0.3 · 高级功能（+8d）

### v0.3.1 双语与逐字歌词（2d）
- 渲染双语：原文 + 翻译上下行，字号区分
- 逐字高亮：`<mm:ss.xx>` 标记解析后，`CustomPaint` 逐词变色

### v0.3.2 桌面悬浮歌词（2d）
- Windows/Linux/macOS：`bitsdojo_window` 创建无边框置顶窗口，透明背景
- 拖拽移动、锁定位置、字体/颜色/描边设置

### v0.3.3 网络状态感知与批量缓存（2d）
- 监听 `connectivity_plus`：WiFi/移动/无网络
- 移动网络下播放弹确认，缓存任务暂停
- 批量缓存：后台下载队列，通知栏进度

### v0.3.4 歌单导入导出（2d）
- JSON 格式：`{version, name, tracks: [{bvid, cid, title, artist}]}`
- 分享：生成文件，系统分享面板；导入：文件选择器

---

## v1.0 · 功能完整（+12d）

### v1.0.1 前奏检测自动对齐（3d）
- `package:fftea` 计算音频能量包络，检测首句起点
- 与歌词首行时间戳对比，自动偏移

### v1.0.2 歌词源插件化（2d）
- `LyricsProvider` 外部注册机制，Dart 包通过 `LyricsPlugin` 接口集成
- 设置页管理已安装源（启用/禁用/优先级）

### v1.0.3 多语言（2d）
- 补充 ARB 翻译：繁体中文（zh-Hant）、英文（en）
- Crowdin 集成（可选）

### v1.0.4 多设备进度同步（3d）
- 自建同步服务（可选）或 Firebase Firestore
- 上传播放位置、队列快照，设备间轮询拉取

### v1.0.5 性能打磨（2d）
- Profile 模式下检查 jank，优化列表 build
- 启动耗时拆解，延迟非关键初始化（歌词、封面预加载）
- 缓存索引查询添加索引（`last_played_at`）

---

## 关键路径与风险

**关键路径**（单人 46d）：  
`M0 → M2 → M3.2 → M3.4 → M4.1 → M5 → M6 → M7 → M8`

**并行机会**（2 人 ~26d）：  
- 人 A：M0 → M1 → M3 → M4 → M8  
- 人 B：M0 → M2 → M7 → M5 → M6 → M8

**风险与缓解**：

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| B 站 API 变更 | 搜索/播放失败 | 接口层隔离 + 每周回归测试；社区监控（GitHub Issue） |
| WBI 签名算法更新 | 所有签名接口 403 | 算法从 `bilibili-API-collect` 同步；本地测试向量 |
| 风控（-412） | 频繁搜索被限 | M2.7 冷却机制；用户教育（搜索节制）；缓存优先 |
| 歌词匹配准确率不达标 | < 85% | M1.3 规则迭代 + 人工标注扩充测试集；提供手动选择兜底 |
| 桌面端媒体控制兼容性 | Linux 发行版差异 | MPRIS 是 FreeDesktop 标准，覆盖主流桌面；Windows SMTC API 稳定 |
| 边听边存并发冲突 | 缓存文件损坏 | `.tmp` 原子改名 + 文件锁；drift 事务写索引 |
| 后台播放被杀 | Android 低内存 | 前台服务 + 引导用户豁免电池优化；内存占用优化（M4.4） |

**DoD 检查清单（M8 前全部勾选）**：

- [ ] `flutter analyze` 0 warnings
- [ ] `domain/` 测试覆盖率 ≥ 90%
- [ ] PRD 第 8 节"验收指标"全部达标
- [ ] 五端安装包各安装并跑通一次完整流程（搜索 → 播放 → 歌词 → 缓存 → 歌单 → 重启恢复）
- [ ] 长时间播放测试（6 小时）通过
- [ ] 无已知 P0/P1 bug（crash、数据丢失、无法播放）

---

**总结**：MVP v0.1 约 46 人日（单人 9-10 周，双人 5-6 周）。按 2 周冲刺（10 个工作日）：Sprint 1-2（M0-M2），Sprint 3-4（M3-M5），Sprint 5-6（M6-M8）。每个 Sprint 末 Demo 可演示功能，持续交付可用增量。
