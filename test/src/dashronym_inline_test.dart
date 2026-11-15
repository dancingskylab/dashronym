import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'support/dashronym_test_host.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testHarness(Widget child) {
  return TestWidgetsApp(
    localizationsDelegates: const [DashronymLocalizations.delegate],
    home: TestPage(body: Center(child: child)),
  );
}

DashronymTheme _theme() => const DashronymTheme(enableHover: false);

void main() {
  testWidgets('DashronymInline toggles tooltip via pointer and keyboard', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _testHarness(
        FocusTraversalGroup(
          child: DashronymInline(
            acronym: 'SDK',
            description: 'Software Development Kit',
            theme: _theme(),
            textStyle: const TextStyle(),
          ),
        ),
      ),
    );

    final trigger = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'SDK' &&
          widget.style?.decoration == TextDecoration.underline,
    );
    expect(trigger, findsOneWidget);

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);
    expect(find.byType(ScaleTransition), findsWidgets);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('SDK').first)
          .flagsCollection
          .isExpanded,
      Tristate.isTrue,
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(DashronymTooltipCard), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('SDK').first)
          .flagsCollection
          .isExpanded,
      Tristate.isFalse,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(DashronymTooltipCard), findsNothing);

    final semanticsFinder = find.bySemanticsLabel('SDK').first;
    final semanticsNode = tester.getSemantics(semanticsFinder);
    expect(semanticsNode.flagsCollection.isButton, isTrue);

    semantics.dispose();
  });

  testWidgets('Tooltip repositions to remain within the viewport', (
    tester,
  ) async {
    // Passing null clears the override; a stored size would leak into later
    // tests that resize the window.
    await tester.binding.setSurfaceSize(const Size(220, 320));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      _testHarness(
        DashronymInline(
          acronym: 'CLI',
          description: 'Command Line Interface',
          theme: _theme(),
          textStyle: const TextStyle(),
        ),
      ),
    );

    await tester.tap(find.text('CLI'));
    await tester.pumpAndSettle();

    final cardFinder = find.byType(DashronymTooltipCard);
    expect(cardFinder, findsOneWidget);

    const screenSize = Size(220, 320);
    final topLeft = tester.getTopLeft(cardFinder);
    final topRight = tester.getTopRight(cardFinder);
    final bottomLeft = tester.getBottomLeft(cardFinder);

    expect(topLeft.dx, greaterThanOrEqualTo(0));
    expect(topRight.dx, lessThanOrEqualTo(screenSize.width));
    expect(topLeft.dy, greaterThanOrEqualTo(0));
    expect(bottomLeft.dy, lessThanOrEqualTo(screenSize.height));
  });

  testWidgets('Elevated tooltip is not clipped to its layout bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        const DashronymInline(
          acronym: 'CLI',
          description: 'Command Line Interface',
          theme: DashronymTheme(
            cardElevation: 24,
            enableHover: false,
          ),
          textStyle: TextStyle(),
        ),
      ),
    );

    await tester.tap(find.text('CLI'));
    await tester.pumpAndSettle();

    final card = find.byType(DashronymTooltipCard);
    expect(card, findsOneWidget);
    expect(
      find.ancestor(of: card, matching: find.byType(ClipRect)),
      findsNothing,
      reason: 'A tight ancestor clip shears Material elevation shadows.',
    );
  });

  testWidgets('Hover shows and hides tooltip when enabled', (tester) async {
    const hoverTheme = DashronymTheme(
      enableHover: true,
      hoverShowDelay: Duration(milliseconds: 50),
      hoverHideDelay: Duration(milliseconds: 50),
    );

    await tester.pumpWidget(
      _testHarness(
        DashronymInline(
          acronym: 'UI',
          description: 'User Interface',
          theme: hoverTheme,
          textStyle: const TextStyle(),
        ),
      ),
    );

    final trigger = find.text('UI');
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(trigger));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
    await gesture.removePointer();
  });

  testWidgets(
    'hover-open tooltip dismisses with Escape without stealing focus',
    (
      tester,
    ) async {
      final otherFocus = FocusNode(debugLabel: 'other-control');
      addTearDown(otherFocus.dispose);
      const hoverTheme = DashronymTheme(
        enableHover: true,
        hoverShowDelay: Duration(milliseconds: 10),
        hoverHideDelay: Duration(milliseconds: 50),
      );

      await tester.pumpWidget(
        _testHarness(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: otherFocus,
                child: const SizedBox.square(dimension: 1),
              ),
              const DashronymInline(
                acronym: 'UI',
                description: 'User Interface',
                theme: hoverTheme,
                textStyle: TextStyle(),
              ),
            ],
          ),
        ),
      );
      otherFocus.requestFocus();
      await tester.pump();
      expect(otherFocus.hasFocus, isTrue);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.text('UI')));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(find.byType(DashronymTooltipCard), findsOneWidget);
      expect(otherFocus.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(DashronymTooltipCard), findsNothing);
      expect(otherFocus.hasFocus, isTrue);
      await gesture.removePointer();
    },
  );

  testWidgets('hover can move from trigger into tooltip without dismissing', (
    tester,
  ) async {
    const hoverTheme = DashronymTheme(
      enableHover: true,
      hoverShowDelay: Duration(milliseconds: 10),
      hoverHideDelay: Duration(milliseconds: 80),
    );

    await tester.pumpWidget(
      _testHarness(
        const DashronymInline(
          acronym: 'A11Y',
          description: 'Accessibility',
          theme: hoverTheme,
          textStyle: TextStyle(),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.text('A11Y')));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    final card = find.byType(DashronymTooltipCard);
    expect(card, findsOneWidget);

    await gesture.moveTo(tester.getCenter(card));
    await tester.pump(const Duration(milliseconds: 120));
    expect(card, findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    await gesture.removePointer();
  });

  testWidgets('close button tooltip can open inside the Dashronym overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        const DashronymInline(
          acronym: 'SDK',
          description: 'Software Development Kit',
          theme: DashronymTheme(enableHover: false),
          textStyle: TextStyle(),
        ),
      ),
    );

    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(
      tester.getCenter(find.byTooltip('Hide definition for SDK')),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byTooltip('Hide definition for SDK'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await gesture.removePointer();
  });

  testWidgets('pointer-open tooltip dismisses with Escape', (tester) async {
    await tester.pumpWidget(
      _testHarness(
        DashronymInline(
          key: const ValueKey('trigger'),
          acronym: 'API',
          description: 'Application Programming Interface',
          theme: _theme(),
          textStyle: const TextStyle(),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('trigger')));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
  });

  testWidgets('rebuilds dispose replaced tooltip curve animations', (
    tester,
  ) async {
    final events = <ObjectEvent>[];

    bool isTooltipCurve(Object object) =>
        object is CurvedAnimation &&
        object.parent is AnimationController &&
        (object.parent as AnimationController).debugLabel == 'DashronymTooltip';

    void allocationsListener(ObjectEvent event) {
      if (isTooltipCurve(event.object)) {
        events.add(event);
      }
    }

    FlutterMemoryAllocations.instance.addListener(allocationsListener);
    addTearDown(
      () => FlutterMemoryAllocations.instance.removeListener(
        allocationsListener,
      ),
    );

    var useLinearCurve = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      _testHarness(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return DashronymInline(
              acronym: 'SDK',
              description: 'Software Development Kit',
              theme: DashronymTheme(
                enableHover: false,
                tooltipFadeInCurve: useLinearCurve
                    ? Curves.linear
                    : Curves.easeOut,
              ),
              textStyle: const TextStyle(),
            );
          },
        ),
      ),
    );

    expect(events.whereType<ObjectCreated>(), hasLength(2));
    expect(events.whereType<ObjectDisposed>(), isEmpty);

    rebuild(() {
      useLinearCurve = true;
    });
    await tester.pump();

    expect(events.whereType<ObjectCreated>(), hasLength(4));
    expect(events.whereType<ObjectDisposed>(), hasLength(2));

    await tester.pumpWidget(const SizedBox.shrink());

    expect(events.whereType<ObjectDisposed>(), hasLength(4));
  });

  testWidgets('direct DashronymInline honors ambient text scaling', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 20, height: 1);
    await tester.pumpWidget(
      _testHarness(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('SDK', key: ValueKey('scaling-reference'), style: style),
              DashronymInline(
                key: ValueKey('direct-inline'),
                acronym: 'SDK',
                description: 'Software Development Kit',
                theme: DashronymTheme(enableHover: false),
                textStyle: style,
              ),
            ],
          ),
        ),
      ),
    );

    final triggerText = find.descendant(
      of: find.byKey(const ValueKey('direct-inline')),
      matching: find.text('SDK'),
    );
    expect(tester.widget<Text>(triggerText).textScaler, isNull);
    expect(
      tester.getRect(triggerText).height,
      closeTo(
        tester.getRect(find.byKey(const ValueKey('scaling-reference'))).height,
        0.01,
      ),
    );
  });

  testWidgets('keyboard can reach tooltip controls and focus returns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        FocusTraversalGroup(
          child: DashronymInline(
            acronym: 'SDK',
            description: 'Software Development Kit',
            theme: _theme(),
            textStyle: const TextStyle(),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    final focusedTrigger = tester.widget<Text>(find.text('SDK').first);
    expect(focusedTrigger.style?.backgroundColor, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);

    // The close action restores focus to the trigger without reopening it.
    // A subsequent activation deliberately opens it again.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);
  });

  testWidgets('rapid hide and reopen cannot remove the replacement tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        const DashronymInline(
          acronym: 'SDK',
          description: 'Software Development Kit',
          theme: DashronymTheme(
            enableHover: false,
            tooltipFadeDuration: Duration(milliseconds: 300),
          ),
          textStyle: TextStyle(),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DashronymTooltipCard), findsOneWidget);
    expect(find.text('Software Development Kit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('announcements use one platform-appropriate semantics path', (
    tester,
  ) async {
    final messages = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        messages.add(message);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );

    await tester.pumpWidget(
      _testHarness(
        const MediaQuery(
          data: MediaQueryData(supportsAnnounce: true),
          child: DashronymInline(
            acronym: 'API',
            description: 'Application Programming Interface',
            theme: DashronymTheme(enableHover: false),
            textStyle: TextStyle(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('API'));
    await tester.pumpAndSettle();

    final announcements = messages
        .whereType<Map<Object?, Object?>>()
        .where((message) => message['type'] == 'announce')
        .toList();
    expect(announcements, hasLength(1));
    expect(
      (announcements.single['data'] as Map<Object?, Object?>)['message'],
      'Showing definition for API. Application Programming Interface',
    );
    final tooltipSemantics = tester.getSemantics(
      find.byType(DashronymTooltipCard),
    );
    expect(tooltipSemantics.flagsCollection.isLiveRegion, isFalse);

    messages.clear();
    await tester.pumpWidget(
      _testHarness(
        const MediaQuery(
          data: MediaQueryData(supportsAnnounce: false),
          child: DashronymInline(
            key: ValueKey('unsupported-announcements'),
            acronym: 'SDK',
            description: 'Software Development Kit',
            theme: DashronymTheme(enableHover: false),
            textStyle: TextStyle(),
          ),
        ),
      ),
    );
    await tester.tap(find.text('SDK').first);
    await tester.pumpAndSettle();

    expect(
      messages.whereType<Map<Object?, Object?>>().where(
        (message) => message['type'] == 'announce',
      ),
      isEmpty,
    );
    final fallbackTooltipSemantics = tester.getSemantics(
      find.byType(DashronymTooltipCard),
    );
    expect(fallbackTooltipSemantics.flagsCollection.isLiveRegion, isTrue);
    expect(
      fallbackTooltipSemantics.value,
      'Software Development Kit',
    );
    expect(
      find.bySemanticsLabel('Hide definition for SDK.'),
      findsNothing,
    );
  });

  testWidgets('tooltip updates content and inherits the trigger theme', (
    tester,
  ) async {
    final color = ValueNotifier(Color(0xFF3F51B5));
    final description = ValueNotifier('First definition');
    addTearDown(color.dispose);
    addTearDown(description.dispose);

    await tester.pumpWidget(
      _testHarness(
        ValueListenableBuilder<Color>(
          valueListenable: color,
          builder: (context, currentColor, _) {
            return ValueListenableBuilder<String>(
              valueListenable: description,
              builder: (context, currentDescription, _) {
                // Any inherited theme around the trigger, here IconTheme,
                // must reach the tooltip content built in the overlay.
                return IconTheme(
                  data: IconThemeData(color: currentColor),
                  child: DashronymInline(
                    acronym: 'API',
                    description: currentDescription,
                    theme: _theme().copyWith(
                      acronymStyle: TextStyle(color: currentColor),
                    ),
                    textStyle: const TextStyle(),
                    tooltipBuilder: (context, details) {
                      return ColoredBox(
                        key: const ValueKey('custom-tooltip'),
                        color: IconTheme.of(context).color!,
                        child: Text(details.description),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('API'));
    await tester.pumpAndSettle();
    expect(find.text('First definition'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('API')).style?.color,
      Color(0xFF3F51B5),
    );
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('custom-tooltip')),
          )
          .color,
      Color(0xFF3F51B5),
    );

    description.value = 'Updated definition';
    color.value = Color(0xFF009688);
    await tester.pumpAndSettle();

    expect(find.text('First definition'), findsNothing);
    expect(find.text('Updated definition'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('API')).style?.color,
      Color(0xFF009688),
    );
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('custom-tooltip')),
          )
          .color,
      Color(0xFF009688),
    );
  });

  testWidgets('long large-scale tooltip avoids safe areas and keyboard', (
    tester,
  ) async {
    // Safe areas and the keyboard come from the window, as in a real app.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 320);
    tester.view.padding = const FakeViewPadding(top: 20, bottom: 20);
    tester.view.viewInsets = const FakeViewPadding(bottom: 100);
    addTearDown(tester.view.reset);
    final description = List.filled(
      20,
      'A long accessibility-aware definition.',
    ).join(' ');

    await tester.pumpWidget(
      _testHarness(
        Builder(
          // The overlay inherits the trigger's text scale.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(3)),
            child: DashronymInline(
              acronym: 'A11Y',
              description: description,
              theme: _theme(),
              textStyle: const TextStyle(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('A11Y'));
    await tester.pumpAndSettle();

    final card = find.byType(DashronymTooltipCard);
    expect(card, findsOneWidget);
    final rect = tester.getRect(card);
    expect(rect.top, greaterThanOrEqualTo(20));
    expect(rect.bottom, lessThanOrEqualTo(200));
    expect(rect.height, lessThanOrEqualTo(164));
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one scope keeps only one tooltip open', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        DashronymScope(
          registry: DashronymRegistry(<String, String>{}),
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashronymInline(
                  acronym: 'SDK',
                  description: 'Software Development Kit',
                  theme: _theme(),
                  textStyle: const TextStyle(),
                ),
                const SizedBox(height: 12),
                DashronymInline(
                  acronym: 'API',
                  description: 'Application Programming Interface',
                  theme: _theme(),
                  textStyle: const TextStyle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Software Development Kit'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Software Development Kit'), findsNothing);
    expect(find.text('Application Programming Interface'), findsOneWidget);
  });

  testWidgets(
    'tab traversal escapes an open tooltip and wraps back to the first '
    'trigger',
    (tester) async {
      await tester.pumpWidget(
        _testHarness(
          DashronymScope(
            registry: DashronymRegistry(<String, String>{}),
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DashronymInline(
                    acronym: 'SDK',
                    description: 'Software Development Kit',
                    theme: _theme(),
                    textStyle: const TextStyle(),
                  ),
                  const SizedBox(height: 12),
                  DashronymInline(
                    acronym: 'API',
                    description: 'Application Programming Interface',
                    theme: _theme(),
                    textStyle: const TextStyle(),
                  ),
                  const SizedBox(height: 12),
                  DashronymInline(
                    acronym: 'CLI',
                    description: 'Command Line Interface',
                    theme: _theme(),
                    textStyle: const TextStyle(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Future<void> tab() async {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }

      await tab();
      expect(find.text('Software Development Kit'), findsOneWidget);
      await tab();
      expect(find.text('Application Programming Interface'), findsOneWidget);
      await tab();
      expect(find.text('Command Line Interface'), findsOneWidget);

      // The next stop is the open tooltip's own close button, not another
      // trigger.
      await tab();
      expect(find.text('Command Line Interface'), findsOneWidget);
      final closeButtonFocus = FocusManager.instance.primaryFocus;
      expect(closeButtonFocus, isNotNull);

      // Tabbing past the tooltip's only control must escape the tooltip's
      // focus scope and land back on the first trigger, not loop on the
      // close button forever.
      await tab();
      expect(find.text('Command Line Interface'), findsNothing);
      expect(find.text('Software Development Kit'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, isNot(closeButtonFocus));
    },
  );

  testWidgets('independent scopes do not dismiss each other', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _testHarness(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DashronymScope(
              registry: DashronymRegistry(<String, String>{}),
              child: DashronymInline(
                acronym: 'SDK',
                description: 'Software Development Kit',
                theme: _theme(),
                textStyle: const TextStyle(),
              ),
            ),
            const SizedBox(width: 24),
            DashronymScope(
              registry: DashronymRegistry(<String, String>{}),
              child: DashronymInline(
                acronym: 'API',
                description: 'Application Programming Interface',
                theme: _theme(),
                textStyle: const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );

    tester.semantics.tap(
      find.semantics.byHint('Double tap to show definition for SDK.'),
    );
    await tester.pumpAndSettle();
    tester.semantics.tap(
      find.semantics.byHint('Double tap to show definition for API.'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Software Development Kit'), findsOneWidget);
    expect(find.text('Application Programming Interface'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('DashronymInline uses custom tooltipBuilder when provided', (
    tester,
  ) async {
    final tooltipKey = GlobalKey();

    await tester.pumpWidget(
      _testHarness(
        DashronymInline(
          acronym: 'API',
          description: 'Application Programming Interface',
          theme: _theme(),
          textStyle: const TextStyle(),
          tooltipBuilder: (context, details) {
            return GestureDetector(
              key: tooltipKey,
              onTap: details.hideTooltip,
              child: PhysicalModel(
                color: const Color(0xFFFFFFFF),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(details.description),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('API'));
    await tester.pumpAndSettle();

    expect(find.byKey(tooltipKey), findsOneWidget);

    await tester.tap(find.byKey(tooltipKey));
    await tester.pumpAndSettle();

    expect(find.byKey(tooltipKey), findsNothing);
  });

  testWidgets('reacts to updates, metrics changes, and scrolls', (
    tester,
  ) async {
    final themeNotifier = ValueNotifier(
      const DashronymTheme(
        enableHover: false,
        tooltipFadeDuration: Duration(milliseconds: 120),
        tooltipMinWidth: 140,
        hoverShowDelay: Duration(milliseconds: 10),
        hoverHideDelay: Duration(milliseconds: 20),
      ),
    );

    var useScroll = true;
    late StateSetter toggleLayout;

    await tester.pumpWidget(
      _testHarness(
        StatefulBuilder(
          builder: (context, setState) {
            toggleLayout = setState;
            return ValueListenableBuilder<DashronymTheme>(
              valueListenable: themeNotifier,
              builder: (context, theme, _) {
                final inline = DashronymInline(
                  key: const ValueKey('inline'),
                  acronym: 'SDK',
                  description: 'Software Development Kit',
                  theme: theme,
                  textStyle: const TextStyle(),
                );

                Widget child;
                if (useScroll) {
                  child = SizedBox(
                    height: 200,
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        const SizedBox(height: 16),
                        inline,
                        const SizedBox(height: 320),
                      ],
                    ),
                  );
                } else {
                  child = inline;
                }

                return FocusTraversalGroup(child: child);
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('inline')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    themeNotifier.value = themeNotifier.value.copyWith(
      tooltipFadeDuration: const Duration(milliseconds: 60),
      hoverHideDelay: const Duration(milliseconds: 30),
    );
    await tester.pump();

    tester.binding.handleMetricsChanged();
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);

    toggleLayout(() {
      useScroll = false;
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('inline')));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    final state = tester.state(find.byKey(const ValueKey('inline')));
    // Intentionally using `dynamic` to access the internal test helper `debugRemoveEntry()`.
    // This bypasses type safety, but is appropriate for test code to verify internal state.
    (state as dynamic).debugRemoveEntry();
    await tester.tap(find.byKey(const ValueKey('inline')));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);

    await tester.tap(find.byKey(const ValueKey('inline')));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    await tester.tap(find.byTooltip('Hide definition for SDK'));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
  });

  testWidgets('DashronymInline hides tooltip on orientation change', (
    tester,
  ) async {
    // Rotate the window itself: a surface-size override leaves the view's
    // metrics alone, so it doesn't count as this view changing.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _testHarness(
        DashronymInline(
          acronym: 'SDK',
          description: 'Software Development Kit',
          theme: _theme(),
          textStyle: const TextStyle(),
        ),
      ),
    );

    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    tester.view.physicalSize = const Size(640, 360);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(DashronymTooltipCard), findsNothing);
  });

  testWidgets('Scrolling dismisses a visible tooltip', (tester) async {
    final controller = ScrollController();

    await tester.pumpWidget(
      _testHarness(
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 16),
                DashronymInline(
                  acronym: 'SDK',
                  description: 'Software Development Kit',
                  theme: _theme(),
                  textStyle: const TextStyle(),
                ),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);

    controller.jumpTo(30);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(DashronymTooltipCard), findsNothing);
  });
}
