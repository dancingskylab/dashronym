// Dashronym inside apps built on package:cupertino_ui.
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:dashronym/dashronym.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});

Future<void> _pumpCupertinoApp(
  WidgetTester tester, {
  required Brightness brightness,
  DashronymTheme theme = const DashronymTheme(),
}) async {
  await tester.pumpWidget(
    CupertinoApp(
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: CupertinoColors.systemIndigo,
      ),
      home: CupertinoPageScaffold(
        child: Center(
          child: DashronymThemeScope(
            data: theme,
            child: DashronymText('SDK', registry: _registry),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('SDK'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Cupertino apps get a ${brightness.name} card', (
      tester,
    ) async {
      await _pumpCupertinoApp(tester, brightness: brightness);

      expect(openCard, findsOneWidget);
      expect(isDark(cardSurface(tester)), brightness == Brightness.dark);
    });
  }

  testWidgets('Cupertino icons take the app primary color', (tester) async {
    await _pumpCupertinoApp(
      tester,
      brightness: Brightness.light,
      theme: const DashronymTheme(
        cardIcon: CupertinoIcons.info,
        cardCloseIcon: CupertinoIcons.xmark,
      ),
    );

    final primary = CupertinoColors.systemIndigo.resolveFrom(
      tester.element(find.byType(CupertinoPageScaffold)),
    );
    expect(
      tester.widget<Icon>(find.byIcon(CupertinoIcons.info)).color,
      primary,
    );
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
  });
}
