import 'package:dashronym/dashronym_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcronymEntry', () {
    test('stores rich fields and exposes a tooltip-compatible description', () {
      final entry = AcronymEntry(
        acronym: 'API',
        expansion: 'Application Programming Interface',
        definition: 'A contract used by software components.',
        aliases: const ['Web API'],
        tags: const ['software', 'integration'],
        source: 'https://example.com/api',
        metadata: const {'reviewed': true},
      );

      expect(entry.acronym, 'API');
      expect(entry.expansion, 'Application Programming Interface');
      expect(
        entry.displayDescription,
        'Application Programming Interface — '
        'A contract used by software components.',
      );
      expect(entry.aliases, ['Web API']);
      expect(entry.tags, ['software', 'integration']);
      expect(entry.source, 'https://example.com/api');
    });

    test('uses the expansion as the simple display description', () {
      final entry = AcronymEntry(
        acronym: 'SDK',
        expansion: 'Software Development Kit',
      );

      expect(entry.displayDescription, 'Software Development Kit');
    });

    test('defensively copies and deeply freezes all collections', () {
      final aliases = ['Web API'];
      final tags = ['software'];
      final nestedList = <Object?>['stable'];
      final nestedMap = <String, Object?>{'items': nestedList};
      final metadata = <String, Object?>{
        'z': 1,
        'nested': nestedMap,
        'a': true,
      };

      final entry = AcronymEntry(
        acronym: 'API',
        expansion: 'Application Programming Interface',
        aliases: aliases,
        tags: tags,
        metadata: metadata,
      );

      aliases.add('Changed');
      tags.add('changed');
      nestedList.add('changed');
      nestedMap['new'] = true;
      metadata['later'] = true;

      expect(entry.aliases, ['Web API']);
      expect(entry.tags, ['software']);
      expect(entry.metadata.keys, ['a', 'nested', 'z']);
      expect(
        (entry.metadata['nested'] as Map<String, Object?>)['items'],
        ['stable'],
      );
      expect(() => entry.aliases.add('x'), throwsUnsupportedError);
      expect(
        () => (entry.metadata['nested'] as Map<String, Object?>)['x'] = true,
        throwsUnsupportedError,
      );
      expect(
        () =>
            ((entry.metadata['nested'] as Map<String, Object?>)['items']
                    as List<Object?>)
                .add('x'),
        throwsUnsupportedError,
      );
    });

    test('round-trips deterministic JSON with value equality', () {
      final entry = AcronymEntry(
        acronym: 'API',
        expansion: 'Application Programming Interface',
        definition: 'A software contract.',
        aliases: const ['Web API'],
        tags: const ['software'],
        source: 'Publisher-authored',
        metadata: const {
          'z': 2,
          'a': {
            'enabled': true,
            'levels': [1, 2, null],
          },
        },
      );

      final decoded = AcronymEntry.fromJson(entry.toJson());

      expect(decoded, entry);
      expect(decoded.hashCode, entry.hashCode);
      expect(entry.toJson().keys, [
        'acronym',
        'expansion',
        'definition',
        'aliases',
        'tags',
        'source',
        'metadata',
      ]);
      expect(entry.metadata.keys, ['a', 'z']);
    });

    test('decodes omitted optional collections as immutable empty values', () {
      final entry = AcronymEntry.fromJson({
        'acronym': 'SDK',
        'expansion': 'Software Development Kit',
      });

      expect(entry.aliases, isEmpty);
      expect(entry.tags, isEmpty);
      expect(entry.metadata, isEmpty);
      expect(() => entry.metadata['x'] = true, throwsUnsupportedError);
    });

    test('copyWith replaces and explicitly clears optional fields', () {
      final original = AcronymEntry(
        acronym: 'API',
        expansion: 'Original expansion',
        definition: 'Original definition',
        source: 'Original source',
      );

      final updated = original.copyWith(
        expansion: 'Updated expansion',
        clearDefinition: true,
        clearSource: true,
        aliases: const ['Web API'],
      );

      expect(updated.acronym, 'API');
      expect(updated.expansion, 'Updated expansion');
      expect(updated.definition, isNull);
      expect(updated.source, isNull);
      expect(updated.aliases, ['Web API']);
      expect(
        () => original.copyWith(
          definition: 'Replacement',
          clearDefinition: true,
        ),
        throwsArgumentError,
      );
    });

    test('rejects blank, padded, duplicate, and redundant fields', () {
      expect(
        () => AcronymEntry(acronym: '', expansion: 'Expansion'),
        throwsArgumentError,
      );
      expect(
        () => AcronymEntry(acronym: ' API', expansion: 'Expansion'),
        throwsArgumentError,
      );
      expect(
        () => AcronymEntry(acronym: 'API', expansion: ' '),
        throwsArgumentError,
      );
      expect(
        () => AcronymEntry(
          acronym: 'API',
          expansion: 'Expansion',
          aliases: const ['API'],
        ),
        throwsArgumentError,
      );
      expect(
        () => AcronymEntry(
          acronym: 'API',
          expansion: 'Expansion',
          aliases: const ['Web API', 'Web API'],
        ),
        throwsArgumentError,
      );
      expect(
        () => AcronymEntry(
          acronym: 'API',
          expansion: 'Expansion',
          tags: const ['software', 'software'],
        ),
        throwsArgumentError,
      );
      expect(
        () => AcronymEntry(
          acronym: 'API',
          expansion: 'Expansion',
          definition: '',
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects non-JSON, non-finite, non-string-key, and cyclic metadata',
      () {
        final cyclic = <String, Object?>{};
        cyclic['self'] = cyclic;

        for (final metadata in <Map<String, Object?>>[
          {'date': DateTime.utc(2026)},
          {'notFinite': double.nan},
          {'infinite': double.infinity},
          {
            'badKeys': <Object?, Object?>{1: 'not JSON'},
          },
          cyclic,
        ]) {
          expect(
            () => AcronymEntry(
              acronym: 'API',
              expansion: 'Expansion',
              metadata: metadata,
            ),
            throwsArgumentError,
          );
        }
      },
    );

    test('strict JSON decoder reports paths and rejects unknown fields', () {
      expect(
        () => AcronymEntry.fromJson({
          'acronym': 'API',
          'expansion': 'Expansion',
          'typo': true,
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('metadata'),
          ),
        ),
      );
      expect(
        () => AcronymEntry.fromJson({
          'acronym': 'API',
          'expansion': 'Expansion',
          'aliases': [1],
        }, path: r'$.entries[4]'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.entries[4].aliases[0]'),
          ),
        ),
      );
      expect(
        () => AcronymEntry.fromJson({'acronym': 'API'}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(r'$.expansion'),
          ),
        ),
      );
    });
  });
}
