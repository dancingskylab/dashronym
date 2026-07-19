import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/tooltip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashronymTooltipCard decorates semantics and styles', (
    tester,
  ) async {
    final onClose = ValueNotifier(false);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DashronymLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: DashronymLocalizations.supportedLocales,
        home: Material(
          child: DashronymTooltipCard(
            acronym: 'SDK',
            description: 'Software Development Kit',
            theme: const DashronymTheme(),
            onClose: () => onClose.value = true,
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(DashronymTooltipCard));
    expect(semantics.label, 'Definition for SDK');
    expect(semantics.value, 'Software Development Kit');

    await tester.tap(find.byTooltip('Hide definition for SDK'));
    await tester.pump();
    expect(onClose.value, isTrue);
  });

  testWidgets('DashronymTooltipCard applies width constraints from theme', (
    tester,
  ) async {
    const theme = DashronymTheme(tooltipMinWidth: 180, tooltipMaxWidth: 220);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DashronymLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: DashronymLocalizations.supportedLocales,
        home: Material(
          child: DashronymTooltipCard(
            acronym: 'API',
            description: 'Application Programming Interface',
            theme: theme,
            onClose: () {},
          ),
        ),
      ),
    );

    final constrainedBox = tester
        .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
        .firstWhere((box) => box.constraints.maxWidth.isFinite);
    expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(180));
    expect(
      constrainedBox.constraints.maxWidth,
      greaterThanOrEqualTo(constrainedBox.constraints.minWidth),
    );
    expect(constrainedBox.constraints.maxWidth, lessThanOrEqualTo(360));
  });

  testWidgets('DashronymTooltipCard expands when landscape is wide', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          DashronymLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: DashronymLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(640, 360)),
          child: Center(
            child: SizedBox(
              width: 600,
              child: DashronymTooltipCard(
                acronym: 'SDK',
                description: 'Software Development Kit',
                theme: const DashronymTheme(),
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final card = tester.getSize(find.byType(DashronymTooltipCard));
    expect(card.width, inInclusiveRange(0, 600));
    expect(card.width, greaterThanOrEqualTo(320));
  });
}
