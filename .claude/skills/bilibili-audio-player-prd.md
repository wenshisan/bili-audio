# Bilibili Audio Player PRD Rules

This skill contains the core product rules and technical guidelines for the Bilibili Audio Player project.

## Content Filtering Rules

### Music Content Identification
- **Duration Limit**: Only support content ≤ 15 minutes, automatically filter podcasts and long videos
- **Category Priority**: Music zone (28), Entertainment zone music category, other configurable zones
- **Multi-P Recognition**: Support multi-P videos, each P inherits the main video's duration limit
- **Content Type**: Support regular video audio streams and audio zone exclusive content

### Search Result Display
- Show thumbnail, title (auto-optimized), UP主 info, stats (views, likes), duration + P count
- Filtered items (exceeding duration) should be grayed out or hidden
- Support pagination

## Title Cleaning Rules (Core Feature)

Title cleaning is used for both **display optimization** and **lyrics matching**.

### Removal Patterns
Remove content in brackets `【】` `[]` `()` `「」`:
- Audio quality markers: `【Hi-Res】` `【无损】` `【320K】` `【FLAC】` `【DSD】`
- Video type: `【官方MV】` `【4K】` `【60帧】` `【HDR】` `【杜比全景声】`
- Cover markers: `【翻唱】` `【cover】` `【Cover】` `【カバー】`
- Subtitle markers: `【中字】` `【日语】` `【罗马音】` `【歌词】`
- Other modifiers: `【完整版】` `【Live】` `【现场】` `【纯享版】` `【伴奏】`

### Delimiter Recognition
Split song name and artist by priority:
- ` - ` `—` `｜` `|` `/` (song before, artist after)
- `《歌名》歌手` or `歌手《歌名》`

### Prefix/Suffix Removal
- Prefix: `【中字】` `【日语】` `完整版` `高清` `官方`
- Suffix: `MV` `歌词版` `伴奏` `纯音乐` `Instrumental`

### Instrumental Recognition
Mark as "no lyrics" when title contains: `伴奏` `纯音乐` `Instrumental`

### Normalization
- Traditional to Simplified Chinese (for matching, display keeps original)
- Full-width to half-width (English, numbers, punctuation)
- Remove extra whitespace (consecutive spaces, leading/trailing spaces)
- Standardize case (English song names capitalize first letter)

### Fallback Strategy
- Use P-part title (more accurate in multi-P videos)
- Use video tags for singer/song names
- Use UP主 name as candidate artist when artist cannot be identified

### Configuration
- Rules maintained in `assets/config/title_cleaning_rules.json`
- Support regex matching patterns
- Remote rule updates on version updates (optional)
- Users can view/disable specific rules in settings

## Lyrics Matching Algorithm

### Source Priority
1. Local cache (already matched, includes user-calibrated offset)
2. Bilibili CC subtitles (can convert to LRC)
3. LRCLIB (open-source lyrics library)
4. Other third-party sources (plugin form, disabled by default)
5. Local import (user manually imports .lrc files)

### Fuzzy Matching Score
Calculate comprehensive score `score ∈ [0, 1]`:

```
score = 0.55 × title_similarity + 0.25 × artist_similarity + 0.20 × duration_similarity
```

- **Title similarity**: Max of normalized Levenshtein distance and Token set Jaccard; pinyin similarity for Chinese
- **Artist similarity**: Multiple artists split by `、` `&` `feat.`, take max match; missing artist weight merges into title
- **Duration similarity**: `max(0, 1 - |Δt| / 10s)`, difference > 10s = 0

### Matching Thresholds
- `score ≥ 0.80`: Auto-adopt
- `0.60 ≤ score < 0.80`: Adopt but mark "may be inaccurate", prompt user to confirm
- `score < 0.60`: Don't auto-adopt, show candidate list for manual selection

### Time Alignment
- **Overall offset**: Support ±0.1s / ±0.5s step adjustment, persist by video (BV + P)
- **Duration scaling**: When lyrics total duration differs significantly from audio and is linearly correlated, prompt for auto-scaling
- **Intro detection (P2)**: Estimate initial offset based on first line time and audio energy start

## Playback Mode Management

All playback modes managed by client-side `PlaybackQueue` class, not relying on just_audio's built-in shuffle:

