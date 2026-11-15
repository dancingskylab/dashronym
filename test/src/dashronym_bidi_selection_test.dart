// Acronyms in right-to-left and mixed-direction paragraphs keep their visual
// and reading order, and selecting a paragraph copies them in place.
import 'package:dashronym/dashronym.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

final _registry = DashronymRegistry({
  'SDK': 'Software Development Kit',
  'API': 'Application Programming Interface',
});
const _bare = DashronymConfig(enableBareAcronyms: true);

Widget _rtl(String text) => _rtlWith(text, _registry);

Widget _rtlWith(String text, DashronymRegistry registry) {
  return testHost(
    TestPage(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: DashronymText(text, registry: registry, config: _bare),
      ),
    ),
  );
}

/// Labels of the acronym triggers, in screen-reader order.
List<String> _triggerReadingOrder(WidgetTester tester) {
  return [
    for (final node in tester.semantics.simulatedAccessibilityTraversal())
      if (node.getSemanticsData().flagsCollection.isButton) node.label,
  ];
}

double _x(WidgetTester tester, String acronym) {
  return tester.getCenter(find.text(acronym)).dx;
}

void main() {
  testWidgets('acronyms between Arabic words run right to left', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_rtl('استخدم SDK ثم API الآن'));

    expect(_x(tester, 'SDK'), greaterThan(_x(tester, 'API')));
    expect(_triggerReadingOrder(tester), ['SDK', 'API']);

    await tester.tap(find.text('API'));
    await tester.pumpAndSettle();
    expect(find.text('Application Programming Interface'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('acronyms in an English run keep left-to-right order', (
    tester,
  ) async {
    await tester.pumpWidget(_rtl('استخدم SDK and API الآن'));

    // Each acronym is a neutral placeholder to the bidi algorithm, so without
    // directional marks the run would reverse. Screen readers step through
    // inline widgets by position, as Flutter does for any WidgetSpan.
    expect(_x(tester, 'SDK'), lessThan(_x(tester, 'API')));

    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle();
    expect(find.text('Software Development Kit'), findsOneWidget);
  });

  testWidgets('right-to-left acronyms keep their order in English text', (
    tester,
  ) async {
    await tester.pumpWidget(
      testHost(
        TestPage(
          body: DashronymText(
            'Read (צהל) ו (מסד) now',
            registry: DashronymRegistry({
              'צהל': 'Israel Defense Forces',
              'מסד': 'Database',
            }),
          ),
        ),
      ),
    );

    // As plain text, the Hebrew run reads right to left.
    expect(_x(tester, 'צהל'), greaterThan(_x(tester, 'מסד')));
  });

  testWidgets('only acronyms that run against the paragraph get marks', (
    tester,
  ) async {
    final registry = DashronymRegistry({
      'SDK': 'Software Development Kit',
      '42': 'The answer',
    });
    String plainText() {
      return tester
          .widget<RichText>(find.byType(RichText).first)
          .text
          .toPlainText();
    }

    await tester.pumpWidget(
      testHost(TestPage(body: DashronymText('Use (SDK).', registry: registry))),
    );
    expect(plainText(), isNot(contains('\u200E')));

    // Digits have no direction of their own, so (42) needs no marks either.
    await tester.pumpWidget(_rtlWith('(42) ثم (SDK)', registry));
    expect('\u200E'.allMatches(plainText()), hasLength(2));
  });

  testWidgets('selecting a paragraph copies its acronyms in place', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    SelectedContent? selected;
    await tester.pumpWidget(
      testHost(
        TestPage(
          body: SelectableRegion(
            focusNode: focusNode,
            selectionControls: emptyTextSelectionControls,
            onSelectionChanged: (content) => selected = content,
            child: DashronymText(
              'Our SDK and API are selectable.',
              registry: _registry,
              config: _bare,
            ),
          ),
        ),
      ),
    );

    tester
        .state<SelectableRegionState>(find.byType(SelectableRegion))
        .selectAll(SelectionChangedCause.keyboard);
    await tester.pump();

    expect(selected?.plainText, 'Our SDK and API are selectable.');
  });
}
