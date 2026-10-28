import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/adaptive/layout_settings.dart';
import '../../domain/update/distribution.dart';
import '../../l10n/l10n.dart';
import 'update_controller.dart';

/// 进入主界面后检查一次更新。车机布局下不弹窗。
class UpdatePrompt extends ConsumerStatefulWidget {
  /// 包住主界面。
  const UpdatePrompt({super.key, required this.child});

  /// 被包住的子树。
  final Widget child;

  @override
  ConsumerState<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<UpdatePrompt> {
  var _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !offersInAppUpdate()) return;
      ref.read(updateControllerProvider.notifier).check();
    });
  }

  void _schedulePrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  void _maybePrompt() {
    if (!offersInAppUpdate() || _shown || !mounted) return;
    if (ref.read(layoutSettingsProvider).carLayout) return;
    final phase = ref.read(updateControllerProvider).phase;
    if (phase != UpdatePhase.available && phase != UpdatePhase.unsupported) {
      return;
    }
    _shown = true;
    showUpdateDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, (previous, next) {
      if (previous?.phase == next.phase) return;
      _schedulePrompt();
    });
    ref.listen(layoutSettingsProvider, (previous, next) => _schedulePrompt());
    return widget.child;
  }
}

/// 打开升级对话框。
Future<void> showUpdateDialog(BuildContext context) {
  if (!offersInAppUpdate()) return Future<void>.value();
  return showDialog<void>(
    context: context,
    builder: (context) => const _UpdateDialog(),
  );
}

class _UpdateDialog extends ConsumerWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(updateControllerProvider);
    final version = state.release?.version.text ?? '';
    final notes = state.release?.changelog ?? '';
    return AlertDialog(
      title: Text(
        state.phase == UpdatePhase.unsupported
            ? l10n.updateUnsupportedTitle
            : l10n.updateAvailableTitle(version),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notes.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(child: Text(notes)),
              ),
            if (state.phase == UpdatePhase.unsupported &&
                (state.release?.pageUrl.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              SelectableText(state.release!.pageUrl),
            ],
            if (state.phase == UpdatePhase.downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: state.progress == 0 ? null : state.progress,
              ),
              const SizedBox(height: 8),
              Text(l10n.updateDownloading((state.progress * 100).round())),
              if (state.asset?.name.endsWith('.dmg') == true) ...[
                const SizedBox(height: 8),
                Text(l10n.updateMacAdmin),
              ],
            ],
            if (state.failure != null) ...[
              const SizedBox(height: 12),
              Text(_failureText(l10n, state.failure!)),
            ],
            if (state.phase == UpdatePhase.launched) ...[
              const SizedBox(height: 12),
              Text(
                state.asset?.name.endsWith('.ipa') == true
                    ? l10n.updateLaunchedIos
                    : state.asset?.name.endsWith('.dmg') == true
                    ? l10n.updateLaunchedMac
                    : l10n.updateLaunched,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (state.phase != UpdatePhase.launched &&
            state.phase != UpdatePhase.unsupported)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.updateLater),
          ),
        if (state.phase == UpdatePhase.available ||
            state.failure == UpdateFailure.permission ||
            state.failure == UpdateFailure.download)
          FilledButton(
            onPressed: state.phase == UpdatePhase.downloading
                ? null
                : () => ref
                      .read(updateControllerProvider.notifier)
                      .downloadAndInstall(),
            child: Text(
              state.asset?.name.endsWith('.ipa') == true
                  ? l10n.updateInstallIos
                  : l10n.updateDownload,
            ),
          ),
        if (state.phase == UpdatePhase.launched ||
            state.phase == UpdatePhase.unsupported)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm),
          ),
      ],
    );
  }
}

String _failureText(AppLocalizations l10n, UpdateFailure failure) =>
    switch (failure) {
      UpdateFailure.check => l10n.updateCheckFailed,
      UpdateFailure.download => l10n.updateDownloadFailed,
      UpdateFailure.permission => l10n.updatePermission,
    };

/// 设置页里的升级入口。
class UpdateSettingsTile extends ConsumerWidget {
  /// 创建升级入口。
  const UpdateSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(updateControllerProvider);
    return ListTile(
      leading: const Icon(Icons.system_update_outlined),
      title: Text(l10n.updateTitle),
      subtitle: Text(_subtitle(l10n, state)),
      onTap:
          state.phase == UpdatePhase.checking ||
              state.phase == UpdatePhase.downloading
          ? null
          : () => _onTap(context, ref, state),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    UpdateState state,
  ) async {
    if (state.phase == UpdatePhase.available ||
        state.phase == UpdatePhase.unsupported ||
        state.phase == UpdatePhase.launched) {
      await showUpdateDialog(context);
      return;
    }
    await ref.read(updateControllerProvider.notifier).check();
    if (!context.mounted) return;
    final phase = ref.read(updateControllerProvider).phase;
    if (phase == UpdatePhase.available || phase == UpdatePhase.unsupported) {
      await showUpdateDialog(context);
    }
  }
}

String _subtitle(AppLocalizations l10n, UpdateState state) {
  final current = state.current?.text;
  final prefix = current == null ? '' : l10n.updateCurrent(current);
  final detail = switch (state.phase) {
    UpdatePhase.idle || UpdatePhase.checking => l10n.updateChecking,
    UpdatePhase.upToDate => l10n.updateUpToDate,
    UpdatePhase.available ||
    UpdatePhase.downloading ||
    UpdatePhase.launched => l10n.updateAvailable(state.release!.version.text),
    UpdatePhase.unsupported => l10n.updateUnsupportedShort,
    UpdatePhase.failed => _failureText(
      l10n,
      state.failure ?? UpdateFailure.check,
    ),
  };
  if (state.phase == UpdatePhase.downloading) {
    return '$detail ${l10n.updateDownloading((state.progress * 100).round())}';
  }
  return prefix.isEmpty ? detail : '$prefix · $detail';
}
