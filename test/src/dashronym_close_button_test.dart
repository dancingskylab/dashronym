// The widgets-only tooltip card and its close button.
import 'dart:ui' show PointerDeviceKind;

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_close_button.dart';
import 'package:dashronym/src/dashronym_glyphs.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _closeLabel = 'Hide definition for SDK';
const _black = Color(0xFF000000);

Future<void> _pumpCard(
  WidgetTester tester, {
  DashronymTheme theme = const DashronymTheme(),
  VoidCallback? onClose,
  bool highContrast = false,
  double width = 360,
}) {
  return tester.pumpWidget(
    TestWidgetsApp(
      textStyle: const TextStyle(color: _black, fontSize: 14),
      localizationsDelegates: const [DashronymLocalizations.delegate],
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: Center(
          child: SizedBox(
            width: width,
            child: DashronymTooltipCard(
              acronym: 'SDK',
              description: 'Software Development Kit',
              theme: theme,
              onClose: onClose ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

/// The decoration of the close button's 40 px circle.
///
/// Matched by shape, because the hover bubble (an overlay child, and so an
/// element-tree descendant of the button) has a decoration of its own.
BoxDecoration _closeDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(DashronymCloseButton),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    ),
  );
  return box.decoration as BoxDecoration;
}

void main() {
  testWidgets('hover and press tint the close button', (tester) async {
    // Hover highlights need traditional (pointer) highlight mode, which test
    // apps on the default mobile platform only enter after a click or key.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await _pumpCard(tester);
    expect(_closeDecoration(tester).color, isNull);

    final center = tester.getCenter(find.byTooltip(_closeLabel));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(center);
    await tester.pump();
    expect(_closeDecoration(tester).color, _black.withValues(alpha: 0.08));

    await mouse.down(center);
    await tester.pump(kPressTimeout);
    expect(_closeDecoration(tester).color, _black.withValues(alpha: 0.10));

    await mouse.up();
    await tester.pump();
    expect(_closeDecoration(tester).color, _black.withValues(alpha: 0.08));
  });

  testWidgets('a cancelled tap clears the pressed tint', (tester) async {
    var closed = false;
    await _pumpCard(tester, onClose: () => closed = true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byTooltip(_closeLabel)),
    );
    // The tooltip's long-press recognizer competes for the pointer, so the
    // tap reports a press only after the press timeout.
    await tester.pump(kPressTimeout);
    expect(_closeDecoration(tester).color, _black.withValues(alpha: 0.10));

    await gesture.moveBy(const Offset(0, 200));
    await gesture.up();
    await tester.pump();
    expect(_closeDecoration(tester).color, isNull);
    expect(closed, isFalse);
  });

  for (final highContrast in [false, true]) {
    testWidgets('keyboard focus draws a ring (high contrast: $highContrast)', (
      tester,
    ) async {
      await _pumpCard(tester, highContrast: highContrast);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final border = _closeDecoration(tester).border! as Border;
      expect(border.top.color, _black);
      expect(border.top.width, highContrast ? 3 : 2);
    });
  }

  testWidgets('Enter, Space and ButtonActivateIntent activate the button', (
    tester,
  ) async {
    var presses = 0;
    await _pumpCard(tester, onClose: () => presses++);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    final focused = FocusManager.instance.primaryFocus!.context!;
    Actions.invoke(focused, const ButtonActivateIntent());
    expect(presses, 3);
  });

  testWidgets('custom icons replace the built-in glyphs', (tester) async {
    const info = IconData(0xe001);
    const close = IconData(0xe002);
    await _pumpCard(
      tester,
      theme: const DashronymTheme(cardIcon: info, cardCloseIcon: close),
    );

    expect(find.byIcon(info), findsOneWidget);
    expect(find.byIcon(close), findsOneWidget);
    expect(find.byType(DashronymGlyphIcon), findsNothing);
  });

  testWidgets('built-in glyphs are decorative', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester);

    expect(find.byType(DashronymGlyphIcon), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(DashronymGlyphIcon),
        matching: find.byType(ExcludeSemantics),
      ),
      findsNWidgets(2),
    );
    semantics.dispose();
  });

  testWidgets('narrow cards drop the decorative glyph', (tester) async {
    await _pumpCard(tester, width: 180);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DashronymGlyphIcon && widget.glyph == DashronymGlyph.info,
      ),
      findsNothing,
    );
    expect(find.byTooltip(_closeLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high contrast or an explicit side outlines the card', (
    tester,
  ) async {
    ShapeBorder? outline() {
      final finder = find.descendant(
        of: find.byType(DashronymTooltipCard),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox && widget.decoration is ShapeDecoration,
        ),
      );
      if (finder.evaluate().isEmpty) return null;
      return (tester.widget<DecoratedBox>(finder).decoration as ShapeDecoration)
          .shape;
    }

    await _pumpCard(tester);
    expect(outline(), isNull);

    await _pumpCard(tester, highContrast: true);
    expect(
      (outline()! as RoundedRectangleBorder).side,
      const BorderSide(color: _black),
    );

    const side = BorderSide(color: Color(0xFF6750A4), width: 2);
    await _pumpCard(tester, theme: const DashronymTheme(cardBorderSide: side));
    expect((outline()! as RoundedRectangleBorder).side, side);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    testWidgets('the tooltip bubble uses ${platform.name} metrics', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await _pumpCard(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byTooltip(_closeLabel)));
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(find.text(_closeLabel));
      final mobile = platform == TargetPlatform.android;
      expect(label.style?.fontSize, mobile ? 14 : 12);
    });
  }

  testWidgets('Escape closes the close-button bubble before the card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        localizationsDelegates: [DashronymLocalizations.delegate],
        home: Center(
          child: DashronymInline(
            acronym: 'SDK',
            description: 'Software Development Kit',
            theme: DashronymTheme(enableHover: false),
            textStyle: TextStyle(),
          ),
        ),
      ),
    );
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byTooltip(_closeLabel)));
    await tester.pumpAndSettle();
    expect(find.text(_closeLabel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(_closeLabel), findsNothing);
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
  });
}
