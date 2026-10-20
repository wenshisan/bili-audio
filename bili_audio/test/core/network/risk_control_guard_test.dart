import 'package:flutter_test/flutter_test.dart';
import 'package:bili_audio/core/network/risk_control_guard.dart';

void main() {
  group('RiskControlGuard', () {
    test('初始状态不在冷却期', () {
      final guard = RiskControlGuard();
      expect(guard.inCooldown, false);
      expect(guard.remaining, Duration.zero);
    });

    test('累计 threshold 次进入冷却', () {
      var now = DateTime(2024, 1, 1);
      final guard = RiskControlGuard(
        threshold: 3,
        cooldown: const Duration(seconds: 60),
        clock: () => now,
      );

      guard.recordHit('/api/search');
      guard.recordHit('/api/search');
      expect(guard.inCooldown, false);

      guard.recordHit('/api/search'); // 第3次触发
      expect(guard.inCooldown, true);
      expect(guard.remaining.inSeconds, 60);

      now = now.add(const Duration(seconds: 30));
      expect(guard.inCooldown, true);
      expect(guard.remaining.inSeconds, 30);

      now = now.add(const Duration(seconds: 31));
      expect(guard.inCooldown, false);
    });

    test('window 外的 hit 不计入', () {
      var now = DateTime(2024, 1, 1);
      final guard = RiskControlGuard(
        threshold: 3,
        window: const Duration(seconds: 60),
        clock: () => now,
      );

      guard.recordHit('/api/search');
      now = now.add(const Duration(seconds: 61)); // 超出 window
      guard.recordHit('/api/search');
      guard.recordHit('/api/search');

      expect(guard.inCooldown, false); // 只有2次有效
    });

    test('进入冷却后 hits 清空', () {
      var now = DateTime(2024, 1, 1);
      final guard = RiskControlGuard(
        threshold: 2,
        cooldown: const Duration(seconds: 10),
        clock: () => now,
      );

      guard.recordHit('/api/search');
      guard.recordHit('/api/search'); // 触发冷却

      now = now.add(const Duration(seconds: 11)); // 冷却结束

      guard.recordHit('/api/search');
      expect(guard.inCooldown, false); // 计数已重置
    });

    test('onEvent 回调接收日志', () {
      final events = <String>[];
      final guard = RiskControlGuard(
        threshold: 2,
        onEvent: events.add,
      );

      guard.recordHit('/api/search');
      guard.recordHit('/api/search');

      expect(events.length, 3); // 2个 hit + 1个 cooldown
      expect(events[0], contains('hit #1'));
      expect(events[1], contains('hit #2'));
      expect(events[2], contains('enter cooldown'));
    });

    test('reset 清空状态', () {
      final guard = RiskControlGuard(threshold: 2);
      guard.recordHit('/api/search');
      guard.recordHit('/api/search');
      expect(guard.inCooldown, true);

      guard.reset();
      expect(guard.inCooldown, false);
    });
  });
}
