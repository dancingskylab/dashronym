// Flutter's accessibility guidelines, on a light and a dark host.
import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

const _darkBackground = Color(0xFF1C1B1F);
const _darkText = TextStyle(color: Color(0xFFE6E1E5), fontSize: 14);

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});

void main() {
  for (final dark in [false, true]) {
    final host = dark ? 'dark' : 'light';

    testWidgets('the card meets every guideline on a $host host', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        testHost(
          background: dark ? _darkBackground : hostBackground,
          textStyle: dark ? _darkText : hostTextStyle,
          Center(
            child: DashronymTooltipCard(
              acronym: 'SDK',
              description: 'Software Development Kit',
              theme: const DashronymTheme(),
              onClose: () {},
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    // Inline triggers are exempt from target size, as WCAG 2.5.8 exempts
    // targets in a sentence, so check labels and contrast only.
    testWidgets('a paragraph with an open card on a $host host', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        testHost(
          background: dark ? _darkBackground : hostBackground,
          textStyle: dark ? _darkText : hostTextStyle,
          Center(
            child: DashronymText(
              'Install the SDK first.',
              registry: _registry,
              config: const DashronymConfig(enableBareAcronyms: true),
            ),
          ),
        ),
      );
      await tester.tap(find.text('SDK'));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }
}
