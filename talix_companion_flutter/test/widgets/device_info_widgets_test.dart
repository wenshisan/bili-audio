// 设备信息页组件测试。
//
// 覆盖 Figma 669:5665 / 5853 / 6303 / 6574 落地后的关键度量与行为:
// 行高、卡片描边、徽标配色、下拉菜单展开/选中、录音按钮启用与禁用态。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talix_companion/theme/app_colors.dart';
import 'package:talix_companion/widgets/common/common.dart';
import 'package:talix_companion/widgets/device_info_widgets.dart';
import 'package:talix_companion/widgets/recording_bar_widgets.dart';

/// 把被测组件包进最小可渲染环境。宽度给足, 避免 800 宽卡片被压缩。
Widget host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 800, child: child),
        ),
      ),
    );

void main() {
  group('DeviceInfoRow', () {
    testWidgets('纯标题行高 48', (tester) async {
      await tester.pumpWidget(host(
        const DeviceInfoRow(
          label: '序列号',
          trailing: DeviceRowValue(value: 'T-2025-7F2A'),
        ),
      ));

      expect(tester.getSize(find.byType(DeviceInfoRow)).height, 48);
      expect(find.text('T-2025-7F2A'), findsOneWidget);
    });

    testWidgets('带副标题行高 64', (tester) async {
      await tester.pumpWidget(host(
        const DeviceInfoRow(
          label: '文件管理',
          subtitle: '管理录音卡及手机内的录音文件',
          trailing: DeviceRowChevron(),
        ),
      ));

      expect(tester.getSize(find.byType(DeviceInfoRow)).height, 64);
      expect(find.text('管理录音卡及手机内的录音文件'), findsOneWidget);
    });

    testWidgets('isDanger 用危险色渲染标题', (tester) async {
      await tester.pumpWidget(host(
        const DeviceInfoRow(label: '解绑并重置', isDanger: true),
      ));

      final text = tester.widget<Text>(find.text('解绑并重置'));
      expect(text.style?.color, AppColors.dangerText);
    });

    testWidgets('onTap 可触发', (tester) async {
      var tapped = false;
      await tester.pumpWidget(host(
        DeviceInfoRow(label: '文件管理', onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(DeviceInfoRow));
      expect(tapped, isTrue);
    });
  });

  group('DeviceInfoCard', () {
    testWidgets('白底 + 1px #E0E0E0 描边 + 4px 圆角', (tester) async {
      await tester.pumpWidget(host(
        const DeviceInfoCard(
          children: [DeviceInfoRow(label: '设备名称')],
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DeviceInfoCard),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.surface);
      expect(
        (decoration.border as Border).top.color,
        AppColors.cardBorder,
      );
      expect(decoration.borderRadius, BorderRadius.circular(4));
    });
  });

  group('DeviceStatusPill', () {
    testWidgets('charging 用主色浅底 + 主色文字', (tester) async {
      await tester.pumpWidget(host(const DeviceStatusPill.charging()));

      expect(find.text('充电中'), findsOneWidget);
      final text = tester.widget<Text>(find.text('充电中'));
      expect(text.style?.color, AppColors.primary);

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(
        (container.decoration as BoxDecoration).color,
        AppColors.primarySurface,
      );
    });

    testWidgets('updatable 用蓝色浅底 + 蓝色文字', (tester) async {
      await tester.pumpWidget(host(const DeviceStatusPill.updatable()));

      expect(find.text('可升级'), findsOneWidget);
      final text = tester.widget<Text>(find.text('可升级'));
      expect(text.style?.color, AppColors.infoText);
    });
  });

  group('DeviceSelectRow', () {
    const options = [
      DeviceMenuOption(value: 'unlimited', label: '不限制'),
      DeviceMenuOption(value: '8h', label: '8小时'),
      DeviceMenuOption(value: '12h', label: '12小时'),
      DeviceMenuOption(value: '24h', label: '24小时'),
    ];

    testWidgets('折叠态只显示当前选中项', (tester) async {
      await tester.pumpWidget(host(
        DeviceSelectRow<String>(
          label: '录音忘关提醒',
          options: options,
          selected: 'unlimited',
          onSelected: (_) {},
        ),
      ));

      expect(find.text('不限制'), findsOneWidget);
      expect(find.text('8小时'), findsNothing);
    });

    testWidgets('点击行展开菜单, 选中项回传后收起', (tester) async {
      String? picked;
      await tester.pumpWidget(host(
        DeviceSelectRow<String>(
          label: '录音忘关提醒',
          options: options,
          selected: 'unlimited',
          onSelected: (v) => picked = v,
        ),
      ));

      await tester.tap(find.byType(DeviceInfoRow));
      await tester.pumpAndSettle();
      // 菜单展开后四个选项都在 (「不限制」同时出现在行内与菜单里)
      expect(find.text('8小时'), findsOneWidget);
      expect(find.text('24小时'), findsOneWidget);

      await tester.tap(find.text('12小时'));
      await tester.pumpAndSettle();
      expect(picked, '12h');
      expect(find.text('12小时'), findsNothing); // 菜单已收起
    });

    testWidgets('菜单展开不改变行高 (浮层不挤压布局)', (tester) async {
      await tester.pumpWidget(host(
        DeviceSelectRow<String>(
          label: '录音忘关提醒',
          subtitle: '录音达到设定时长前进行提醒',
          options: options,
          selected: 'unlimited',
          onSelected: (_) {},
        ),
      ));

      final before = tester.getSize(find.byType(DeviceSelectRow<String>));
      await tester.tap(find.byType(DeviceInfoRow));
      await tester.pumpAndSettle();
      final after = tester.getSize(find.byType(DeviceSelectRow<String>));

      expect(after, before);
      expect(before.height, 64);
    });
  });

  group('StartRecordingButton', () {
    testWidgets('启用态 312×56 主色填充', (tester) async {
      await tester.pumpWidget(host(
        Align(
          alignment: Alignment.centerRight,
          child: StartRecordingButton(onTap: () {}),
        ),
      ));

      final size = tester.getSize(find.byType(StartRecordingButton));
      expect(size.width, 312);
      expect(size.height, 56);
      expect(find.text('开始录音'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StartRecordingButton),
          matching: find.byType(Container),
        ).first,
      );
      expect(
        (container.decoration as BoxDecoration).color,
        AppColors.primary,
      );
    });

    testWidgets('onTap 为 null 时按中性色渲染 (设备离线禁用态)', (tester) async {
      await tester.pumpWidget(host(
        const Align(
          alignment: Alignment.centerRight,
          child: StartRecordingButton(),
        ),
      ));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StartRecordingButton),
          matching: find.byType(Container),
        ).first,
      );
      expect(
        (container.decoration as BoxDecoration).color,
        AppColors.neutralFill,
      );
    });

    testWidgets('左侧主区与右侧 caret 是两个独立点击目标', (tester) async {
      var started = 0;
      var caretTapped = 0;
      await tester.pumpWidget(host(
        Align(
          alignment: Alignment.centerRight,
          child: StartRecordingButton(
            onTap: () => started++,
            onCaretTap: () => caretTapped++,
          ),
        ),
      ));

      await tester.tap(find.text('开始录音'));
      expect(started, 1);
      expect(caretTapped, 0);

      // caret 在按钮最右侧 48 宽区域内
      final rect = tester.getRect(find.byType(StartRecordingButton));
      await tester.tapAt(Offset(rect.right - 24, rect.center.dy));
      expect(caretTapped, 1);
      expect(started, 1);
    });
  });

  group('RecordingStatusBar', () {
    testWidgets('渲染时长与文件名, 停止按钮可触发', (tester) async {
      var stopped = false;
      await tester.pumpWidget(host(
        Align(
          alignment: Alignment.centerRight,
          child: RecordingStatusBar(
            elapsedText: '00:12:34',
            fileName: '新录音2026-07-17',
            onStop: () => stopped = true,
          ),
        ),
      ));

      expect(find.text('00:12:34'), findsOneWidget);
      expect(find.text('新录音2026-07-17'), findsOneWidget);

      await tester.tap(find.byTooltip('结束录音'));
      expect(stopped, isTrue);
    });

    testWidgets('暂停态提示文案切换为「继续录音」', (tester) async {
      await tester.pumpWidget(host(
        const Align(
          alignment: Alignment.centerRight,
          child: RecordingStatusBar(
            elapsedText: '00:00:05',
            fileName: '新录音2026-07-17',
            isPaused: true,
          ),
        ),
      ));

      expect(find.byTooltip('继续录音'), findsOneWidget);
    });
  });

  group('TalixSwitch.compact', () {
    testWidgets('设备信息页规格 48×24', (tester) async {
      // 用 Align 给松约束 — 页面里开关作为 Row 的 trailing, 同样是松约束
      await tester.pumpWidget(host(
        Align(
          alignment: Alignment.centerRight,
          child: TalixSwitch.compact(value: true, onChanged: (_) {}),
        ),
      ));

      final size = tester.getSize(find.byType(TalixSwitch));
      expect(size.width, 48);
      expect(size.height, 24);
    });
  });
}
