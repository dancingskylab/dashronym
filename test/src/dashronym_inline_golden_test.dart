import 'dart:ui';

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_constraints.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Light host colors and body text, standing in for a typical app.
const _hostBackground = Color(0xFFFFFBFE);
const _hostText = TextStyle(
  color: Color(0xFF1C1B1F),
  fontSize: 14,
  height: 1.43,
  letterSpacing: 0.25,
);

/// Dark host colors, as a dark theme would set them.
const _darkBackground = Color(0xFF1C1B1F);
const _darkText = Color(0xFFE6E1E5);

Future<void> _pumpInline(
  WidgetTester tester, {
  DashronymTheme? theme,
  TextDirection textDirection = TextDirection.ltr,
  Alignment alignment = Alignment.center,
  Size surfaceSize = const Size(360, 640),
  double? height,
  DashronymTooltipBuilder? tooltipBuilder,
  Color background = _hostBackground,
  Color? textColor,
  bool highContrast = false,
  TextScaler? textScaler,
  Widget? body,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    TestWidgetsApp(
      color: background,
      textStyle: _hostText.copyWith(color: textColor),
      localizationsDelegates: const [DashronymLocalizations.delegate],
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            highContrast: highContrast,
            textScaler: textScaler,
          ),
          child: Directionality(
            textDirection: textDirection,
            child: ColoredBox(
              color: background,
              child: SizedBox(
                height: height ?? surfaceSize.height,
                child: Align(
                  alignment: alignment,
                  child:
                      body ??
                      DashronymInline(
                        acronym: 'SDK',
                        description: 'Software Development Kit',
                        theme: theme ?? const DashronymTheme(),
                        textStyle: TextStyle(fontSize: 18, color: textColor),
                        tooltipBuilder: tooltipBuilder,
                      ),
                ),
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
  // Goldens must not include the debug-mode banner.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  testWidgets('DashronymInline golden - default state', (tester) async {
    await _pumpInline(tester);
    await expectLater(
      find.byType(TestWidgetsApp),
      matchesGoldenFile('goldens/dashronym_inline_default.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - open state', (tester) async {
    await _pumpInline(tester);
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(TestWidgetsApp),
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
      find.byType(TestWidgetsApp),
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
      find.byType(TestWidgetsApp),
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
      find.byType(TestWidgetsApp),
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
      find.byType(TestWidgetsApp),
      matchesGoldenFile('goldens/dashronym_inline_landscape.png'),
    );
  }, tags: const ['golden']);

  Future<void> openAndMatch(WidgetTester tester, String golden) async {
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(TestWidgetsApp),
      matchesGoldenFile('goldens/$golden'),
    );
  }

  testWidgets('DashronymInline golden - dark host', (tester) async {
    await _pumpInline(
      tester,
      background: _darkBackground,
      textColor: _darkText,
    );
    await openAndMatch(tester, 'dashronym_inline_dark_open.png');
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - high contrast, keyboard', (
    tester,
  ) async {
    await _pumpInline(tester, highContrast: true);
    // Tab shows the trigger's focus highlight and opens the card.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(TestWidgetsApp),
      matchesGoldenFile('goldens/dashronym_inline_high_contrast.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - focused close button', (
    tester,
  ) async {
    await _pumpInline(tester);
    // The first Tab opens the card; the second reaches its close button.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TestWidgetsApp),
      matchesGoldenFile('goldens/dashronym_close_focused.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - hovered close button', (
    tester,
  ) async {
    final highlight = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = highlight);
    await _pumpInline(tester, theme: const DashronymTheme(enableHover: false));
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(
      location: tester.getCenter(find.byTooltip('Hide definition for SDK')),
    );
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(TestWidgetsApp),
      matchesGoldenFile('goldens/dashronym_close_hovered.png'),
    );
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - two acronyms in mixed RTL text', (
    tester,
  ) async {
    await _pumpInline(
      tester,
      textDirection: TextDirection.rtl,
      body: DashronymText(
        'استخدم SDK and API الآن',
        registry: DashronymRegistry({
          'SDK': 'Software Development Kit',
          'API': 'Application Programming Interface',
        }),
        config: const DashronymConfig(enableBareAcronyms: true),
      ),
    );
    await openAndMatch(tester, 'dashronym_text_rtl_two.png');
  }, tags: const ['golden']);

  testWidgets('DashronymInline golden - text scaled to 200%', (tester) async {
    await _pumpInline(tester, textScaler: const TextScaler.linear(2));
    await openAndMatch(tester, 'dashronym_inline_text_scale_2.png');
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
        return DecoratedBox(
          key: customTooltipKey,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
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
