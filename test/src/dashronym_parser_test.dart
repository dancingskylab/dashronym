import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:dashronym/src/dashronym_parser.dart';
import 'package:dashronym/src/dashronym_parser_core.dart';
import 'package:dashronym/src/dashronym_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DashronymParser _parser() => DashronymParser(
  registry: DashronymRegistry({'SDK': 'Software Development Kit'}),
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
      (widgetSpans.single.child as DashronymInline).textScaler,
      TextScaler.noScaling,
    );
    expect(
      spans.map((span) => span.runtimeType),
      containsAll([TextSpan, WidgetSpan]),
    );
  });

  test('DashronymParser caches spans for identical input', () {
    final core = DashronymParserCore(
      registry: DashronymRegistry({'SDK': 'Software Development Kit'}),
      config: const DashronymConfig(enableBareAcronyms: true),
    );
    final first = core.parse('Using (SDK) daily.');
    final second = core.parse('Using (SDK) daily.');

    expect(identical(first, second), isTrue);
  });

  test('parser cache is bounded and reads promote entries', () {
    final core = DashronymParserCore(
      registry: DashronymRegistry.empty(),
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
      registry: DashronymRegistry({'SDK': 'First definition'}),
      config: const DashronymConfig(),
    );
    final secondRegistry = DashronymParserCore(
      registry: DashronymRegistry({'SDK': 'Second definition'}),
      config: const DashronymConfig(),
    );

    expect(
      firstRegistry.parse(input),
      const [
        DashronymTextToken('Use the '),
        DashronymMatchToken(acronym: 'SDK', description: 'First definition'),
        DashronymTextToken('.'),
      ],
    );
    expect(
      secondRegistry.parse(input),
      const [
        DashronymTextToken('Use the '),
        DashronymMatchToken(acronym: 'SDK', description: 'Second definition'),
        DashronymTextToken('.'),
      ],
    );
  });

  test('empty registry cannot receive cached tokens from another registry', () {
    const input = 'Cache isolation for (SDK).';
    final populatedParser = DashronymParserCore(
      registry: DashronymRegistry({'SDK': 'Software Development Kit'}),
      config: const DashronymConfig(),
    );
    final emptyParser = DashronymParserCore(
      registry: DashronymRegistry.empty(),
      config: const DashronymConfig(),
    );

    expect(
      populatedParser.parse(input),
      contains(
        const DashronymMatchToken(
          acronym: 'SDK',
          description: 'Software Development Kit',
        ),
      ),
    );
    expect(emptyParser.parse(input), const [DashronymTextToken(input)]);
  });

  test('parser snapshots marker configuration when it is created', () {
    final markers = ['[]'];
    final parser = DashronymParserCore(
      registry: DashronymRegistry({'SDK': 'Software Development Kit'}),
      config: DashronymConfig(acceptMarkers: markers),
    );

    markers
      ..clear()
      ..add('()');

    expect(
      parser.parse('[SDK]'),
      const [
        DashronymMatchToken(
          acronym: 'SDK',
          description: 'Software Development Kit',
        ),
      ],
    );
    expect(parser.parse('(SDK)'), const [DashronymTextToken('(SDK)')]);
  });

  test('parser supports marker pairs made of non-BMP characters', () {
    final parser = DashronymParserCore(
      registry: DashronymRegistry({'SDK': 'Software Development Kit'}),
      config: const DashronymConfig(acceptMarkers: ['🔹🔸']),
    );

    expect(
      parser.parse('🔹SDK🔸'),
      const [
        DashronymMatchToken(
          acronym: 'SDK',
          description: 'Software Development Kit',
        ),
      ],
    );
  });

  group('explicit marker matching', () {
    test('accepts registered punctuation and mixed-case terms', () {
      final parser = DashronymParserCore(
        registry: DashronymRegistry({
          'C++': 'C Plus Plus',
          '.NET': 'Microsoft .NET',
          'R&D': 'Research and Development',
          'OAuth': 'Open Authorization',
        }),
        config: const DashronymConfig(),
      );

      expect(
        parser.parse('Use (C++), (.NET), (R&D), and (OAuth).'),
        const [
          DashronymTextToken('Use '),
          DashronymMatchToken(acronym: 'C++', description: 'C Plus Plus'),
          DashronymTextToken(', '),
          DashronymMatchToken(acronym: '.NET', description: 'Microsoft .NET'),
          DashronymTextToken(', '),
          DashronymMatchToken(
            acronym: 'R&D',
            description: 'Research and Development',
          ),
          DashronymTextToken(', and '),
          DashronymMatchToken(
            acronym: 'OAuth',
            description: 'Open Authorization',
          ),
          DashronymTextToken('.'),
        ],
      );
    });

    test('resolves aliases and honors registry case sensitivity', () {
      final entry = DashronymEntry(
        acronym: 'DOTNET',
        expansion: 'Microsoft .NET',
        aliases: const ['.NET'],
      );
      final insensitive = DashronymParserCore(
        registry: DashronymRegistry.fromEntries([entry]),
        config: const DashronymConfig(),
      );
      final sensitive = DashronymParserCore(
        registry: DashronymRegistry.fromEntries(
          [entry],
          caseInsensitive: false,
        ),
        config: const DashronymConfig(),
      );

      expect(
        insensitive.parse('(.net)'),
        const [
          DashronymMatchToken(acronym: '.net', description: 'Microsoft .NET'),
        ],
      );
      expect(sensitive.parse('(.net)'), const [DashronymTextToken('(.net)')]);
      expect(
        sensitive.parse('(.NET)'),
        const [
          DashronymMatchToken(acronym: '.NET', description: 'Microsoft .NET'),
        ],
      );
    });

    test('measures explicit terms in Unicode scalar values', () {
      final parser = DashronymParserCore(
        registry: DashronymRegistry({
          'X': 'One scalar',
          'A😀': 'Two scalars',
          'C++': 'Three scalars',
          'OAuth': 'Five scalars',
        }),
        config: const DashronymConfig(minLen: 2, maxLen: 3),
      );

      expect(
        parser.parse('(X) (A😀) (C++) (OAuth)'),
        const [
          DashronymTextToken('(X) '),
          DashronymMatchToken(acronym: 'A😀', description: 'Two scalars'),
          DashronymTextToken(' '),
          DashronymMatchToken(acronym: 'C++', description: 'Three scalars'),
          DashronymTextToken(' (OAuth)'),
        ],
      );
    });

    test(
      'uses the earliest closer and preserves unknown markers literally',
      () {
        const input = '(A)B) (unknown)';
        final parser = DashronymParserCore(
          registry: DashronymRegistry({
            'A)B': 'Must not skip the first closer',
          }),
          config: const DashronymConfig(),
        );

        expect(parser.parse(input), const [DashronymTextToken(input)]);
      },
    );

    test('rejects registered terms containing line breaks', () {
      for (final lineBreak in const ['\n', '\r', '\u2028', '\u2029']) {
        final acronym = 'OAuth${lineBreak}2';
        final input = '($acronym)';
        final parser = DashronymParserCore(
          registry: DashronymRegistry({acronym: 'Must not cross a line break'}),
          config: const DashronymConfig(),
        );

        expect(
          parser.parse(input),
          [DashronymTextToken(input)],
          reason: 'U+${lineBreak.runes.single.toRadixString(16)}',
        );
      }
    });
  });

  test('DashronymParser matches bare acronyms within length bounds', () {
    final parser = DashronymParser(
      registry: DashronymRegistry({
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

  test('bare matching remains conservative ALL-CAPS ASCII', () {
    final parser = DashronymParserCore(
      registry: DashronymRegistry({
        'OAuth': 'Open Authorization',
        'C++': 'C Plus Plus',
        '.NET': 'Microsoft .NET',
        'R&D': 'Research and Development',
        'API': 'Application Programming Interface',
      }),
      config: const DashronymConfig(enableBareAcronyms: true),
    );

    expect(
      parser.parse('OAuth C++ .NET R&D API'),
      const [
        DashronymTextToken('OAuth C++ .NET R&D '),
        DashronymMatchToken(
          acronym: 'API',
          description: 'Application Programming Interface',
        ),
      ],
    );
  });

  test('DashronymParser threads rich entries into inline widgets', () {
    final entry = DashronymEntry(
      acronym: 'SDK',
      expansion: 'Software Development Kit',
      definition: 'Tools used to build software.',
      tags: const ['software'],
      source: 'internal-glossary',
    );
    final parser = DashronymParser(
      registry: DashronymRegistry.fromEntries([entry]),
      config: const DashronymConfig(enableBareAcronyms: true),
      theme: const DashronymTheme(),
      baseStyle: const TextStyle(),
    );

    final widgetSpan = parser
        .parseToSpans('SDK')
        .whereType<WidgetSpan>()
        .single;
    expect((widgetSpan.child as DashronymInline).entry, same(entry));
  });
}