| Mode | Behavior |
| --- | --- |
| **Sequential** | Play in queue order, stop after last song |
| **List Loop** | Loop through queue, return to first after last |
| **Single Loop** | Repeat current song |
| **Random (Basic)** | Randomly shuffle queue, no repeats until all songs played once, then re-shuffle |
| **Random (Smart)** | Weighted random, avoid same artist consecutively, reduce weight of recently played |

### Multi-P Handling
- Each P of multi-P video is an independent track
- In random mode, configure "P-part continuous play": P-parts of same video maintain order, participate in random as a whole

### Mode Switching
- Switching to random generates random queue immediately, current song unchanged, subsequent play in random order
- Switching from random back to sequential restores original queue order
- Random queue restored after app restart (persist random seed or queue index)

## Caching Strategy (Core Feature)

### Edge-Listening-Edge-Storing (Auto Cache)
- **Smart caching**: Auto-cache audio stream during playback, no manual download needed
- **First play**: Stream from network while writing to local cache
- **Second play**: Read from local cache directly, completely offline, 0 network requests
- **Cache completeness**: Audio + cover + lyrics + metadata (title, artist, duration, P info) all cached
- **Background cache**: Support marking "cache" in playlist, auto-download in background

### Cache Configuration
- **Default size**: 1GB
- **Adjustable range**: 100MB - 20GB (or unlimited)
- **Storage location**: Customizable (mobile supports SD card)
- **LRU cleanup**: Auto-cleanup least recently played items when cache full
- **Protection mechanism**: Music in local playlists marked as "favorited", excluded from auto-cleanup

### Network Optimization
- **Cache hit priority**: Check local cache before play, if hit completely no network access
- **Lazy stream URL refresh**: Cached music doesn't need to refresh stream URL, only request when playing uncached content
- **Preload strategy**: Next song in playlist auto-preloads (configurable off)
- **Network state awareness**:
  - WiFi: Auto-cache
  - Mobile network: Only play current, prompt whether to cache
  - No network: Only show cached content

## Login Strategy (On-Demand Login)

App supports **core features without login**, only prompt login when necessary:

### No Login Required
- Search music content
- Play basic quality (64K/128K)
- View lyrics, adjust offset
- Create local playlists
- Edge-listening-edge-storing cache
- Playback history

### Login Required (prompt when triggered)
- Playing high quality (192K/320K/Dolby): prompt "Login to unlock high quality"
- Playing member-exclusive/login-required content: prompt "This content requires login"
- Accessing "My Favorites": prompt "Login to sync Bilibili favorites"
- Following UP主: prompt "Login to view UP主 submissions"
- API returns -101 (not logged in) or -403 (insufficient permissions): auto-guide login

### Login Entry Points
- Settings page "Account" area (show "Click to login" or logged-in user info)
- Popup guide when feature blocked ("Login now" button)
- No forced login on first launch, no popup interruption

## UI/UX Requirements

### Material Design 3
- Follow Material Design 3 design specifications
- Support light/dark theme auto-switching (follow system) and manual switching
- Support custom theme colors (preset multiple color schemes)
- Responsive layout adapting to different screen sizes

### Display Optimization
- All song info displays (search results, playlist, notification bar, lock screen) use optimized song names
- Format unified as `歌名 - 歌手`
- Always preserve Bilibili original title, users can view
- Support manual editing of song name/artist, persist corrections

## Technical Stack

### Framework & Libraries
- **Framework**: Flutter 3.x / Dart 3
- **State Management**: Riverpod
- **Network**: dio (unified handling of Cookie, Referer, User-Agent, WBI signature)
- **Playback**: just_audio + audio_service (background play and system media control)
- **Cache**: just_audio's LockCachingAudioSource, supports edge-listening-edge-storing, cache key is `bvid_cid_quality`
- **Local Storage**:
  - drift (SQLite): Playlists, history, lyrics cache, offsets, cache index
  - File system: Audio files, cover images, lyrics files
- **Router**: go_router

### Layer Structure
```
lib/
├── data/          # Bilibili API, lyrics sources, database, Repository
├── domain/        # Entities, lyrics matching algorithm, PlaybackQueue management (pure Dart, unit testable)
├── features/      # search / player / lyrics / library / settings / queue
└── core/          # Network, logging, theme, utilities
```

## Performance Requirements

