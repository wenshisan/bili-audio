import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 预设主题种子色 (dev-tasks M0.4)。首项为 B 站粉。
const List<Color> presetSeeds = [
  Color(0xFFFB7299),
  Color(0xFF00AEEC),
  Color(0xFF6750A4),
  Color(0xFF2E7D32),
  Color(0xFFEF6C00),
  Color(0xFF455A64),
];

ThemeData buildTheme(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      color: scheme.surfaceContainerLow,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll<double>(1),
      backgroundColor: WidgetStatePropertyAll<Color>(
        brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerLow,
      ),
    ),
  );
}

@immutable
class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.seed = const Color(0xFFFB7299),
  });

  final ThemeMode mode;
  final Color seed;

  ThemeState copyWith({ThemeMode? mode, Color? seed}) =>
      ThemeState(mode: mode ?? this.mode, seed: seed ?? this.seed);

  /// settings 表中的存储形式: (mode 名称, ARGB 十六进制)
  (String, String) encode() =>
      (mode.name, seed.toARGB32().toRadixString(16).padLeft(8, '0'));

  static ThemeState decode(String? mode, String? seed) {
    final argb = int.tryParse((seed ?? '').replaceFirst('0x', ''), radix: 16);
    return ThemeState(
      mode: ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      ),
      seed: argb == null ? presetSeeds.first : Color(argb),
    );
  }
}

/// 启动时从 settings 读出的主题; bootstrap 中 override
final initialThemeProvider = Provider<ThemeState>((ref) => const ThemeState());

/// 主题持久化回调; bootstrap 中 override 为写 settings 表
final themeSaverProvider = Provider<Future<void> Function(ThemeState)>(
  (ref) => (_) async {},
);

/// 主题状态 (M0.4): 修改后立即生效并持久化, 重启后保持
class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() => ref.read(initialThemeProvider);

  void setMode(ThemeMode mode) => _update(state.copyWith(mode: mode));

  void setSeed(Color seed) => _update(state.copyWith(seed: seed));

  void _update(ThemeState next) {
    state = next;
    ref.read(themeSaverProvider)(next);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);
