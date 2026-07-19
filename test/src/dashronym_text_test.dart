import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/acronym_inline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashronymText renders widget spans with provided text scaler', (
    tester,
  ) async {
    final widget = DashronymText(
      'Our (SDK) is stable.',
      registry: AcronymRegistry({'SDK': 'Software Development Kit'}),
      config: const DashronymConfig(),
      theme: const DashronymTheme(),
      textScaler: const TextScaler.linear(1.5),
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

    final richText = tester.widgetList<RichText>(find.byType(RichText)).first;
    final span = richText.text as TextSpan;

    expect(richText.textScaler, const TextScaler.linear(1.5));
    expect(span.children?.whereType<WidgetSpan>().length, 1);
  });

  testWidgets(
    'DashronymText merges inherited style and honors semanticsLabel',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final registry = AcronymRegistry({'SDK': 'Software Development Kit'});

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(boldText: true),
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 12),
              child: Scaffold(
                body: DashronymText(
                  'This SDK is powerful.',
                  registry: registry,
                  config: const DashronymConfig(enableBareAcronyms: true),
                  theme: const DashronymTheme(),
                  semanticsLabel: 'SDK definition label',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      expect(richText.text.style?.fontWeight, FontWeight.bold);

      final semanticsNode = tester.getSemantics(
        find.bySemanticsLabel('SDK definition label'),
      );
      expect(semanticsNode.label, 'SDK definition label');
      final acronymNode = tester.getSemantics(
        find.bySemanticsLabel('SDK').first,
      );
      expect(acronymNode.flagsCollection.isButton, isTrue);

      semantics.dispose();
    },
  );

  testWidgets('DashronymText respects non-inherited style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashronymText(
            'SDK docs',
            registry: AcronymRegistry({'SDK': 'Software Development Kit'}),
            style: const TextStyle(inherit: false, fontSize: 18),
            config: const DashronymConfig(),
            theme: const DashronymTheme(),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.style?.fontSize, 18);
  });

  testWidgets('WidgetSpan trigger is rendered with exactly one scale pass', (
    tester,
  ) async {
    const referenceKey = ValueKey('reference');
    const tooltipReferenceKey = ValueKey('tooltip-reference');
    const tooltipKey = ValueKey('tooltip-probe');
    const style = TextStyle(fontSize: 20, height: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('SDK', key: referenceKey, style: style),
                    DashronymText(
                      'SDK',
                      registry: AcronymRegistry({
                        'SDK': 'Software Development Kit',
                      }),
                      config: const DashronymConfig(
                        enableBareAcronyms: true,
                      ),
                      style: style,
                      textScaler: const TextScaler.linear(2),
                      tooltipBuilder: (context, details) {
                        return const Material(
                          child: Text(
                            'A B',
                            key: tooltipKey,
                            style: style,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Text(
                  'A B',
                  key: tooltipReferenceKey,
                  style: style,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final mainRichText = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere(
          (widget) =>
              widget.text.toPlainText(includePlaceholders: true) == '\uFFFC',
        );
    final mainRichTextFinder = find.byWidget(mainRichText);
    final triggerTextFinder = find.descendant(
      of: find.byType(AcronymInline),
      matching: find.text('SDK'),
    );

    expect(
      tester.widget<Text>(triggerTextFinder).textScaler,
      TextScaler.noScaling,
    );
    expect(
      tester.getRect(triggerTextFinder).height,
      closeTo(tester.getRect(find.byKey(referenceKey)).height, 0.01),
    );

    final referenceRect = tester.getRect(find.byKey(referenceKey));
    final dashronymRect = tester.getRect(mainRichTextFinder);
    expect(dashronymRect.top, closeTo(referenceRect.top, 0.01));
    expect(dashronymRect.bottom, closeTo(referenceRect.bottom, 0.01));

    await tester.tap(triggerTextFinder);
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.byKey(tooltipKey))),
      const TextScaler.linear(2),
    );
    expect(
      tester.getSize(find.byKey(tooltipKey)).width,
      allOf(greaterThan(0), lessThanOrEqualTo(360)),
    );
    expect(
      tester.getSize(find.byKey(tooltipKey)).height,
      closeTo(
        tester.getSize(find.byKey(tooltipReferenceKey)).height,
        0.01,
      ),
    );
  });

  testWidgets(
    'WidgetSpan keeps explicit direction and locale while tooltip keeps scaler',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: DashronymText(
                'Our SDK',
                registry: AcronymRegistry({
                  'SDK': 'Software Development Kit',
                }),
                config: const DashronymConfig(enableBareAcronyms: true),
                textScaler: const TextScaler.linear(1.5),
                textDirection: TextDirection.rtl,
                locale: const Locale('ar'),
              ),
            ),
          ),
        ),
      );

      final richText = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((widget) => widget.text.toPlainText().contains('Our'));
      expect(richText.textScaler, const TextScaler.linear(1.5));
      expect(richText.textDirection, TextDirection.rtl);
      expect(richText.locale, const Locale('ar'));

      final inlineText = find.text('SDK');
      final inlineContext = tester.element(inlineText);
      final inlineWidget = tester.widget<Text>(inlineText);
      expect(inlineWidget.textScaler, TextScaler.noScaling);
      expect(inlineWidget.locale, const Locale('ar'));
      expect(
        MediaQuery.textScalerOf(inlineContext),
        const TextScaler.linear(1.5),
      );
      expect(Directionality.of(inlineContext), TextDirection.rtl);
      expect(Localizations.localeOf(inlineContext), const Locale('ar'));
    },
  );

  testWidgets('DashronymText participates in SelectionArea registration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          child: DashronymText(
            'Our SDK is selectable.',
            registry: AcronymRegistry({
              'SDK': 'Software Development Kit',
            }),
            config: const DashronymConfig(enableBareAcronyms: true),
          ),
        ),
      ),
    );

    final richText = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere(
          (widget) => widget.text.toPlainText().contains('selectable'),
        );
    expect(richText.selectionRegistrar, isNotNull);
    expect(richText.selectionColor, isNotNull);
  });

  testWidgets(
    'explicit values override scope and theme extension fallbacks',
    (tester) async {
      final scopeRegistry = AcronymRegistry({
        'API': 'Scope definition',
      });
      final explicitRegistry = AcronymRegistry({
        'API': 'Explicit definition',
      });
      const extensionTheme = DashronymTheme(
        acronymStyle: TextStyle(color: Colors.red),
      );
      const scopeTheme = DashronymTheme(
        acronymStyle: TextStyle(color: Colors.green),
      );
      const explicitTheme = DashronymTheme(
        acronymStyle: TextStyle(color: Colors.blue),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [extensionTheme]),
          home: Scaffold(
            body: Column(
              children: [
                DashronymScope(
                  registry: scopeRegistry,
                  config: const DashronymConfig(
                    enableBareAcronyms: true,
                  ),
                  theme: scopeTheme,
                  tooltipBuilder: (context, details) {
                    return Text(
                      details.description,
                      key: const ValueKey('scope-tooltip'),
                    );
                  },
                  child: Column(
                    children: [
                      const DashronymText(
                        'API',
                        key: ValueKey('scoped-text'),
                      ),
                      DashronymText(
                        'API',
                        key: const ValueKey('explicit-text'),
                        registry: explicitRegistry,
                        config: const DashronymConfig(
                          enableBareAcronyms: true,
                        ),
                        theme: explicitTheme,
                        tooltipBuilder: (context, details) {
                          return Text(
                            details.description,
                            key: const ValueKey('explicit-tooltip'),
                          );
                        },
                      ),
                      const DashronymText(
                        'API',
                        key: ValueKey('explicit-config-text'),
                        config: DashronymConfig(),
                      ),
                    ],
                  ),
                ),
                DashronymText(
                  'API',
                  key: const ValueKey('extension-text'),
                  registry: scopeRegistry,
                  config: const DashronymConfig(
                    enableBareAcronyms: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      AcronymInline inlineFor(Key key) {
        return tester.widget<AcronymInline>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(AcronymInline),
          ),
        );
      }

      expect(
        inlineFor(const ValueKey('scoped-text')).theme,
        same(scopeTheme),
      );
      expect(
        inlineFor(const ValueKey('scoped-text')).description,
        'Scope definition',
      );
      expect(
        inlineFor(const ValueKey('explicit-text')).theme,
        same(explicitTheme),
      );
      expect(
        inlineFor(const ValueKey('explicit-text')).description,
        'Explicit definition',
      );
      expect(
        inlineFor(const ValueKey('extension-text')).theme,
        same(extensionTheme),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('explicit-config-text')),
          matching: find.byType(AcronymInline),
        ),
        findsNothing,
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('scoped-text')),
          matching: find.text('API'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scope-tooltip')), findsOneWidget);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('explicit-text')),
          matching: find.text('API'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('explicit-tooltip')), findsOneWidget);
    },
  );

  testWidgets('missing registry reports a focused FlutterError', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DashronymText('API')),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
      error.toString(),
      contains('DashronymText requires an AcronymRegistry'),
    );
    expect(error.toString(), contains('DashronymScope'));
  });
}
