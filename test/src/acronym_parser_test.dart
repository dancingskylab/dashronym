import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/acronym_parser.dart';
import 'package:dashronym/src/acronym_parser_core.dart';
import 'package:dashronym/src/acronym_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DashronymParser _parser() => DashronymParser(
  registry: AcronymRegistry({'SDK': 'Software Development Kit'}),
  config: const DashronymConfig(enableBareAcronyms: true),
  theme: const DashronymTheme(),
  baseStyle: const TextStyle(),
);

void main() {
  test('DashronymParser converts acronyms into widget spans', () {
    final spans = _parser().parseToSpans('Using (SDK) daily.');

    final widgetSpans = spans.whereType<WidgetSpan>().toList(growable: false);
    expect(widgetSpans, hasLength(1));
    expect(
      spans.map((span) => span.runtimeType),
      containsAll([TextSpan, WidgetSpan]),
    );
  });

  test('DashronymParser caches spans for identical input', () {
    final core = DashronymParserCore(
      registry: AcronymRegistry({'SDK': 'Software Development Kit'}),
      config: const DashronymConfig(enableBareAcronyms: true),
    );
    final first = core.parse('Using (SDK) daily.');
    final second = core.parse('Using (SDK) daily.');

    expect(identical(first, second), isTrue);
  });

  test('parser cache is bounded and reads promote entries', () {
    final core = DashronymParserCore(
      registry: AcronymRegistry.empty(),
      config: const DashronymConfig(),
      cacheCapacity: 2,
    );
    final first = core.parse('first');
    final second = core.parse('second');

    expect(identical(core.parse('first'), first), isTrue);
    core.parse('third');

    expect(identical(core.parse('second'), second), isFalse);
  });

  test('parser caches are isolated from other registries', () {
    const input = 'Use the (SDK).';
    final firstRegistry = DashronymParserCore(
      registry: AcronymRegistry({'SDK': 'First definition'}),
      config: const DashronymConfig(),
    );
    final secondRegistry = DashronymParserCore(
      registry: AcronymRegistry({'SDK': 'Second definition'}),
      config: const DashronymConfig(),
    );

    expect(
      firstRegistry.parse(input),
      const [
        TextToken('Use the '),
        AcronymToken(acronym: 'SDK', description: 'First definition'),
        TextToken('.'),
      ],
    );
    expect(
      secondRegistry.parse(input),
      const [
        TextToken('Use the '),
        AcronymToken(acronym: 'SDK', description: 'Second definition'),
        TextToken('.'),
      ],
    );
  });

  test('empty registry cannot receive cached tokens from another registry', () {
    const input = 'Cache isolation for (SDK).';
    final populatedParser = DashronymParserCore(
      registry: AcronymRegistry({'SDK': 'Software Development Kit'}),
      config: const DashronymConfig(),
    );
    final emptyParser = DashronymParserCore(
      registry: AcronymRegistry.empty(),
      config: const DashronymConfig(),
    );

    expect(
      populatedParser.parse(input),
      contains(
        const AcronymToken(
          acronym: 'SDK',
          description: 'Software Development Kit',
        ),
      ),
    );
    expect(emptyParser.parse(input), const [TextToken(input)]);
  });

  test('parser snapshots marker configuration when it is created', () {
    final markers = ['[]'];
    final parser = DashronymParserCore(
      registry: AcronymRegistry({'SDK': 'Software Development Kit'}),
      config: DashronymConfig(acceptMarkers: markers),
    );

    markers
      ..clear()
      ..add('()');

    expect(
      parser.parse('[SDK]'),
      const [
        AcronymToken(
          acronym: 'SDK',
          description: 'Software Development Kit',
        ),
      ],
    );
    expect(parser.parse('(SDK)'), const [TextToken('(SDK)')]);
  });

  test('parser supports marker pairs made of non-BMP characters', () {
    final parser = DashronymParserCore(
      registry: AcronymRegistry({'SDK': 'Software Development Kit'}),
      config: const DashronymConfig(acceptMarkers: ['🔹🔸']),
    );

    expect(
      parser.parse('🔹SDK🔸'),
      const [
        AcronymToken(
          acronym: 'SDK',
          description: 'Software Development Kit',
        ),
      ],
    );
  });

  test('DashronymParser matches bare acronyms within length bounds', () {
    final parser = DashronymParser(
      registry: AcronymRegistry({
        'SDK': 'Software Development Kit',
        'CI': 'Continuous Integration',
      }),
      config: const DashronymConfig(
        enableBareAcronyms: true,
        minLen: 2,
        maxLen: 3,
      ),
      theme: const DashronymTheme(),
      baseStyle: const TextStyle(),
    );

    final spans = parser.parseToSpans('SDK tooling and CI runs');
    final widgetSpans = spans.whereType<WidgetSpan>().toList(growable: false);

    expect(widgetSpans.length, 2);
  });
}