| Category | Requirement |
| --- | --- |
| Performance | Cold start < 2s; Click play to sound < 1.5s (normal network); Lyrics matching < 3s; P-part switching seamless < 0.5s |
| Stability | Audio stream expiration auto-refresh and continue, no user perception interruption; Background play 6+ hours no crash |
| Resources | Background play memory < 100MB (Android/iOS), < 150MB (desktop); Only decode audio stream, don't load video frames |
| Battery | Continuous background play 3 hours power consumption < 5% (test device: mid-range Android phone, screen off, WiFi) |

## Background Play (Core Feature)

### System Integration
- **Notification bar control**: Show cover, song name, artist, P info; play/pause, previous, next buttons; real-time progress update; support notification bar scrolling lyrics (Android)
- **Lock screen control**: System lock screen interface integrated media controls; show cover and song info; support headphone wire control, Bluetooth control
- **Media session integration**: Integrate system media session (Media Session / MPRIS); support system shortcut control (media keys); cooperate with other media apps (auto pause/resume)

### Low Power Optimization
- Background play only decode audio stream, don't decode video
- Smart network request merging, reduce wake-ups
- Support Doze mode and background restriction exemption application (Android)
- Prevent system sleep during play, auto-release when paused

### Breakpoint Resume
- Auto-save playback position, list, playback mode
- Restore last playback state after app restart
- Support multi-device progress sync (requires login, P2)

## Acceptance Criteria

### On-Demand Login
- Can complete search, play, lyrics, cache, local playlist full workflow in non-logged-in state
- No login popup during startup and regular use
- Only trigger login prompt in scenarios listed in 3.4.1

### Content Filtering Accuracy
- Content > 15 minutes filtering rate 100%
- Multi-P videos correctly identify each P's independent duration

### Cache Functionality
- First play auto-cache success rate ≥ 99%
- Second play cache hit rate 100%, 0 network requests
- 1GB cache space can hold ~200-300 songs (estimated at 128K bitrate)
- LRU cleanup accurate, don't mistakenly delete "favorited" music

### Lyrics Matching Accuracy
- Test set (≥ 200 popular music videos) lyrics auto-matching accuracy ≥ 85%, mismatch rate ≤ 5%
- Offset calibration after lyrics and singing error ≤ 0.3s

### Background Play Stability
- Continuous background play 6 hours no crash, no significant memory growth (< 20MB), no audio interruption

### Multi-P Switching Experience
- P-part switching delay < 0.5s, lyrics auto-switch to corresponding P

### Playback Mode Correctness
- Random mode no repeats within one round, all tracks played once before re-shuffle
- Smart random same artist consecutive appearance probability < 10% (when that artist < 50% of queue)
- Random mode "previous" can accurately go back to previous actually played track
- Mode switching, app restart keep queue and current track consistent

### System Integration Completeness
- Notification bar, lock screen, media keys, Bluetooth headphone control all work properly

### Stream URL Auto-Refresh
- Play 3+ hours, stream URL expiration auto-refresh seamlessly success rate ≥ 99% (only for uncached content)

### Core Module Test Coverage
- Title cleaning, scoring algorithm, P-part parsing, cache management, PlaybackQueue unit test coverage ≥ 90%

## Version Planning

| Version | Scope |
| --- | --- |
| v0.1 MVP | QR login, search (duration filter ≤ 15min), auto-optimize song name display, P-part support, audio play, edge-listening-edge-storing (1GB cache), excellent background play (notification/lock screen control), LRCLIB lyrics + fuzzy matching, offset calibration, basic local playlists |
| v0.2 | Favorites sync (auto-filter long content), complete local playlist management, playback history stats, Bilibili CC subtitle lyrics source, quality selection, cache management UI |
| v0.3 | Batch cache, bilingual/word-by-word lyrics, desktop floating lyrics, smart playlists, network state awareness |
| v1.0 | Intro detection auto-alignment, lyrics source plugin system, multi-language, multi-device progress sync, cache export sharing, performance and stability polish |

## Development Principles

1. **Login Optional First**: Ensure all core features work without login, only prompt when absolutely necessary
2. **Cache First**: Prioritize local cache, minimize network requests
3. **User Experience**: Seamless P-part switching, no interruption during stream URL refresh, smooth background play
4. **Code Quality**: Pure functions for core algorithms (title cleaning, scoring), high unit test coverage
5. **Configuration Driven**: Title cleaning rules, lyrics sources configurable, easy to iterate
6. **Material Design Compliance**: Strictly follow Material Design 3 specifications, support theming
7. **Performance Oriented**: Meet all performance requirements in section 4
