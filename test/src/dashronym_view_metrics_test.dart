// Cards react only to metric changes of their own view.
import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

Future<void> _openCard(WidgetTester tester) async {
  await tester.pumpWidget(
    testHost(
      const Center(
        child: DashronymInline(
          acronym: 'SDK',
          description: 'Software Development Kit',
          theme: DashronymTheme(enableHover: false),
          textStyle: TextStyle(),
        ),
      ),
    ),
  );
  await tester.tap(find.text('SDK'));
  await tester.pumpAndSettle();
  expect(find.byType(DashronymTooltipCard), findsOneWidget);
}

void main() {
  testWidgets('a metrics change of another view keeps the card open', (
    tester,
  ) async {
    await _openCard(tester);

    // Every view's metric change notifies every binding observer; with this
    // view unchanged, the change must belong to another window.
    tester.binding.handleMetricsChanged();
    await tester.pumpAndSettle();

    expect(find.byType(DashronymTooltipCard), findsOneWidget);
  });

  testWidgets('resizing this view closes the card', (tester) async {
    addTearDown(tester.view.reset);
    await _openCard(tester);

    tester.view.physicalSize = tester.view.physicalSize * 1.25;
    await tester.pumpAndSettle();

    expect(find.byType(DashronymTooltipCard), findsNothing);
  });
}
