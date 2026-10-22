import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/player/bili_audio_handler.dart';
import '../providers.dart';
import 'layout_settings.dart';

final searchFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'search');
  ref.onDispose(node.dispose);
  return node;
});

void togglePlay(BiliAudioHandler handler) {
  if (handler.engine.playing) {
    handler.pause();
  } else {
    handler.play();
  }
}

void seekBy(BiliAudioHandler handler, Duration delta) {
  final total = handler.mediaItem.hasValue ? handler.mediaItem.value?.duration : null;
  var next = handler.engine.position + delta;
  if (next < Duration.zero) next = Duration.zero;
  if (total != null && next > total) next = total;
  handler.seek(next);
}

bool textFieldFocused() {
  final focus = FocusManager.instance.primaryFocus;
  final context = focus?.context;
  if (context == null) return false;
  return context.findAncestorStateOfType<EditableTextState>() != null;
}

void focusSearch(BuildContext context, WidgetRef ref) {
  if (ref.read(layoutSettingsProvider).carLayout) return;
  GoRouter.of(context).go('/search');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(searchFocusNodeProvider).requestFocus();
  });
}

/// 桌面和 iPad 外接键盘。焦点在输入框时不拦截。
class PlayerShortcutLayer extends ConsumerStatefulWidget {
  const PlayerShortcutLayer({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PlayerShortcutLayer> createState() => _PlayerShortcutLayerState();
}

class _PlayerShortcutLayerState extends ConsumerState<PlayerShortcutLayer> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || textFieldFocused()) return false;
    final key = event.logicalKey;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final command = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    if (command && key == LogicalKeyboardKey.keyF) {
      focusSearch(context, ref);
      return true;
    }
    final handler = ref.read(audioHandlerProvider);
    if (key == LogicalKeyboardKey.space) {
      togglePlay(handler);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      seekBy(handler, const Duration(seconds: -5));
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      seekBy(handler, const Duration(seconds: 5));
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.mediaTrackPrevious) {
      handler.skipToPrevious();
      return true;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.mediaTrackNext) {
      handler.skipToNext();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
