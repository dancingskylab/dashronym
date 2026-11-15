// The tooltip honors the platform's Reduce Motion setting.
import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

/// The scale applied to the card halfway through its entrance.
Future<double> _midEntranceScale(
  WidgetTester tester, {
  required bool reduceMotion,
}) async {
  await tester.pumpWidget(
    testHost(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(reduceMotion: reduceMotion),
          child: const Center(
            child: DashronymInline(
              acronym: 'SDK',
              description: 'Software Development Kit',
              theme: DashronymTheme(
                enableHover: false,
                tooltipFadeDuration: Duration(milliseconds: 200),
              ),
              textStyle: TextStyle(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('SDK'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  final scale = tester.widget<ScaleTransition>(
    find.ancestor(
      of: find.byType(DashronymTooltipCard),
      matching: find.byType(ScaleTransition),
    ),
  );
  final fade = tester.widget<FadeTransition>(
    find.ancestor(
      of: find.byType(DashronymTooltipCard),
      matching: find.byType(FadeTransition),
    ),
  );
  // The card still fades in either way.
  expect(fade.opacity.value, inExclusiveRange(0, 1));
  final midScale = scale.scale.value;
  await tester.pumpAndSettle();
  return midScale;
}

void main() {
  testWidgets('cards scale in by default', (tester) async {
    expect(
      await _midEntranceScale(tester, reduceMotion: false),
      lessThan(1),
    );
  });

  testWidgets('cards only fade when Reduce Motion is on', (tester) async {
    expect(await _midEntranceScale(tester, reduceMotion: true), 1);
  });
}
