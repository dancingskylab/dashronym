import 'dart:ui';

import 'package:dashronym/dashronym.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_constraints.dart';

Future<void> _pumpInline(
  WidgetTester tester, {
  DashronymTheme? theme,
  TextDirection textDirection = TextDirection.ltr,
  Alignment alignment = Alignment.center,
  Size surfaceSize = const Size(360, 640),
  double? height,
  DashronymTooltipBuilder? tooltipBuilder,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DashronymLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: SizedBox(
            height: height ?? surfaceSize.height,
            child: Align(
              alignment: alignment,
              child: DashronymInline(
                acronym: 'SDK',
                description: 'Software Development Kit',
                theme: theme ?? const DashronymTheme(),
                textStyle: const TextStyle(fontSize: 18),
                tooltipBuilder: tooltipBuilder,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('DashronymInline golden - default state', (tester) async {
    await _pumpInline(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashronym_inline_default.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - open state', (tester) async {
    await _pumpInline(tester);
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashronym_inline_open.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - hovered state', (tester) async {
    const hoverTheme = DashronymTheme(
      enableHover: true,
      hoverShowDelay: Duration(milliseconds: 40),
      hoverHideDelay: Duration(milliseconds: 40),
    );
    await _pumpInline(tester, theme: hoverTheme);

    final trigger = find.text('SDK');
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(trigger));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashronym_inline_hover.png'),
    );

    await gesture.removePointer();
    await tester.pump(const Duration(milliseconds: 120));
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - RTL open state', (tester) async {
    await _pumpInline(tester, textDirection: TextDirection.rtl);
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashronym_inline_rtl_open.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - flipped above trigger', (tester) async {
    await _pumpInline(
      tester,
      alignment: Alignment.bottomCenter,
      height: 160,
      theme: const DashronymTheme(tooltipOffset: Offset(0, 8)),
    );
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashronym_inline_flipped.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - landscape layout', (tester) async {
    await _pumpInline(
      tester,
      surfaceSize: const Size(640, 360),
      height: 360,
      theme: const DashronymTheme(tooltipMinWidth: 200),
    );
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashronym_inline_landscape.png'),
    );
  }, tags: const ['golden']);

  testWidgets('Custom tooltip builder clamps width in landscape', (
    tester,
  ) async {
    const customTooltipKey = ValueKey('custom-tooltip');
    await _pumpInline(
      tester,
      surfaceSize: const Size(640, 360),
      height: 360,
      tooltipBuilder: (context, details) {
        return Material(
          key: customTooltipKey,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 900,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Custom tooltip content that would otherwise overflow horizontally when space is tight.',
              ),
            ),
          ),
        );
      },
    );
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final renderBox = tester.renderObject<RenderBox>(
      find.byKey(customTooltipKey),
    );
    final width = renderBox.size.width;
    final maxExpectedWidth = 640 - DashronymTooltipConstraints.outerGutter * 2;
    expect(width, lessThanOrEqualTo(maxExpectedWidth));
    expect(width, closeTo(600, 0.1));
  });
}
