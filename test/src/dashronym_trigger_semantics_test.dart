// Screen readers meet each acronym once, as a disclosure button, and read its
// card right after it.
import 'dart:ui' show LocaleStringAttribute, SemanticsAction, Tristate;

import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

final _registry = DashronymRegistry({
  'SDK': 'Software Development Kit',
  'API': 'Application Programming Interface',
});

Widget _paragraph({Locale? locale}) {
  return testHost(
    TestPage(
      body:
          Text.rich(
            TextSpan(
              locale: locale,
              text: 'Use the SDK now, and the API later.',
            ),
          ).dashronyms(
            registry: _registry,
            config: const DashronymConfig(enableBareAcronyms: true),
          ),
    ),
  );
}

List<SemanticsNode> _nodesLabeled(String label) {
  return find.semantics
      .byPredicate((node) => node.label == label)
      .evaluate()
      .toList();
}

/// The trigger's node; an open card repeats the acronym as plain text.
SemanticsNode _triggerNode(String acronym) {
  return _nodesLabeled(acronym)
      .where((node) => node.getSemanticsData().flagsCollection.isButton)
      .single;
}

SemanticsData _trigger(String acronym) {
  return _triggerNode(acronym).getSemanticsData();
}

void _perform(String acronym, SemanticsAction action) {
  final node = _triggerNode(acronym);
  node.owner!.performAction(node.id, action);
}

/// The text a screen reader speaks for each node, in reading order.
List<String> _readingOrder(WidgetTester tester) {
  return [
    for (final node in tester.semantics.simulatedAccessibilityTraversal())
      [
        node.label,
        node.value,
        node.tooltip,
      ].where((text) => text.isNotEmpty).join(' | '),
  ].where((text) => text.isNotEmpty).toList();
}

void main() {
  testWidgets('each acronym is one focusable disclosure button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_paragraph());

    for (final acronym in ['SDK', 'API']) {
      expect(_nodesLabeled(acronym), hasLength(1), reason: acronym);
      final data = _trigger(acronym);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isFocused, isNot(Tristate.none));
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.focus), isTrue);
    }
    semantics.dispose();
  });

  testWidgets('the trigger reports focus as Focus would', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_paragraph());
    expect(_trigger('SDK').flagsCollection.isFocused, Tristate.isFalse);

    _perform('SDK', SemanticsAction.focus);
    await tester.pumpAndSettle();
    expect(_trigger('SDK').flagsCollection.isFocused, Tristate.isTrue);
    expect(_trigger('API').flagsCollection.isFocused, Tristate.isFalse);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(_trigger('SDK').flagsCollection.isFocused, Tristate.isFalse);
    semantics.dispose();
  });

  testWidgets(
    'iOS gets no focus action, as with Focus',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_paragraph());
      expect(_trigger('SDK').hasAction(SemanticsAction.focus), isFalse);
      expect(_trigger('SDK').flagsCollection.isFocused, Tristate.isFalse);
      semantics.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('expand and collapse actions follow the card', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_paragraph());

    expect(_trigger('SDK').hasAction(SemanticsAction.expand), isTrue);
    expect(_trigger('SDK').hasAction(SemanticsAction.collapse), isFalse);

    _perform('SDK', SemanticsAction.expand);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsOneWidget);
    expect(_trigger('SDK').flagsCollection.isExpanded, Tristate.isTrue);
    expect(_trigger('SDK').hasAction(SemanticsAction.expand), isFalse);
    expect(_trigger('SDK').hasAction(SemanticsAction.collapse), isTrue);

    _perform('SDK', SemanticsAction.collapse);
    await tester.pumpAndSettle();
    expect(find.byType(DashronymTooltipCard), findsNothing);
    expect(_trigger('SDK').hasAction(SemanticsAction.expand), isTrue);
    semantics.dispose();
  });

  testWidgets('an authored locale tags the label without reshaping the tree', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_paragraph());
    final plain = _readingOrder(tester);

    await tester.pumpWidget(_paragraph(locale: const Locale('fr')));

    expect(_readingOrder(tester), plain);
    final attributes = _triggerNode('SDK').attributedLabel.attributes;
    expect(
      attributes.whereType<LocaleStringAttribute>().single.locale,
      const Locale('fr'),
    );
    semantics.dispose();
  });

  // On the web the engine moves the card next to its acronym with aria-owns,
  // so the framework's tree keeps it in the overlay.
  testWidgets('the card is read right after its acronym', skip: kIsWeb, (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testHost(
        TestPage(
          body: const Column(
            children: [
              Text('Before'),
              DashronymInline(
                acronym: 'SDK',
                description: 'Software Development Kit',
                theme: DashronymTheme(enableHover: false),
                textStyle: TextStyle(),
              ),
              Text('After'),
            ],
          ),
        ),
      ),
    );
    _perform('SDK', SemanticsAction.tap);
    await tester.pumpAndSettle();

    final order = _readingOrder(tester);
    final trigger = order.indexOf('SDK');
    expect(order.indexOf('Before'), lessThan(trigger), reason: '$order');
    expect(
      order.indexOf('Definition for SDK | Software Development Kit'),
      trigger + 1,
      reason: '$order',
    );
    expect(
      order.indexOf('Hide definition for SDK'),
      greaterThan(trigger + 1),
      reason: '$order',
    );
    expect(order.indexOf('After'), order.length - 1, reason: '$order');
    semantics.dispose();
  });
}
