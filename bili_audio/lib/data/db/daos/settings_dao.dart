import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// 获取设置值
  Future<String?> get(String key) async {
    final result = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// 设置值
  Future<void> set(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: key,
        value: value,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 批量设置
  Future<void> setBatch(Map<String, String> values) async {
    await transaction(() async {
      for (final entry in values.entries) {
        await set(entry.key, entry.value);
      }
    });
  }

  /// 删除设置
  Future<int> remove(String key) {
    return (delete(settings)..where((s) => s.key.equals(key))).go();
  }

  /// 获取所有设置
  Future<Map<String, String>> getAll() async {
    final list = await select(settings).get();
    return {for (final item in list) item.key: item.value};
  }

  /// 清空所有设置
  Future<int> clear() {
    return delete(settings).go();
  }

  // 便捷方法

  Future<String?> getThemeMode() => get('theme_mode');
  Future<void> setThemeMode(String mode) => set('theme_mode', mode);

  Future<String?> getThemeSeed() => get('theme_seed');
  Future<void> setThemeSeed(String seed) => set('theme_seed', seed);

  Future<int> getCacheMaxSize() async {
    final value = await get('cache_max_size');
    return value != null ? int.tryParse(value) ?? 1073741824 : 1073741824;
  }

  Future<void> setCacheMaxSize(int size) => set('cache_max_size', size.toString());

  Future<int> getDefaultQuality() async {
    final value = await get('default_quality');
    return value != null ? int.tryParse(value) ?? 30232 : 30232;
  }

  Future<void> setDefaultQuality(int quality) =>
      set('default_quality', quality.toString());
}
