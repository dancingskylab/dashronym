// Keyboard interaction between Dashronym tooltips and enclosing routes.
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

/// A dialog surface, standing in for a design system's dialog.
class _TestDialog extends StatelessWidget {
  const _TestDialog({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    );
  }
}

/// Opens a dialog route that Escape dismisses, like a design system's dialog.
Future<void> _showTestDialog(BuildContext context, Widget child) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    pageBuilder: (context, animation, secondaryAnimation) =>
        _TestDialog(child: child),
  );
}

/// Opens a dialog that contains an autofocused text field and a trigger.
Future<void> _pumpDialog(
  WidgetTester tester, {
  required DashronymTheme theme,
  bool includeTextField = true,
}) async {
  final controller = TextEditingController();
  final fieldFocus = FocusNode(debugLabel: 'field');
  addTearDown(controller.dispose);
  addTearDown(fieldFocus.dispose);

  await tester.pumpWidget(
    testHost(
      Builder(
        builder: (context) => GestureDetector(
          onTap: () => _showTestDialog(
            context,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (includeTextField)
                  SizedBox(
                    width: 200,
                    child: EditableText(
                      controller: controller,
                      focusNode: fieldFocus,
                      autofocus: true,
                      style: hostTextStyle,
                      cursorColor: const Color(0xFF000000),
                      backgroundCursorColor: const Color(0xFF808080),
                    ),
                  ),
                DashronymInline(
                  acronym: 'SDK',
                  description: 'Software Development Kit',
                  theme: theme,
                  textStyle: const TextStyle(),
                ),
              ],
            ),
          ),
          child: const Text('Open dialog'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open dialog'));
  await tester.pumpAndSettle();
  expect(find.byType(_TestDialog), findsOneWidget);
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
    expect(find.byType(_TestDialog), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, same(textFieldFocus));

    // With no tooltip left to dismiss, Escape belongs to the dialog again.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(_TestDialog), findsNothing);
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
    expect(find.byType(_TestDialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(_TestDialog), findsNothing);
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
      const TestWidgetsApp(
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
        home: TestPage(
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
      TestWidgetsApp(
        localizationsDelegates: const [DashronymLocalizations.delegate],
        home: TestPage(
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
      _showTestDialog(pageContext, const Text('Newer route')),
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
      TestWidgetsApp(
        localizationsDelegates: const [DashronymLocalizations.delegate],
        home: TestPage(
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

  testWidgets('DismissIntent from other shortcuts closes a visible card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestWidgetsApp(
        localizationsDelegates: [DashronymLocalizations.delegate],
        home: TestPage(
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

    // From the focused trigger.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final trigger = FocusManager.instance.primaryFocus!;
    expect(find.byType(DashronymTooltipCard), findsOneWidget);
    Actions.invoke(trigger.context!, const DismissIntent());
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(trigger));

    // From a control inside the card, which hands focus back to the trigger.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final inside = FocusManager.instance.primaryFocus!;
    expect(inside, isNot(same(trigger)));
    Actions.invoke(inside.context!, const DismissIntent());
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(trigger));
  });
}
