// BindingViewModel 测试。
//
// 重点覆盖 dispose 竞态: simulateScanInDebug() 的 2 秒定时器在用户提前返回
// (ViewModel 已 dispose) 之后触发, 不应抛 "used after being disposed"。

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talix_companion/viewmodels/binding_viewmodel.dart';

void main() {
  group('BindingViewModel', () {
    test('初始状态为 searching', () {
      final vm = BindingViewModel();
      expect(vm.state, AddDeviceState.searching);
      vm.dispose();
    });

    test('模拟扫描 2 秒后切到 found', () {
      fakeAsync((elapse) {
        final vm = BindingViewModel();
        vm.simulateScanInDebug();

        expect(vm.state, AddDeviceState.searching);
        elapse(const Duration(seconds: 2));
        expect(vm.state, AddDeviceState.found);

        vm.dispose();
      });
    });

    test('定时器未触发就 dispose 不抛异常', () {
      fakeAsync((elapse) {
        final vm = BindingViewModel();
        vm.simulateScanInDebug();

        // 用户 2 秒内就点了返回。
        elapse(const Duration(milliseconds: 500));
        vm.dispose();

        // 定时器原本会在这里触发 notifyListeners() 并抛错。
        expect(() => elapse(const Duration(seconds: 5)), returnsNormally);
      });
    });

    test('dispose 后 notifyListeners 静默 no-op', () {
      final vm = BindingViewModel();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.markDeviceFound();
      expect(notified, 1);

      vm.dispose();
      // 已 disposed, 不应再抛异常也不应再通知。
      expect(() => vm.markDeviceNotFound(), returnsNormally);
      expect(notified, 1);
    });

    test('重复 simulateScanInDebug 不叠加定时器', () {
      fakeAsync((elapse) {
        final vm = BindingViewModel();
        var notified = 0;
        vm.addListener(() => notified++);

        // 连点三次"重新扫描"。
        vm.simulateScanInDebug();
        vm.simulateScanInDebug();
        vm.simulateScanInDebug();

        elapse(const Duration(seconds: 5));

        // 只应切换一次状态。
        expect(vm.state, AddDeviceState.found);
        expect(notified, 1);

        vm.dispose();
      });
    });

    test('auto=false 时立即切换, 不等定时器', () {
      final vm = BindingViewModel();
      vm.simulateScanInDebug(auto: false, nextResult: AddDeviceState.notFound);
      expect(vm.state, AddDeviceState.notFound);
      vm.dispose();
    });

    test('retryScan 回到 searching 并重新开始扫描', () {
      fakeAsync((elapse) {
        final vm = BindingViewModel();
        vm.markDeviceNotFound();
        expect(vm.state, AddDeviceState.notFound);

        vm.retryScan();
        expect(vm.state, AddDeviceState.searching);

        elapse(const Duration(seconds: 2));
        expect(vm.state, AddDeviceState.found);

        vm.dispose();
      });
    });

    test('_setState 相同值不重复通知', () {
      final vm = BindingViewModel();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.markDeviceFound();
      vm.markDeviceFound();
      expect(notified, 1);

      vm.dispose();
    });

    test('假设备数据保持稳定', () {
      final vm = BindingViewModel();
      expect(vm.deviceSerial, 'talix2026A0008');
      expect(vm.deviceName, isNotEmpty);
      vm.dispose();
    });
  });
}
