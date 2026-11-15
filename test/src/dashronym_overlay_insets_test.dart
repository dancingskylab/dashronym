// Tooltip placement uses the overlay's insets, which a scaffold strips from
// the trigger's own MediaQuery.
import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_tooltip_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/dashronym_test_host.dart';

void main() {
  testWidgets('cards avoid the keyboard and status bar a scaffold hides', (
    tester,
  ) async {
    // A 400 x 800 window with a 300 px keyboard and a 40 px status bar.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testHost(
        Builder(
          builder: (context) {
            // Like a Scaffold with an app bar and resizeToAvoidBottomInset,
            // remove the insets from the body that hosts the trigger.
            return MediaQuery(
              data: MediaQuery.of(context)
                  .removeViewInsets(removeBottom: true)
                  .removePadding(removeTop: true),
              child: const Stack(
                children: [
                  // Ignoring the keyboard, more room appears below the
                  // trigger than above it, yet a card placed below would
                  // end under the keyboard.
                  Positioned(
                    left: 180,
                    top: 380,
                    child: DashronymInline(
                      acronym: 'SDK',
                      description: 'Software Development Kit',
                      theme: DashronymTheme(enableHover: false),
                      textStyle: TextStyle(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(DashronymTooltipCard));
    expect(card.bottom, lessThanOrEqualTo(800 - 300));
    expect(card.top, greaterThanOrEqualTo(40));
  });

  testWidgets('a 120 px wide window fits the card without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(120, 480);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testHost(
        const Align(
          alignment: Alignment.topCenter,
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

    // An overflow would have failed the test with a layout error.
    final card = tester.getRect(find.byType(DashronymTooltipCard));
    expect(card.left, greaterThanOrEqualTo(0));
    expect(card.right, lessThanOrEqualTo(120));
    expect(find.byTooltip('Hide definition for SDK'), findsOneWidget);
  });
}
