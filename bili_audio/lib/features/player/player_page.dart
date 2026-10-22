import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/adaptive/window_metrics.dart';
import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../common/add_to_playlist_sheet.dart';
import '../album/album_controller.dart';
import '../lyrics/lyrics_controller.dart';
import '../lyrics/lyrics_view.dart';
import 'widgets/player_transport.dart';

/// 播放页 (M6.2)
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final item = ref.watch(mediaItemProvider).value;
    final handler = ref.read(audioHandlerProvider);
    final track = handler.currentTrack;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => context.pop(),
        ),
        actions: [if (track != null) _MoreMenu()],
      ),
      body: item == null || track == null
          ? Center(child: Text(l10n.nothingPlaying))
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final metrics = WindowMetrics.fromSize(c.biggest);
                  if (metrics.isShort) return _ShortPlayer(item: item);
                  final cover = PlayerCoverSection(item: item);
                  const lyrics = LyricsView();
                  final sideBySide =
                      metrics.width.index >= WindowWidth.expanded.index;
                  return Column(
                    children: [
                      Expanded(
                        child: sideBySide
                            ? Row(
                                children: [
                                  Expanded(child: cover),
                                  const Expanded(child: lyrics),
                                ],
                              )
                            : Column(
                                children: [
                                  Expanded(flex: 3, child: cover),
                                  const Expanded(flex: 2, child: lyrics),
                                ],
                              ),
                      ),
                      const PlayerProgressBar(),
                      const PlayerControls(),
                      const PlayerSleepIndicator(),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _ShortPlayer extends StatelessWidget {
  const _ShortPlayer({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: PlayerCoverSection(item: item, padding: 8, compact: true),
        ),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CurrentLyricLine(),
              PlayerProgressBar(),
              PlayerControls(mainExtent: 56, iconExtent: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final handler = ref.read(audioHandlerProvider);
    return PopupMenuButton<String>(
      onSelected: (v) async {
        final track = handler.currentTrack;
        if (track == null) return;
        switch (v) {
          case 'speed':
            await _pickSpeed(context, ref);
          case 'sleep':
            await _pickSleep(context, ref);
          case 'playlist':
            await showAddToPlaylistSheet(context, ref, () async => [track]);
          case 'original':
            await showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(l10n.originalTitle),
                content: SelectableText('${track.title}\n${track.bvid}'),
              ),
            );
          case 'edit':
            await _editTitle(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'speed', child: Text(l10n.playerSpeed)),
        PopupMenuItem(value: 'sleep', child: Text(l10n.playerSleepTimer)),
        PopupMenuItem(value: 'playlist', child: Text(l10n.actionAddToPlaylist)),
        PopupMenuItem(
          value: 'original',
          child: Text(l10n.playerViewOriginalTitle),
        ),
        PopupMenuItem(value: 'edit', child: Text(l10n.playerEditTitle)),
      ],
    );
  }

  Future<void> _pickSpeed(BuildContext context, WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    final speed = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final s in const [0.75, 1.0, 1.25, 1.5, 2.0])
              ChoiceChip(
                label: Text('${s}x'),
                selected: handler.engine.speed == s,
                onSelected: (_) => Navigator.pop(c, s),
              ),
          ],
        ),
      ),
    );
    if (speed != null) await handler.setSpeed(speed);
  }

  Future<void> _pickSleep(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final timer = ref.read(audioHandlerProvider).sleepTimer;
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.sleepOff),
              onTap: () => Navigator.pop(c, 0),
            ),
            for (final m in const [15, 30, 60])
              ListTile(
                title: Text(l10n.sleepMinutes(m)),
                onTap: () => Navigator.pop(c, m),
              ),
            ListTile(
              title: Text(l10n.sleepAfterCurrent),
              onTap: () => Navigator.pop(c, -1),
            ),
            ListTile(
              title: Text(l10n.sleepAfterNext),
              onTap: () => Navigator.pop(c, -2),
            ),
          ],
        ),
      ),
    );
    switch (choice) {
      case null:
        return;
      case 0:
        timer.cancel();
      case < 0:
        timer.startAfterTracks(-choice);
      default:
        timer.start(Duration(minutes: choice));
    }
  }

  /// 编辑歌名/歌手: 写 user_edited=true, 重启保持 (M6.2)
  Future<void> _editTitle(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final handler = ref.read(audioHandlerProvider);
    final track = handler.currentTrack!;
    final name = TextEditingController(text: track.displayTitle);
    final artist = TextEditingController(text: track.artist ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.playerEditTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: l10n.fieldSongName),
            ),
            TextField(
              controller: artist,
              decoration: InputDecoration(labelText: l10n.fieldArtist),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final newName = name.text.trim().isEmpty ? null : name.text.trim();
    final newArtist = artist.text.trim().isEmpty ? null : artist.text.trim();
    await ref
        .read(databaseProvider)
        .tracksDao
        .updateTrackByUser(
          bvid: track.bvid,
          cid: track.cid,
          cleanedName: newName,
          artist: newArtist,
        );
    handler.updateCurrentTrack(
      track.copyWith(cleanedName: newName, artist: newArtist),
    );
    // 歌名变化后清除歌词和专辑缓存，按新歌名重新匹配
    await ref.read(lyricsControllerProvider.notifier).rematch();
    await ref.read(albumControllerProvider.notifier).rematch();
  }
}
