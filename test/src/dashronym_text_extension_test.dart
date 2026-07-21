import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<InlineSpan> _walkSpans(InlineSpan span) sync* {
  yield span;
  if (span case final TextSpan textSpan) {
    for (final child in textSpan.children ?? const <InlineSpan>[]) {
      yield* _walkSpans(child);
    }
  }
}

void main() {
  testWidgets('Text.dashronyms wraps strings with tooltip spans', (
    tester,
  ) async {
    final registry = DashronymRegistry({
      'API': 'Application Programming Interface',
    });
    final widget = const Text(
      'Our (API) is public.',
    ).dashronyms(registry: registry, config: const DashronymConfig());

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

    expect(find.byType(DashronymInline), findsOneWidget);
  });

  testWidgets('Text.dashronyms preserves an unmatched rich source tree', (
    tester,
  ) async {
    final original = Text.rich(
      const TextSpan(text: 'Hello'),
      textScaler: const TextScaler.linear(1.2),
    );

    final result =
        original.dashronyms(registry: DashronymRegistry({})) as DashronymText;

    expect(result.text, isEmpty);
    expect(result.inlineSpan, same(original.textSpan));
    expect(result.textScaler, const TextScaler.linear(1.2));
  });

  testWidgets(
    'Text.rich processes nested text and preserves authored span metadata',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var recognizerInvoked = false;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => recognizerInvoked = true;
      addTearDown(recognizer.dispose);
      const existingWidget = WidgetSpan(
        child: SizedBox(
          key: ValueKey('existing-widget-span'),
          width: 12,
          height: 12,
        ),
      );
      const labelledSpan = TextSpan(
        text: 'SDK',
        semanticsLabel: 'Author SDK label',
      );
      final source = TextSpan(
        style: const TextStyle(color: Colors.red),
        children: [
          TextSpan(
            text: 'Use API now. ',
            style: const TextStyle(fontWeight: FontWeight.bold),
            recognizer: recognizer,
            locale: const Locale('en'),
            spellOut: true,
          ),
          existingWidget,
          labelledSpan,
        ],
      );
      final original = Text.rich(
        source,
        textScaler: const TextScaler.linear(1.2),
        semanticsIdentifier: 'rich-copy',
      );
      final result = original.dashronyms(
        registry: DashronymRegistry({
          'API': 'Application Programming Interface',
          'SDK': 'Software Development Kit',
        }),
        config: const DashronymConfig(enableBareAcronyms: true),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: result)),
      );

      expect(find.byType(DashronymInline), findsOneWidget);
      expect(
        find.byKey(const ValueKey('existing-widget-span')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byType(DashronymInline),
                matching: find.text('API'),
              ),
            )
            .style,
        isA<TextStyle>()
            .having((style) => style.color, 'color', Colors.red)
            .having(
              (style) => style.fontWeight,
              'fontWeight',
              FontWeight.bold,
            ),
      );

      final richText = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere(
            (widget) => widget.text
                .toPlainText(includePlaceholders: true)
                .contains('Use '),
          );
      final flattened = _walkSpans(richText.text).toList();
      expect(
        flattened.whereType<WidgetSpan>().any(
          (span) => identical(span, existingWidget),
        ),
        isTrue,
      );
      expect(flattened.any((span) => identical(span, labelledSpan)), isTrue);

      final preservedPlain = flattened.whereType<TextSpan>().firstWhere(
        (span) => span.text == 'Use ',
      );
      expect(preservedPlain.recognizer, same(recognizer));
      expect(preservedPlain.locale, const Locale('en'));
      expect(preservedPlain.spellOut, isTrue);
      recognizer.onTap!();
      expect(recognizerInvoked, isTrue);

      expect(
        labelledSpan.toPlainText(includeSemanticsLabels: true),
        'Author SDK label',
      );
      expect(find.bySemanticsIdentifier('rich-copy'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('Text.dashronyms inherits registry and config from scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashronymScope(
          registry: DashronymRegistry({
            'API': 'Application Programming Interface',
          }),
          config: const DashronymConfig(enableBareAcronyms: true),
          child: Scaffold(
            body: const Text('Use API').dashronyms(),
          ),
        ),
      ),
    );

    expect(find.byType(DashronymInline), findsOneWidget);
  });

  testWidgets(
    'matched rich span keeps inherited locale, spellOut, and one identifier',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final source = TextSpan(
        locale: const Locale('fr'),
        spellOut: true,
        children: const [
          TextSpan(
            text: 'API',
            semanticsIdentifier: 'authored-api',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text.rich(source).dashronyms(
              registry: DashronymRegistry({
                'API': 'Application Programming Interface',
              }),
              config: const DashronymConfig(enableBareAcronyms: true),
            ),
          ),
        ),
      );

      final inline = tester.widget<DashronymInline>(
        find.byType(DashronymInline),
      );
      expect(inline.locale, const Locale('fr'));
      expect(inline.spellOut, isTrue);
      expect(inline.semanticsIdentifier, 'authored-api');
      final inlineSemanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.identifier == 'authored-api',
      );
      expect(inlineSemanticsFinder, findsOneWidget);
      final inlineSemantics = tester.widget<Semantics>(inlineSemanticsFinder);
      expect(inlineSemantics.container, isTrue);
      expect(find.bySemanticsIdentifier('authored-api'), findsOneWidget);

      final node = tester.getSemantics(
        find.bySemanticsIdentifier('authored-api'),
      );
      expect(node.attributedLabel.string, 'API');
      expect(
        node.attributedLabel.attributes.whereType<SpellOutStringAttribute>(),
        hasLength(1),
      );
      expect(
        node.attributedLabel.attributes.whereType<LocaleStringAttribute>(),
        hasLength(1),
      );

      semantics.dispose();
    },
  );

  testWidgets('Text.dashronyms merges inherited style and bold text', (
    tester,
  ) async {
    final registry = DashronymRegistry({'SDK': 'Software Development Kit'});

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(boldText: true),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: Scaffold(
              body: const Text(
                'SDK launch successful',
              ).dashronyms(registry: registry),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('Text.dashronyms keeps explicit non-inherited style', (
    tester,
  ) async {
    final registry = DashronymRegistry({'SDK': 'Software Development Kit'});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Text(
            'SDK ready',
            style: TextStyle(inherit: false, fontSize: 22),
          ).dashronyms(registry: registry),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    expect(richText.text.style?.fontSize, 22);
  });
}
