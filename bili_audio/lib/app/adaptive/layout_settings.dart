import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../providers.dart';
import 'system_car.dart';

/// 设置里的车机布局开关。自动只在系统报告车载界面时生效。
enum CarLayoutMode {
  auto,
  on,
  off;

  static CarLayoutMode parse(String? raw) => switch (raw) {
        'on' => CarLayoutMode.on,
        'off' => CarLayoutMode.off,
        _ => CarLayoutMode.auto,
      };

  String get storageValue => name;
}

/// 分隔比例与车机开关。车机是否显示还要看 [systemCar]。
class LayoutSettings {
  const LayoutSettings({
    this.splitRatio = 0.62,
    this.carMode = CarLayoutMode.auto,
    this.systemCar = false,
  });

  final double splitRatio;
  final CarLayoutMode carMode;
  final bool systemCar;

  bool get carLayout => switch (carMode) {
        CarLayoutMode.on => true,
        CarLayoutMode.off => false,
        CarLayoutMode.auto => systemCar,
      };

  LayoutSettings copyWith({
    double? splitRatio,
    CarLayoutMode? carMode,
    bool? systemCar,
  }) =>
      LayoutSettings(
        splitRatio: splitRatio ?? this.splitRatio,
        carMode: carMode ?? this.carMode,
        systemCar: systemCar ?? this.systemCar,
      );
}

/// 纯函数，便于单测：宽度不能单独打开车机布局。
bool resolveCarLayout(CarLayoutMode mode, bool systemCar) =>
    LayoutSettings(carMode: mode, systemCar: systemCar).carLayout;

class LayoutSettingsNotifier extends Notifier<LayoutSettings> {
  var _epoch = 0;

  @override
  LayoutSettings build() {
    _load();
    return const LayoutSettings();
  }

  Future<void> _load() async {
    final token = ++_epoch;
    final db = ref.read(databaseProvider);
    final ratioRaw = await db.settingsDao.get(_splitKey);
    final modeRaw = await db.settingsDao.get(_carKey);
    final system = await loadSystemCarUi();
    if (token != _epoch || !ref.mounted) return;
    final ratio = double.tryParse(ratioRaw ?? '') ?? 0.62;
    state = LayoutSettings(
      splitRatio: ratio.clamp(0.4, 0.75),
      carMode: CarLayoutMode.parse(modeRaw),
      systemCar: system,
    );
  }

  Future<void> setSplitRatio(double ratio) => _write(
        state.copyWith(splitRatio: ratio.clamp(0.4, 0.75)),
        (db) => db.settingsDao.set(_splitKey, ratio.clamp(0.4, 0.75).toString()),
      );

  Future<void> setCarMode(CarLayoutMode mode) => _write(
        state.copyWith(carMode: mode),
        (db) => db.settingsDao.set(_carKey, mode.storageValue),
      );

  Future<void> _write(
    LayoutSettings next,
    Future<void> Function(AppDatabase db) persist,
  ) async {
    _epoch++;
    state = next;
    final db = ref.read(databaseProvider);
    await persist(db);
  }
}

const _splitKey = 'layout.split_ratio';
const _carKey = 'layout.car_mode';

final layoutSettingsProvider =
    NotifierProvider<LayoutSettingsNotifier, LayoutSettings>(
  LayoutSettingsNotifier.new,
);
