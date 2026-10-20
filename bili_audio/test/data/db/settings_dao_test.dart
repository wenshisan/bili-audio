import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/data/db/app_database.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsDao', () {
    test('默认设置已插入', () async {
      final themeMode = await db.settingsDao.getThemeMode();
      expect(themeMode, 'system');

      final themeSeed = await db.settingsDao.getThemeSeed();
      expect(themeSeed, '0xFF2196F3');

      final cacheMaxSize = await db.settingsDao.getCacheMaxSize();
      expect(cacheMaxSize, 1073741824);

      final defaultQuality = await db.settingsDao.getDefaultQuality();
      expect(defaultQuality, 30232);
    });

    test('设置和获取值', () async {
      await db.settingsDao.set('test_key', 'test_value');

      final value = await db.settingsDao.get('test_key');
      expect(value, 'test_value');
    });

    test('更新现有设置', () async {
      await db.settingsDao.set('test_key', 'old_value');
      await db.settingsDao.set('test_key', 'new_value');

      final value = await db.settingsDao.get('test_key');
      expect(value, 'new_value');
    });

    test('批量设置', () async {
      await db.settingsDao.setBatch({
        'key1': 'value1',
        'key2': 'value2',
        'key3': 'value3',
      });

      final value1 = await db.settingsDao.get('key1');
      final value2 = await db.settingsDao.get('key2');
      final value3 = await db.settingsDao.get('key3');

      expect(value1, 'value1');
      expect(value2, 'value2');
      expect(value3, 'value3');
    });

    test('删除设置', () async {
      await db.settingsDao.set('test_key', 'test_value');
      await db.settingsDao.remove('test_key');

      final value = await db.settingsDao.get('test_key');
      expect(value, matcher.isNull);
    });

    test('获取所有设置', () async {
      final all = await db.settingsDao.getAll();
      expect(all, isNotEmpty);
      expect(all['theme_mode'], 'system');
    });

    test('便捷方法: 主题模式', () async {
      await db.settingsDao.setThemeMode('dark');
      final mode = await db.settingsDao.getThemeMode();
      expect(mode, 'dark');
    });

    test('便捷方法: 主题种子色', () async {
      await db.settingsDao.setThemeSeed('0xFFFF5722');
      final seed = await db.settingsDao.getThemeSeed();
      expect(seed, '0xFFFF5722');
    });

    test('便捷方法: 缓存最大值', () async {
      await db.settingsDao.setCacheMaxSize(2147483648);
      final size = await db.settingsDao.getCacheMaxSize();
      expect(size, 2147483648);
    });

    test('便捷方法: 默认音质', () async {
      await db.settingsDao.setDefaultQuality(30280);
      final quality = await db.settingsDao.getDefaultQuality();
      expect(quality, 30280);
    });

    test('不存在的设置返回 null', () async {
      final value = await db.settingsDao.get('non_existent_key');
      expect(value, matcher.isNull);
    });
  });
}
