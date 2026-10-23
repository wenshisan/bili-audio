import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion/motion.dart';
import '../../app/providers.dart';
import '../../data/lyrics/lyrics_manager.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/lyrics/lrc_parser.dart';
import '../../domain/lyrics/lyrics_provider.dart';
import '../../l10n/l10n.dart';
import 'lyrics_controller.dart';

/// 歌词区 (M5.5 / M6.2): 当前行高亮居中, 点击行跳转
class LyricsView extends ConsumerWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final muted = TextStyle(color: Theme.of(context).colorScheme.outline);
    final controller = ref.read(lyricsControllerProvider.notifier);

    final lyrics = ref.watch(lyricsControllerProvider);
    return MotionSwap(
      swapKey: _lyricsKey(lyrics),
      child: switch (lyrics) {
        AsyncLoading() => Center(child: Text(l10n.lyricsLoading, style: muted)),
        AsyncError(:final error) => Center(
          child: Text(errorText(l10n, error), style: muted),
        ),
        AsyncData(value: LyricsFound(:final lyrics)) => _Lines(lyrics: lyrics),
        AsyncData(value: LyricsUncertain(:final candidates)) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.lyricsUncertain, style: muted),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => showLyricsPicker(context, ref, candidates),
                child: Text(l10n.lyricsPick),
              ),
            ],
          ),
        ),
        AsyncData(value: LyricsNone(:final candidates, :final markedByUser)) =>
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.playerLyricsPlaceholder, style: muted),
                if (!markedByUser && candidates.isNotEmpty)
                  TextButton(
                    onPressed: () => showLyricsPicker(context, ref, candidates),
                    child: Text(l10n.lyricsPick),
                  ),
                if (markedByUser)
                  TextButton(
                    onPressed: controller.rematch,
                    child: Text(l10n.lyricsRematch),
                  ),
              ],
            ),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

Object _lyricsKey(AsyncValue<LyricsResult?> state) => switch (state) {
  AsyncLoading() => 'loading',
  AsyncError() => 'error',
  AsyncData(value: LyricsFound(:final lyrics)) =>
    'found:${lyrics.source}:${lyrics.lines.length}:${lyrics.lines.isEmpty ? '' : lyrics.lines.first.text}',
  AsyncData(value: LyricsUncertain()) => 'uncertain',
  AsyncData(value: LyricsNone()) => 'none',
  _ => 'other',
};

class _Lines extends ConsumerStatefulWidget {
  const _Lines({required this.lyrics});

  final Lyrics lyrics;

  @override
  ConsumerState<_Lines> createState() => _LinesState();
}

class _LinesState extends ConsumerState<_Lines> {
  static const _lineHeight = 48.0;
  final _scroll = ScrollController();
  late LyricsTimeline _timeline = LyricsTimeline(widget.lyrics);
  int _current = -1;
  DateTime _userScrolledAt = DateTime(0);

  @override
  void didUpdateWidget(covariant _Lines old) {
    super.didUpdateWidget(old);
    if (old.lyrics != widget.lyrics) _timeline = LyricsTimeline(widget.lyrics);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _follow(int index, double viewport) {
    if (index == _current) return;
    _current = index;
    // 用户手动滚动后 3 秒内不自动跟随
    if (DateTime.now().difference(_userScrolledAt) <
        const Duration(seconds: 3)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = (index * _lineHeight).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final index = _timeline.indexAt(position);
    final lines = widget.lyrics.lines;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        _follow(index, c.maxHeight);
        final pad = (c.maxHeight - _lineHeight) / 2;
        return Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: (_) {
                _userScrolledAt = DateTime.now();
                return false;
              },
              child: ListView.builder(
                controller: _scroll,
                padding: EdgeInsets.symmetric(
                  vertical: pad.clamp(0, double.infinity),
                ),
                itemExtent: _lineHeight,
                itemCount: lines.length,
                itemBuilder: (context, i) {
                  final line = lines[i];
                  final active = i == index;
                  return InkWell(
                    // 跳转到该行: 时间戳需加回偏移
                    onTap: () => ref
                        .read(audioHandlerProvider)
                        .seek(line.timestamp + widget.lyrics.offset),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            line.text,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: active
                                ? theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  )
                                : theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                          ),
                          if (line.translation != null)
                            Text(
                              line.translation!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: IconButton(
                tooltip: context.l10n.lyricsOffset,
                icon: const Icon(Icons.tune),
                onPressed: () => showOffsetSheet(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 歌词偏移: ±0.1s 步进 + ±0.5s 快捷 (D10: 全链路 Duration)
Future<void> showOffsetSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _OffsetSheet(),
    );

class _OffsetSheet extends ConsumerWidget {
  const _OffsetSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final result = ref.watch(lyricsControllerProvider).value;
    final controller = ref.read(lyricsControllerProvider.notifier);
    final offset = result is LyricsFound ? result.lyrics.offset : Duration.zero;
    final seconds = (offset.inMilliseconds / 1000).toStringAsFixed(1);

    Widget step(int ms, String label) => OutlinedButton(
      onPressed: result is LyricsFound
          ? () => controller.adjustOffset(Duration(milliseconds: ms))
          : null,
      child: Text(label),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.lyricsOffset,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lyricsOffsetValue(offset.isNegative ? seconds : '+$seconds'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                step(-500, '-0.5s'),
                step(-100, '-0.1s'),
                step(100, '+0.1s'),
                step(500, '+0.5s'),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.rematch();
                  },
                  child: Text(l10n.lyricsRematch),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    controller.markNone();
                  },
                  child: Text(l10n.lyricsMarkNone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 手动选择歌词候选
Future<void> showLyricsPicker(
  BuildContext context,
  WidgetRef ref,
  List<LyricsCandidate> candidates,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheet) {
    final l10n = sheet.l10n;
    final controller = ref.read(lyricsControllerProvider.notifier);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final c in candidates)
            ListTile(
              title: Text(
                l10n.lyricsCandidate(
                  c.originalTitle ?? '',
                  c.originalArtist ?? '',
                  (c.matchScore * 100).round(),
                ),
              ),
              subtitle: Text(
                c.lyrics.lines.take(2).map((l) => l.text).join(' / '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(sheet);
                controller.accept(c);
              },
            ),
          ListTile(
            leading: const Icon(Icons.block),
            title: Text(l10n.lyricsMarkNone),
            onTap: () {
              Navigator.pop(sheet);
              controller.markNone();
            },
          ),
        ],
      ),
    );
  },
);
