import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
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
      onGenerateTitle: (context) => context.l10n.appTitle,
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
        final content = child ?? const SizedBox.shrink();
        return isDesktop ? _DesktopWindowShell(child: content) : content;
      },
    );
  }
}

/// 桌面端窗口外壳 (沿用 talix_companion_flutter 的无边框方案)。
///
/// 窗口背景在 main() 中设为透明, 这里用 ClipRRect 裁出圆角,
/// 顶部放自定义标题栏承担拖拽 / 最小化 / 最大化 / 关闭。
class _DesktopWindowShell extends StatelessWidget {
  const _DesktopWindowShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            const WindowTitleBar(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
