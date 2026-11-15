// Apps still built on package:flutter/material.dart, which Flutter 3.50
// deprecates. Delete this file once Flutter removes that library.
// ignore_for_file: deprecated_member_use
import 'package:dashronym/dashronym.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('legacy Material apps get a ${brightness.name} card', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: Center(child: DashronymText('SDK', registry: _registry)),
          ),
        ),
      );
      await tester.tap(find.text('SDK'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(openCard, findsOneWidget);
      expect(isDark(cardSurface(tester)), brightness == Brightness.dark);
    });
  }

  testWidgets('legacy Material apps can install a DashronymThemeScope', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => DashronymThemeScope(
          data: DashronymTheme(
            cardColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Center(child: DashronymText('SDK', registry: _registry)),
        ),
      ),
    );
    await tester.tap(find.text('SDK'));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(cardSurface(tester), theme.colorScheme.surfaceContainerHigh);
  });
}
