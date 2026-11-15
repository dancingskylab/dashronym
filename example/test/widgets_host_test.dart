// Dashronym inside apps that use no design system at all.
import 'package:dashronym/dashronym.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});

void main() {
  for (final dark in [false, true]) {
    testWidgets('plain WidgetsApp hosts work (dark text: $dark)', (
      tester,
    ) async {
      await tester.pumpWidget(
        TestWidgetsApp(
          textStyle: TextStyle(
            color: dark ? const Color(0xFFF2F2F2) : const Color(0xFF1C1B1F),
          ),
          home: Center(child: DashronymText('SDK', registry: _registry)),
        ),
      );
      await tester.tap(find.text('SDK'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(isDark(cardSurface(tester)), dark);
    });
  }
}
