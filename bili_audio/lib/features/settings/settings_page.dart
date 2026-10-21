import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/entities/audio_track.dart';
import '../../l10n/l10n.dart';
import '../common/cover_image.dart';
import '../login/login_controller.dart';

/// 设置 (M6.6)
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final db = ref.watch(databaseProvider);
    final prefs = ref.watch(playbackPrefsProvider);
    return ListView(
      children: [
        const _AccountTile(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.music_note_outlined),
          title: Text(l10n.settingsPlayback),
        ),
        ListTile(
          title: Text(l10n.settingsQuality),
          subtitle: Text(prefs.quality.name),
          onTap: () async {
            final q = await _pickQuality(context, prefs.quality);
            if (q != null) {
              prefs.quality = q;
              await db.settingsDao.setDefaultQuality(q.id);
            }
          },
        ),
        if (!prefs.loggedIn)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: Text(l10n.settingsQualityGuestHint,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(l10n.settingsCache),
        ),
        FutureBuilder<int>(
          future: db.settingsDao.getCacheMaxSize(),
          builder: (c, snap) {
            final max = snap.data ?? (500 * 1024 * 1024);
            return ListTile(
              title: Text(l10n.settingsCacheLimit),
              subtitle: Text(formatBytes(max)),
              onTap: () => _pickCacheLimit(c, ref, max),
            );
          },
        ),
        ListTile(
          title: Text(l10n.settingsCacheManage),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/cache'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l10n.settingsAppearance),
        ),
        const _ThemeModeRow(),
        const _SeedColorRow(),
      ],
    );
  }

  Future<AudioQuality?> _pickQuality(
    BuildContext context,
    AudioQuality current,
  ) =>
      showDialog<AudioQuality>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.l10n.settingsQuality),
          content: RadioGroup<AudioQuality>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(c, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final q in AudioQuality.values.reversed)
                  RadioListTile<AudioQuality>(title: Text(q.name), value: q),
              ],
            ),
          ),
        ),
      );

  Future<void> _pickCacheLimit(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final l10n = context.l10n;
    final options = [
      250 * 1024 * 1024,
      500 * 1024 * 1024,
      1024 * 1024 * 1024,
      2 * 1024 * 1024 * 1024,
      5 * 1024 * 1024 * 1024,
    ];
    final picked = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.settingsCacheLimit),
        content: RadioGroup<int>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(c, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final size in options)
                RadioListTile<int>(title: Text(formatBytes(size)), value: size),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(databaseProvider).settingsDao.setCacheMaxSize(picked);
    }
  }
}

class _ThemeModeRow extends ConsumerWidget {
  const _ThemeModeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(themeControllerProvider.notifier);
    final mode = ref.watch(themeControllerProvider).mode;
    return ListTile(
      title: Text(l10n.settingsThemeMode),
      subtitle: Text(switch (mode) {
        ThemeMode.system => l10n.themeSystem,
        ThemeMode.light => l10n.themeLight,
        ThemeMode.dark => l10n.themeDark,
      }),
      onTap: () async {
        final picked = await showDialog<ThemeMode>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(l10n.settingsThemeMode),
            content: RadioGroup<ThemeMode>(
              groupValue: mode,
              onChanged: (v) => Navigator.pop(c, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final m in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      title: Text(switch (m) {
                        ThemeMode.system => l10n.themeSystem,
                        ThemeMode.light => l10n.themeLight,
                        ThemeMode.dark => l10n.themeDark,
                      }),
                      value: m,
                    ),
                ],
              ),
            ),
          ),
        );
        if (picked != null) controller.setMode(picked);
      },
    );
  }
}

class _SeedColorRow extends ConsumerWidget {
  const _SeedColorRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(themeControllerProvider.notifier);
    final seed = ref.watch(themeControllerProvider).seed;
    return ListTile(
      title: Text(l10n.settingsSeedColor),
      subtitle: Wrap(
        spacing: 8,
        children: [
          for (final c in presetSeeds)
            GestureDetector(
              onTap: () => controller.setSeed(c),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: seed == c ? Border.all(width: 3, color: c) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 账号 (M7.2): 未登录显示"点击登录", 已登录显示头像/昵称/退出
class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(loginControllerProvider);
    final u = user.value;
    if (u == null) {
      return ListTile(
        leading: const Icon(Icons.account_circle_outlined),
        title: Text(l10n.settingsAccount),
        subtitle: Text(user.isLoading ? '…' : l10n.settingsNotLoggedIn),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/login'),
      );
    }
    return ListTile(
      leading: CoverImage(u.face, size: 40, radius: 20),
      title: Text(u.name),
      subtitle: Text('Lv${u.level}${u.vip ? ' · VIP' : ''}'),
      trailing: TextButton(
        child: Text(l10n.logout),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              content: Text(l10n.logoutConfirm),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(l10n.cancel)),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(l10n.confirm)),
              ],
            ),
          );
          if (ok == true) {
            await ref.read(loginControllerProvider.notifier).logout();
          }
        },
      ),
    );
  }
}
