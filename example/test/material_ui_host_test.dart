// Dashronym inside apps built on package:material_ui.
import 'package:dashronym/dashronym.dart';
import 'package:dashronym_example/main.dart';
import 'package:dashronym_example/material_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});

Future<ThemeData> _pumpMaterialApp(
  WidgetTester tester, {
  required Brightness brightness,
  bool useRecipe = true,
}) async {
  late ThemeData theme;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: brightness),
      localizationsDelegates: const [
        DashronymLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) {
        theme = Theme.of(context);
        if (!useRecipe) return child!;
        return DashronymThemeScope(
          data: dashronymThemeFromMaterial(theme),
          child: child!,
        );
      },
      home: Scaffold(
        body: Center(child: DashronymText('SDK', registry: _registry)),
      ),
    ),
  );
  await tester.tap(find.text('SDK'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return theme;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('the Material recipe styles the card (${brightness.name})', (
      tester,
    ) async {
      final theme = await _pumpMaterialApp(tester, brightness: brightness);

      expect(cardSurface(tester), theme.colorScheme.surface);
      final info = tester.widget<Icon>(find.byIcon(Icons.info_outline));
      expect(info.color, theme.colorScheme.primary);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('without the recipe the card still follows '
        '${brightness.name} mode', (tester) async {
      await _pumpMaterialApp(
        tester,
        brightness: brightness,
        useRecipe: false,
      );

      expect(isDark(cardSurface(tester)), brightness == Brightness.dark);
    });
  }

  testWidgets('the example app opens a Material-styled definition', (
    tester,
  ) async {
    await tester.pumpWidget(const DashronymExampleApp());
    await tester.tap(find.text('SDK').first);
    await tester.pumpAndSettle();

    expect(openCard, findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
