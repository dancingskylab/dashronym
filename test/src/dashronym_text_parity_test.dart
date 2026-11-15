// DashronymText matches Text on hyphenation and on the text-spacing overrides
// that web accessibility settings publish through MediaQuery.
import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});
const _bare = DashronymConfig(enableBareAcronyms: true);

/// The paragraph's own RichText; each trigger renders another inside it.
RichText _paragraph(WidgetTester tester) {
  return tester.widget<RichText>(find.byType(RichText).first);
}

void main() {
  testWidgets('hyphens defaults to manual, as with Text', (tester) async {
    await tester.pumpWidget(
      testHost(
        TestPage(body: DashronymText('Use the SDK.', registry: _registry)),
      ),
    );
    expect(_paragraph(tester).hyphens, Hyphens.manual);
  });

  final hosts = <String, Widget>{
    'DashronymText': DashronymText(
      'Use the SDK.',
      registry: _registry,
      hyphens: Hyphens.hidden,
    ),
    'DashronymText.rich': DashronymText.rich(
      const TextSpan(text: 'Use the SDK.'),
      registry: _registry,
      hyphens: Hyphens.hidden,
    ),
    'Text.dashronyms': const Text(
      'Use the SDK.',
      hyphens: Hyphens.hidden,
    ).dashronyms(registry: _registry),
    'Text.rich.dashronyms': const Text.rich(
      TextSpan(text: 'Use the SDK.'),
      hyphens: Hyphens.hidden,
    ).dashronyms(registry: _registry),
    'Text.dashronyms(hyphens:)': const Text(
      'Use the SDK.',
    ).dashronyms(registry: _registry, hyphens: Hyphens.hidden),
  };
  for (final MapEntry(key: name, value: host) in hosts.entries) {
    testWidgets('$name passes hyphens to the paragraph', (tester) async {
      await tester.pumpWidget(testHost(TestPage(body: host)));
      expect(_paragraph(tester).hyphens, Hyphens.hidden);
    });
  }

  testWidgets('text-spacing overrides reach the text, strut and triggers', (
    tester,
  ) async {
    await tester.pumpWidget(
      testHost(
        TestPage(
          // Only the platform sets these, so copyWith can't.
          body: MediaQuery(
            data: const MediaQueryData(
              lineHeightScaleFactorOverride: 2,
              letterSpacingOverride: 3,
              wordSpacingOverride: 4,
            ),
            child: DashronymText.rich(
              const TextSpan(
                text: 'Use the ',
                children: [TextSpan(text: 'SDK now.')],
              ),
              registry: _registry,
              config: _bare,
              strutStyle: const StrutStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );

    void expectSpacing(TextStyle? style) {
      expect(style?.height, 2);
      expect(style?.letterSpacing, 3);
      expect(style?.wordSpacing, 4);
    }

    final paragraph = _paragraph(tester);
    expect(paragraph.strutStyle?.height, 2);
    expect(paragraph.strutStyle?.fontSize, 14);
    final spans = <TextSpan>[];
    paragraph.text.visitChildren((span) {
      if (span is TextSpan) spans.add(span);
      return true;
    });
    expect(spans.where((span) => span.text != null), isNotEmpty);
    for (final span in spans) {
      expectSpacing(span.style);
    }

    // Each trigger is a Text, which applies the overrides itself.
    final trigger = tester.widget<RichText>(
      find.descendant(
        of: find.byType(DashronymInline),
        matching: find.byType(RichText),
      ),
    );
    expectSpacing(trigger.text.style);
  });

  testWidgets('without overrides, text styles are left alone', (tester) async {
    await tester.pumpWidget(
      testHost(
        TestPage(
          body: DashronymText(
            'Use the SDK.',
            registry: _registry,
            strutStyle: const StrutStyle(fontSize: 14),
          ),
        ),
      ),
    );
    final paragraph = _paragraph(tester);
    expect(paragraph.strutStyle?.height, isNull);
    expect(paragraph.text.style?.letterSpacing, hostTextStyle.letterSpacing);
  });
}
