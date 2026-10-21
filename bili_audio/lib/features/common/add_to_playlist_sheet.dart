import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/entities/audio_track.dart' as domain;
import '../../l10n/l10n.dart';
import '../player/player_actions.dart';

final playlistsWithCountProvider = StreamProvider(
  (ref) => ref.watch(databaseProvider).playlistsDao.watchPlaylistsWithCount(),
);

/// 选择歌单并加入 (M6.4); 支持就地新建
Future<void> showAddToPlaylistSheet(
  BuildContext context,
  WidgetRef ref,
  Future<List<domain.Track>?> Function() loadTracks,
) async {
  final playlistId = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _PlaylistPicker(),
  );
  if (playlistId == null || !context.mounted) return;
  final tracks = await loadTracks();
  if (tracks == null || !context.mounted) return;
  await ref.read(playerActionsProvider).addToPlaylist(playlistId, tracks);
  final playlist =
      await ref.read(databaseProvider).playlistsDao.getPlaylist(playlistId);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.addedToPlaylist(playlist?.name ?? ''))),
  );
}

/// 输入歌单名的对话框; 返回 null 表示取消
Future<String?> showPlaylistNameDialog(
  BuildContext context, {
  String initial = '',
  String? title,
}) {
  final controller = TextEditingController(text: initial);
  final l10n = context.l10n;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title ?? l10n.libraryCreate),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 100,
        decoration: InputDecoration(labelText: l10n.playlistName),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  ).then((v) => v == null || v.isEmpty ? null : v);
}

class _PlaylistPicker extends ConsumerWidget {
  const _PlaylistPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playlists = ref.watch(playlistsWithCountProvider).value ?? const [];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.libraryCreate),
            onTap: () async {
              final name = await showPlaylistNameDialog(context);
              if (name == null) return;
              final id = await ref
                  .read(databaseProvider)
                  .playlistsDao
                  .createPlaylist(PlaylistsCompanion.insert(
                    name: name,
                    source: const Value('local'),
                  ));
              if (context.mounted) Navigator.pop(context, id);
            },
          ),
          for (final p in playlists)
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.playlist.name),
              subtitle: Text(l10n.playlistTrackCount(p.count)),
              enabled: !p.playlist.isReadonly,
              onTap: () => Navigator.pop(context, p.playlist.id),
            ),
        ],
      ),
    );
  }
}
