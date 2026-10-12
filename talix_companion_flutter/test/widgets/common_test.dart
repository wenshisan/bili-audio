// Talix 通用组件测试。
//
// 覆盖 Figma 规范落地后的关键行为: 尺寸、颜色、启用/禁用、回调触发。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talix_companion/theme/app_colors.dart';
import 'package:talix_companion/widgets/common/common.dart';

/// 把被测组件包进最小可渲染环境。
Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

/// 取 TalixButton 的实际填充色。
Color? fillOf(WidgetTester tester) => tester
    .widget<Material>(
      find.descendant(
        of: find.byType(TalixButton),
        matching: find.byType(Material),
      ),
    )
    .color;

/// 取 TalixButton 的描边。无描边时返回 null。
BoxBorder? borderOf(WidgetTester tester) => (tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byType(TalixButton),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration)
    .border;

void main() {
  group('TalixButton', () {
    testWidgets('primary 变体使用 Figma 主色且高度为 56', (tester) async {
      await tester.pumpWidget(host(
        TalixButton(label: '分享链接', onPressed: () {}),
      ));

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TalixButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.primary);

      final size = tester.getSize(find.byType(TalixButton));
      expect(size.height, 56);
    });

    testWidgets('secondary 变体使用中性填充与主文字色', (tester) async {
      await tester.pumpWidget(host(
        TalixButton(
          label: '复制链接',
          variant: TalixButtonVariant.secondary,
          onPressed: () {},
        ),
      ));

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TalixButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.neutralFill);

      final text = tester.widget<Text>(find.text('复制链接'));
      expect(text.style?.color, AppColors.textPrimary);
    });

    testWidgets('onPressed 为 null 时不可点击并降级为灰底', (tester) async {
      await tester.pumpWidget(host(
        const TalixButton(label: '禁用'),
      ));

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TalixButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.neutralFill);

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('点击触发回调', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(
        TalixButton(label: '确定', onPressed: () => taps++),
      ));

      await tester.tap(find.byType(TalixButton));
      expect(taps, 1);
    });

    testWidgets('loading 时显示进度指示且屏蔽点击', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(
        TalixButton(label: '提交', loading: true, onPressed: () => taps++),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // 文字被替换掉了, 不应还在树里。
      expect(find.text('提交'), findsNothing);

      await tester.tap(find.byType(TalixButton));
      expect(taps, 0);
    });

    testWidgets('size 决定高度', (tester) async {
      for (final (size, expected) in const [
        (TalixButtonSize.large, 56.0),
        (TalixButtonSize.medium, 44.0),
        (TalixButtonSize.small, 36.0),
      ]) {
        await tester.pumpWidget(host(
          TalixButton(label: 'x', size: size, onPressed: () {}),
        ));
        expect(tester.getSize(find.byType(TalixButton)).height, expected);
      }
    });

    testWidgets('danger 变体红底白字', (tester) async {
      await tester.pumpWidget(host(
        TalixButton(
          label: '解除绑定',
          variant: TalixButtonVariant.danger,
          onPressed: () {},
        ),
      ));

      expect(fillOf(tester), AppColors.danger);
      expect(
        tester.widget<Text>(find.text('解除绑定')).style?.color,
        AppColors.textOnPrimary,
      );
    });

    testWidgets('dangerOutline 变体白底红字红描边', (tester) async {
      await tester.pumpWidget(host(
        TalixButton(
          label: '清除数据',
          variant: TalixButtonVariant.dangerOutline,
          onPressed: () {},
        ),
      ));

      // 白底而非透明: 叠在灰色页面背景上不能发灰。
      expect(fillOf(tester), AppColors.surface);
      expect(
        tester.widget<Text>(find.text('清除数据')).style?.color,
        AppColors.danger,
      );
      expect(borderOf(tester)?.top.color, AppColors.danger);
    });

    testWidgets('neutralOutline 变体透明底灰描边', (tester) async {
      await tester.pumpWidget(host(
        TalixButton(
          label: '取消',
          variant: TalixButtonVariant.neutralOutline,
          onPressed: () {},
        ),
      ));

      expect(fillOf(tester), Colors.transparent);
      expect(borderOf(tester)?.top.color, AppColors.divider);
    });

    testWidgets('borderRadius 覆盖默认胶囊圆角', (tester) async {
      await tester.pumpWidget(host(
        TalixButton(label: '购买', borderRadius: 12, onPressed: () {}),
      ));

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TalixButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('backgroundColor / borderColor 覆盖生效', (tester) async {
      await tester.pumpWidget(host(
        TalixButton(
          label: '开始生成',
          variant: TalixButtonVariant.neutralOutline,
          backgroundColor: const Color(0xFF262626),
          borderColor: const Color(0xFFD1D1D1),
          onPressed: () {},
        ),
      ));

      expect(fillOf(tester), const Color(0xFF262626));
      expect(borderOf(tester)?.top.color, const Color(0xFFD1D1D1));
    });

    testWidgets('disabled* 覆盖让禁用态保持深色底', (tester) async {
      await tester.pumpWidget(host(
        const TalixButton(
          label: '检查中…',
          variant: TalixButtonVariant.dark,
          loading: true,
          disabledBackgroundColor: Color(0xFF111827),
          disabledForegroundColor: Colors.white,
        ),
      ));

      // loading 视为禁用, 但底色不降级成 neutralFill。
      expect(fillOf(tester), const Color(0xFF111827));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('TalixCheckbox', () {
    testWidgets('circle 形态默认 20x20', (tester) async {
      await tester.pumpWidget(host(
        TalixCheckbox(value: false, onChanged: (_) {}),
      ));
      expect(tester.getSize(find.byType(TalixCheckbox)), const Size(20, 20));
    });

    testWidgets('square 形态默认 16x16', (tester) async {
      await tester.pumpWidget(host(
        TalixCheckbox(
          value: false,
          shape: TalixCheckboxShape.square,
          onChanged: (_) {},
        ),
      ));
      expect(tester.getSize(find.byType(TalixCheckbox)), const Size(16, 16));
    });

    testWidgets('选中时填充主色并显示对勾', (tester) async {
      await tester.pumpWidget(host(
        TalixCheckbox(value: true, onChanged: (_) {}),
      ));

      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(TalixCheckbox),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary);
      expect(find.byType(TalixCheckMark), findsOneWidget);
    });

    testWidgets('未选中时无填充无对勾', (tester) async {
      await tester.pumpWidget(host(
        TalixCheckbox(value: false, onChanged: (_) {}),
      ));

      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(TalixCheckbox),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.border, isNotNull);
      expect(find.byType(TalixCheckMark), findsNothing);
    });

    testWidgets('点击回传取反值', (tester) async {
      bool? received;
      await tester.pumpWidget(host(
        TalixCheckbox(value: false, onChanged: (v) => received = v),
      ));

      await tester.tap(find.byType(TalixCheckbox));
      expect(received, isTrue);
    });
  });

  group('TalixRadio', () {
    testWidgets('选中项显示对勾, 未选中项不显示', (tester) async {
      await tester.pumpWidget(host(
        const Column(
          children: [
            TalixRadio<String>(value: 'a', groupValue: 'a'),
            TalixRadio<String>(value: 'b', groupValue: 'a'),
          ],
        ),
      ));

      // 两个 radio 只有一个画出对勾。
      expect(find.byType(TalixCheckMark), findsOneWidget);
    });

    testWidgets('点击未选中项回传自身 value', (tester) async {
      String? picked;
      await tester.pumpWidget(host(
        Column(
          children: [
            TalixRadio<String>(
              value: 'a',
              groupValue: 'a',
              onChanged: (v) => picked = v,
            ),
            TalixRadio<String>(
              value: 'b',
              groupValue: 'a',
              onChanged: (v) => picked = v,
            ),
          ],
        ),
      ));

      await tester.tap(find.byType(TalixRadio<String>).last);
      expect(picked, 'b');
    });

    testWidgets('默认热区 24x24', (tester) async {
      await tester.pumpWidget(host(
        const TalixRadio<int>(value: 1, groupValue: 1),
      ));
      expect(tester.getSize(find.byType(TalixRadio<int>)), const Size(24, 24));
    });
  });

  group('TalixSwitch', () {
    testWidgets('打开时轨道为主色', (tester) async {
      await tester.pumpWidget(host(
        TalixSwitch(value: true, onChanged: (_) {}),
      ));
      await tester.pumpAndSettle();

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary);
    });

    testWidgets('关闭时轨道为中性色', (tester) async {
      await tester.pumpWidget(host(
        TalixSwitch(value: false, onChanged: (_) {}),
      ));
      await tester.pumpAndSettle();

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.neutralFill);
    });

    testWidgets('尺寸为 iOS 标准 51x31', (tester) async {
      await tester.pumpWidget(host(
        TalixSwitch(value: false, onChanged: (_) {}),
      ));
      expect(tester.getSize(find.byType(TalixSwitch)), const Size(51, 31));
    });

    testWidgets('点击回传取反值', (tester) async {
      bool? received;
      await tester.pumpWidget(host(
        TalixSwitch(value: false, onChanged: (v) => received = v),
      ));

      await tester.tap(find.byType(TalixSwitch));
      expect(received, isTrue);
    });
  });

  group('TalixOptionRow', () {
    testWidgets('纯标题行高 64', (tester) async {
      await tester.pumpWidget(host(
        const SizedBox(
          width: 402,
          child: TalixOptionRow(title: '录音'),
        ),
      ));
      expect(tester.getSize(find.byType(TalixOptionRow)).height, 64);
    });

    testWidgets('带单行副标题行高 88', (tester) async {
      await tester.pumpWidget(host(
        const SizedBox(
          width: 402,
          child: TalixOptionRow(title: '自动', subtitle: '智能匹配适合的模型'),
        ),
      ));
      expect(tester.getSize(find.byType(TalixOptionRow)).height, 88);
    });

    testWidgets('showDivider 为 false 时不绘制分隔线', (tester) async {
      await tester.pumpWidget(host(
        const SizedBox(
          width: 402,
          child: TalixOptionRow(title: '录音', showDivider: false),
        ),
      ));
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('trailing 被渲染, onTap 可触发', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(
        SizedBox(
          width: 402,
          child: TalixOptionRow(
            title: '录音',
            trailing: const TalixRowValueLabel(value: 'MP3'),
            onTap: () => taps++,
          ),
        ),
      ));

      expect(find.text('MP3'), findsOneWidget);
      await tester.tap(find.text('录音'));
      expect(taps, 1);
    });
  });
}
