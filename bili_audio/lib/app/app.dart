import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/update/distribution.dart';
import '../l10n/l10n.dart';
import 'adaptive/player_shortcuts.dart';
import 'platform/window_frame.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';
import 'widgets/window_title_bar.dart';

bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

class BiliAudioApp extends ConsumerWidget {
  const BiliAudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => productTitle(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(themeState.seed, Brightness.light),
      darkTheme: buildTheme(themeState.seed, Brightness.dark),
      themeMode: themeState.mode,
      routerConfig: appRouter,
      // 桌面端套一层无边框窗口外壳: 8px 圆角 + 自定义标题栏
      builder: (context, child) {
        Widget content = PlayerShortcutLayer(
          child: child ?? const SizedBox.shrink(),
        );
        if (isDesktop) content = _DesktopWindowShell(child: content);
        if (!kIsWeb && Platform.isMacOS) {
          content = _MacPlaybackMenu(child: content);
        }
        return content;
      },
    );
  }
}

/// 桌面端窗口外壳 (沿用 talix_companion_flutter 的无边框方案)。
///
/// 窗口背景在 main() 中设为透明, 这里用 ClipRRect 裁出圆角。
/// 顶部标题栏可拖拽。Windows / Linux 在右侧放窗体按钮；
/// macOS 保留系统红绿灯，标题栏与红绿灯同高，标题靠右并垂直居中。
class _DesktopWindowShell extends StatelessWidget {
  const _DesktopWindowShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: desktopWindowRounded,
      builder: (context, rounded, _) => ClipRRect(
        borderRadius: BorderRadius.circular(rounded ? 8 : 0),
        clipBehavior: Clip.antiAlias,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(top: WindowTitleBar.platformBarHeight),
                child: child,
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: WindowTitleBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacPlaybackMenu extends ConsumerWidget {
  const _MacPlaybackMenu({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final handler = ref.read(audioHandlerProvider);
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: productTitle(),
          menus: [
            PlatformMenuItem(
              label: l10n.actionPlay,
              onSelected: () => togglePlay(handler),
            ),
            PlatformMenuItem(label: '上一首', onSelected: handler.skipToPrevious),
            PlatformMenuItem(label: '下一首', onSelected: handler.skipToNext),
            PlatformMenuItem(
              label: l10n.settingsTitle,
              onSelected: () => context.go('/settings'),
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}
