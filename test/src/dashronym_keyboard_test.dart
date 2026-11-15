// Keyboard interaction between Dashronym tooltips and enclosing routes.
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a dialog that contains an autofocused text field and a trigger.
Future<void> _pumpDialog(
  WidgetTester tester, {
  required DashronymTheme theme,
  bool includeTextField = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [DashronymLocalizations.delegate],
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (includeTextField) const TextField(autofocus: true),
                      DashronymInline(
                        acronym: 'SDK',
                        description: 'Software Development Kit',
                        theme: theme,
                        textStyle: const TextStyle(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: const Text('Open dialog'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open dialog'));
  await tester.pumpAndSettle();
  expect(find.byType(Dialog), findsOneWidget);
}

void main() {
  testWidgets('Escape on a hover-opened card leaves the dialog open', (
    tester,
  ) async {
    await _pumpDialog(
      tester,
      theme: const DashronymTheme(hoverShowDelay: Duration.zero),
    );
    final textFieldFocus = FocusManager.instance.primaryFocus;
    expect(textFieldFocus, isNotNull);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('SDK')));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, same(textFieldFocus));

    // With no tooltip left to dismiss, Escape belongs to the dialog again.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('a focused trigger with a closed card lets Escape close the '
      'dialog', (tester) async {
    await _pumpDialog(
      tester,
      theme: const DashronymTheme(enableHover: false),
      includeTextField: false,
    );

    // Focusing the trigger opens its card; the first Escape closes the card.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'DashronymInline');
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
  testWidgets('Escape dismisses a hover-opened card when nothing has focus', (
    tester,
  ) async {
    // A bare overlay host has no route, so nothing requests focus and the
    // focus manager's early key handlers cannot run.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => const Center(
                  child: DashronymInline(
                    acronym: 'SDK',
                    description: 'Software Development Kit',
                    theme: DashronymTheme(hoverShowDelay: Duration.zero),
                    textStyle: TextStyle(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(FocusManager.instance.primaryFocus, isNull);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('SDK')));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
  });

  testWidgets('Enter toggles a focused trigger where Enter maps to '
      'ButtonActivateIntent, as on the web', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [DashronymLocalizations.delegate],
        // Replace the app-level shortcuts with the web mapping, where Enter
        // produces ButtonActivateIntent and nothing maps it to ActivateIntent.
        shortcuts: <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.tab, shift: true):
              PreviousFocusIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ButtonActivateIntent(),
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        home: Scaffold(
          body: Center(
            child: DashronymInline(
              acronym: 'SDK',
              description: 'Software Development Kit',
              theme: DashronymTheme(enableHover: false),
              textStyle: TextStyle(),
            ),
          ),
        ),
      ),
    );

    // Focusing the trigger opens its card; Enter then toggles it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);
  });

  testWidgets('Escape reaches a newer route while an older card is visible', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [DashronymLocalizations.delegate],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const Center(
                child: DashronymInline(
                  acronym: 'SDK',
                  description: 'Software Development Kit',
                  // Keep the hover-opened card visible after a route covers
                  // the trigger.
                  theme: DashronymTheme(
                    hoverShowDelay: Duration.zero,
                    hoverHideDelay: Duration(seconds: 5),
                  ),
                  textStyle: TextStyle(),
                ),
              );
            },
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('SDK')));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    unawaited(
      showDialog<void>(
        context: pageContext,
        builder: (_) => const Dialog(child: Text('Newer route')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Newer route'), findsOneWidget);
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Newer route'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('activating a non-button focusable inside a custom tooltip '
      'leaves the tooltip open', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [DashronymLocalizations.delegate],
        home: Scaffold(
          body: Center(
            child: DashronymInline(
              acronym: 'SDK',
              description: 'Software Development Kit',
              theme: const DashronymTheme(enableHover: false),
              textStyle: const TextStyle(),
              tooltipBuilder: (context, details) =>
                  const Focus(child: Text('Read more')),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Read more'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final inner = FocusManager.instance.primaryFocus;
    expect(inner?.debugLabel, isNot('DashronymInline'));

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(find.text('Read more'), findsOneWidget, reason: '$key');
      expect(FocusManager.instance.primaryFocus, same(inner), reason: '$key');
    }
  });
}
