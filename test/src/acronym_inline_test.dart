import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/acronym_inline.dart';
import 'package:dashronym/src/tooltip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testHarness(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      DashronymLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: DashronymLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

DashronymTheme _theme() => const DashronymTheme(enableHover: false);

void main() {
  testWidgets('AcronymInline toggles tooltip via pointer and keyboard', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _testHarness(
        FocusTraversalGroup(
          child: AcronymInline(
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
    final view = tester.view;
    final originalLogicalSize = view.physicalSize / view.devicePixelRatio;

    await tester.binding.setSurfaceSize(const Size(220, 320));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(originalLogicalSize);
    });

    await tester.pumpWidget(
      _testHarness(
        AcronymInline(
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

    final screenSize = view.physicalSize / view.devicePixelRatio;
    final topLeft = tester.getTopLeft(cardFinder);
    final topRight = tester.getTopRight(cardFinder);
    final bottomLeft = tester.getBottomLeft(cardFinder);

    expect(topLeft.dx, greaterThanOrEqualTo(0));
    expect(topRight.dx, lessThanOrEqualTo(screenSize.width));
    expect(topLeft.dy, greaterThanOrEqualTo(0));
    expect(bottomLeft.dy, lessThanOrEqualTo(screenSize.height));
  });

  testWidgets('Hover shows and hides tooltip when enabled', (tester) async {
    const hoverTheme = DashronymTheme(
      enableHover: true,
      hoverShowDelay: Duration(milliseconds: 50),
      hoverHideDelay: Duration(milliseconds: 50),
    );

    await tester.pumpWidget(
      _testHarness(
        AcronymInline(
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
        const AcronymInline(
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

  testWidgets('pointer-open tooltip dismisses with Escape', (tester) async {
    await tester.pumpWidget(
      _testHarness(
        AcronymInline(
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

  testWidgets('direct AcronymInline honors ambient text scaling', (
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
              AcronymInline(
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
          child: AcronymInline(
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
        const AcronymInline(
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
          child: AcronymInline(
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
          child: AcronymInline(
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
    final color = ValueNotifier(Colors.indigo);
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
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: currentColor,
                      primary: currentColor,
                    ),
                  ),
                  child: AcronymInline(
                    acronym: 'API',
                    description: currentDescription,
                    theme: _theme().copyWith(
                      acronymStyle: TextStyle(color: currentColor),
                    ),
                    textStyle: const TextStyle(),
                    tooltipBuilder: (context, details) {
                      return ColoredBox(
                        key: const ValueKey('custom-tooltip'),
                        color: Theme.of(context).colorScheme.primary,
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
    expect(tester.widget<Text>(find.text('API')).style?.color, Colors.indigo);
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('custom-tooltip')),
          )
          .color,
      Colors.indigo,
    );

    description.value = 'Updated definition';
    color.value = Colors.teal;
    await tester.pumpAndSettle();

    expect(find.text('First definition'), findsNothing);
    expect(find.text('Updated definition'), findsOneWidget);
    expect(tester.widget<Text>(find.text('API')).style?.color, Colors.teal);
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const ValueKey('custom-tooltip')),
          )
          .color,
      Colors.teal,
    );
  });

  testWidgets('long large-scale tooltip avoids safe areas and keyboard', (
    tester,
  ) async {
    final originalLogicalSize =
        tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.binding.setSurfaceSize(const Size(280, 320));
    addTearDown(
      () => tester.binding.setSurfaceSize(originalLogicalSize),
    );
    final description = List.filled(
      20,
      'A long accessibility-aware definition.',
    ).join(' ');

    await tester.pumpWidget(
      _testHarness(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(280, 320),
            padding: EdgeInsets.symmetric(vertical: 20),
            viewInsets: EdgeInsets.only(bottom: 100),
            textScaler: TextScaler.linear(3),
          ),
          child: AcronymInline(
            acronym: 'A11Y',
            description: description,
            theme: _theme(),
            textStyle: const TextStyle(),
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

  testWidgets('Opening one tooltip hides any previously open tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHarness(
        FocusTraversalGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AcronymInline(
                acronym: 'SDK',
                description: 'Software Development Kit',
                theme: _theme(),
                textStyle: const TextStyle(),
              ),
              const SizedBox(height: 12),
              AcronymInline(
                acronym: 'API',
                description: 'Application Programming Interface',
                theme: _theme(),
                textStyle: const TextStyle(),
              ),
            ],
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

  testWidgets('AcronymInline uses custom tooltipBuilder when provided', (
    tester,
  ) async {
    final tooltipKey = GlobalKey();
    final entry = AcronymEntry(
      acronym: 'API',
      expansion: 'Application Programming Interface',
      definition: 'A contract for software integration.',
      tags: const ['software'],
    );
    AcronymEntry? receivedEntry;

    await tester.pumpWidget(
      _testHarness(
        AcronymInline(
          acronym: 'API',
          description: 'Application Programming Interface',
          theme: _theme(),
          textStyle: const TextStyle(),
          entry: entry,
          tooltipBuilder: (context, details) {
            receivedEntry = details.entry;
            return GestureDetector(
              key: tooltipKey,
              onTap: details.hideTooltip,
              child: Material(
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
    expect(receivedEntry, same(entry));

    await tester.tap(find.byKey(tooltipKey));
    await tester.pumpAndSettle();

    expect(find.byKey(tooltipKey), findsNothing);
  });

  testWidgets('AcronymInline reacts to updates, metrics changes, and scrolls', (
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
                final inline = AcronymInline(
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

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
  });

  testWidgets('AcronymInline hides tooltip on orientation change', (
    tester,
  ) async {
    final binding = tester.binding;
    final view = tester.view;
    final originalLogicalSize = view.physicalSize / view.devicePixelRatio;

    await binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() async {
      await binding.setSurfaceSize(originalLogicalSize);
    });

    await tester.pumpWidget(
      _testHarness(
        AcronymInline(
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

    await binding.setSurfaceSize(const Size(640, 360));
    binding.handleMetricsChanged();
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
                AcronymInline(
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
