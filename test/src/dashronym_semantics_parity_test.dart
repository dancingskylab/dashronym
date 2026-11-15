// Characterization tests for the trigger, the stock card and its close
// control. They pin behavior that must survive internal rewrites of the card,
// so they only use finders that do not depend on a design system:
// find.byTooltip, find.bySemanticsLabel and find.byType(DashronymTooltipCard).
import 'dart:ui' show PointerDeviceKind, SemanticsAction, Tristate;

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _closeTooltip = 'Hide definition for SDK';

Future<void> _pumpTrigger(
  WidgetTester tester, {
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [DashronymLocalizations.delegate],
      supportedLocales: DashronymLocalizations.supportedLocales,
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: Center(
            child: FocusTraversalGroup(
              child: const DashronymInline(
                acronym: 'SDK',
                description: 'Software Development Kit',
                theme: DashronymTheme(enableHover: false),
                textStyle: TextStyle(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openByTap(WidgetTester tester) async {
  await tester.tap(find.text('SDK').first);
  await tester.pumpAndSettle();
  expect(find.byType(DashronymTooltipCard), findsOneWidget);
}

Finder get _cardTitle => find.descendant(
  of: find.byType(DashronymTooltipCard),
  matching: find.text('SDK'),
);

FocusNode? get _primaryFocus => FocusManager.instance.primaryFocus;

void main() {
  testWidgets('trigger exposes a button with expanded state and hints', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpTrigger(tester);

    var trigger = tester.getSemantics(find.bySemanticsLabel('SDK').first);
    expect(trigger.flagsCollection.isButton, isTrue);
    expect(trigger.flagsCollection.isExpanded, Tristate.isFalse);
    expect(trigger.hint, 'Double tap to show definition for SDK.');
    expect(trigger.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    await _openByTap(tester);

    trigger = tester.getSemantics(find.bySemanticsLabel('SDK').first);
    expect(trigger.flagsCollection.isExpanded, Tristate.isTrue);
    expect(trigger.hint, 'Double tap to hide definition for SDK.');
    semantics.dispose();
  });

  testWidgets('card exposes its definition as one labeled container', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpTrigger(tester);
    await _openByTap(tester);

    final card = tester.getSemantics(find.byType(DashronymTooltipCard));
    expect(card.label, 'Definition for SDK');
    expect(card.value, 'Software Development Kit');
    semantics.dispose();
  });

  testWidgets('close control is an enabled, focusable, labeled button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpTrigger(tester);
    await _openByTap(tester);

    final close = tester.getSemantics(find.byTooltip(_closeTooltip));
    final data = close.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.flagsCollection.isFocused, isNot(Tristate.none));
    expect(data.tooltip, _closeTooltip);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(close.rect.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(close.rect.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    semantics.dispose();
  });

  testWidgets('a tap near the edge of the close target closes the card', (
    tester,
  ) async {
    await _pumpTrigger(tester);
    await _openByTap(tester);

    // 22 px from the center lies outside a 40 px visual button but inside the
    // 48 px minimum interactive target.
    final center = tester.getCenter(find.byTooltip(_closeTooltip));
    await tester.tapAt(center + const Offset(0, 22));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'close control sits at the trailing edge in ${direction.name}',
      (
        tester,
      ) async {
        await _pumpTrigger(tester, textDirection: direction);
        await _openByTap(tester);

        final closeX = tester.getCenter(find.byTooltip(_closeTooltip)).dx;
        final titleX = tester.getCenter(_cardTitle).dx;
        if (direction == TextDirection.ltr) {
          expect(closeX, greaterThan(titleX));
        } else {
          expect(closeX, lessThan(titleX));
        }
      },
    );
  }

  testWidgets('Space on the focused close control closes and refocuses', (
    tester,
  ) async {
    await _pumpTrigger(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);
    final triggerFocus = _primaryFocus;
    expect(triggerFocus?.debugLabel, 'DashronymInline');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_primaryFocus, isNot(same(triggerFocus)));

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
    expect(_primaryFocus, same(triggerFocus));
  });

  testWidgets('hovering the close control reveals its tooltip text', (
    tester,
  ) async {
    await _pumpTrigger(tester);
    await _openByTap(tester);
    expect(find.text(_closeTooltip), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byTooltip(_closeTooltip)));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text(_closeTooltip), findsOneWidget);
    expect(find.byType(DashronymTooltipCard), findsOneWidget);
  });
}
