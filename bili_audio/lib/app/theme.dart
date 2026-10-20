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
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
  );
}

@immutable
class ThemeState {
  const ThemeState({this.mode = ThemeMode.system, this.seed = const Color(0xFFFB7299)});

  final ThemeMode mode;
  final Color seed;

  ThemeState copyWith({ThemeMode? mode, Color? seed}) =>
      ThemeState(mode: mode ?? this.mode, seed: seed ?? this.seed);
}

/// 主题状态。持久化留待 M0.3 的 settings 表接入后补上。
class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() => const ThemeState();

  void setMode(ThemeMode mode) => state = state.copyWith(mode: mode);

  void setSeed(Color seed) => state = state.copyWith(seed: seed);
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(ThemeController.new);
