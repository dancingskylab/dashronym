import 'dart:convert';
import 'dart:io';

import 'package:dashronym/dashronym_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashronymGlossary', () {
    test('round-trips every version-1 document field', () {
      final glossary = DashronymGlossary(
        name: 'Software basics',
        id: 'com.example.software',
        version: '2026.07.1',
        locale: 'en-CA',
        license: 'LicenseRef-Publisher-Owned',
        source: 'https://example.com/glossary',
        updatedAt: DateTime.parse('2026-07-19T02:30:00-06:00'),
        metadata: const {
          'publisher': {'name': 'Example Publisher'},
          'reviewed': true,
        },
        entries: [
          AcronymEntry(
            acronym: 'API',
            expansion: 'Application Programming Interface',
            definition: 'A contract used by software components.',
            aliases: const ['Web API'],
            tags: const ['software'],
          ),
        ],
      );

      final fromObject = DashronymGlossary.fromJson(glossary.toJson());
      final fromString = DashronymGlossary.fromJsonString(
        glossary.toJsonString(),
      );

      expect(glossary.format, 'dashronym.glossary');
      expect(glossary.schemaVersion, 1);
      expect(glossary.updatedAt, DateTime.utc(2026, 7, 19, 8, 30));
      expect(fromObject, glossary);
      expect(fromString, glossary);
      expect(fromString.hashCode, glossary.hashCode);
      expect(
        glossary.toJson()['updatedAt'],
        '2026-07-19T08:30:00.000Z',
      );
      expect(glossary.toJsonString(pretty: true), contains('\n  "format"'));
    });

    test('decodes a minimal document with stable defaults', () {
      final glossary = DashronymGlossary.fromJson({
        'format': 'dashronym.glossary',
        'schemaVersion': 1,
        'name': 'Minimal',
        'entries': [
          {
            'acronym': 'SDK',
            'expansion': 'Software Development Kit',
          },
        ],
      });

      expect(glossary.id, isNull);
      expect(glossary.version, isNull);
      expect(glossary.locale, isNull);
      expect(glossary.license, isNull);
      expect(glossary.source, isNull);
      expect(glossary.updatedAt, isNull);
      expect(glossary.metadata, isEmpty);
      expect(glossary.entries.single.acronym, 'SDK');
    });

    test('defensively copies entries and deeply freezes metadata', () {
      final entries = [
        AcronymEntry(acronym: 'API', expansion: 'Expansion'),
      ];
      final nested = <Object?>['stable'];
      final metadata = <String, Object?>{'nested': nested};

      final glossary = DashronymGlossary(
        name: 'Immutable',
        entries: entries,
        metadata: metadata,
      );
      entries.add(AcronymEntry(acronym: 'SDK', expansion: 'Other'));
      nested.add('changed');
      metadata['later'] = true;

      expect(glossary.entries, hasLength(1));
      expect(glossary.metadata['nested'], ['stable']);
      expect(
        () => glossary.entries.add(
          AcronymEntry(acronym: 'CLI', expansion: 'Command-line interface'),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => (glossary.metadata['nested'] as List<Object?>).add('x'),
        throwsUnsupportedError,
      );
    });

    test('copyWith updates data and explicitly clears optional fields', () {
      final original = DashronymGlossary(
        name: 'Original',
        id: 'original-id',
        locale: 'en-CA',
        updatedAt: DateTime.utc(2026),
      );

      final updated = original.copyWith(
        name: 'Updated',
        clearId: true,
        locale: 'fr-CA',
        clearUpdatedAt: true,
      );

      expect(updated.name, 'Updated');
      expect(updated.id, isNull);
      expect(updated.locale, 'fr-CA');
      expect(updated.updatedAt, isNull);
      expect(
        () => original.copyWith(id: 'replacement', clearId: true),
        throwsArgumentError,
      );
    });

    test('toRegistry provides direct canonical and alias lookup', () {
      final entry = AcronymEntry(
        acronym: 'API',
        expansion: 'Application Programming Interface',
        aliases: const ['Web API'],
      );
      final glossary = DashronymGlossary(
        name: 'Software',
        entries: [entry],
      );

      final registry = glossary.toRegistry();

      expect(registry.entries, {'API': entry.displayDescription});
      expect(registry.entryOf('web api'), entry);
    });

    test('rejects unsupported format, schema version, and unknown fields', () {
      final valid = <String, Object?>{
        'format': 'dashronym.glossary',
        'schemaVersion': 1,
        'name': 'Glossary',
        'entries': <Object?>[],
      };

      expect(
        () => DashronymGlossary.fromJson({...valid, 'format': 'other'}),
        _formatExceptionContaining(r'$.format'),
      );
      expect(
        () => DashronymGlossary.fromJson({...valid, 'schemaVersion': 2}),
        _formatExceptionContaining(r'$.schemaVersion'),
      );
      expect(
        () => DashronymGlossary.fromJson({...valid, 'schemaVersion': 1.0}),
        _formatExceptionContaining('integer'),
      );
      expect(
        () => DashronymGlossary.fromJson({...valid, 'publisher': 'unknown'}),
        _formatExceptionContaining('metadata'),
      );
    });

    test('rejects missing, null, and incorrectly typed required fields', () {
      expect(
        () => DashronymGlossary.fromJson({
          'format': 'dashronym.glossary',
          'schemaVersion': 1,
          'entries': <Object?>[],
        }),
        _formatExceptionContaining(r'$.name'),
      );
      expect(
        () => DashronymGlossary.fromJson({
          'format': 'dashronym.glossary',
          'schemaVersion': 1,
          'name': null,
          'entries': <Object?>[],
        }),
        _formatExceptionContaining('string'),
      );
      expect(
        () => DashronymGlossary.fromJson({
          'format': 'dashronym.glossary',
          'schemaVersion': 1,
          'name': 'Glossary',
          'entries': 'not an array',
        }),
        _formatExceptionContaining('array'),
      );
    });

    test('accepts RFC 3339 date-times and normalizes offsets to UTC', () {
      final base = <String, Object?>{
        'format': 'dashronym.glossary',
        'schemaVersion': 1,
        'name': 'Glossary',
        'entries': <Object?>[],
      };

      DashronymGlossary decode(String updatedAt) =>
          DashronymGlossary.fromJson({...base, 'updatedAt': updatedAt});

      expect(
        decode('2026-07-19T02:30:00.123456789-06:00').updatedAt,
        DateTime.utc(2026, 7, 19, 8, 30, 0, 123, 456),
      );
      expect(
        decode('2026-07-19t08:30:00z').updatedAt,
        DateTime.utc(2026, 7, 19, 8, 30),
      );
      expect(
        decode('1990-12-31T15:59:60-08:00').updatedAt,
        DateTime.utc(1991),
      );
      expect(
        decode('2026-07-19T08:30:00-00:00').updatedAt,
        DateTime.utc(2026, 7, 19, 8, 30),
      );
    });

    test('rejects non-RFC 3339 date-time syntax', () {
      final base = <String, Object?>{
        'format': 'dashronym.glossary',
        'schemaVersion': 1,
        'name': 'Glossary',
        'entries': <Object?>[],
      };
      final invalidValues = [
        '2026-07-19 08:30:00Z',
        '2026-07-19T08:30Z',
        '2026-07-19T08:30:00',
        '2026-07-19T08:30:00+0000',
        '2026-07-19T08:30:00+00',
        '2026-07-19T08:30:00,5Z',
        '2026-07-19T08:30:00Z\n',
        'not-a-dateZ',
      ];

      for (final updatedAt in invalidValues) {
        expect(
          () => DashronymGlossary.fromJson({
            ...base,
            'updatedAt': updatedAt,
          }),
          _formatExceptionContaining('RFC 3339'),
          reason: updatedAt,
        );
      }
    });

    test('rejects normalized calendar, clock, and offset components', () {
      final base = <String, Object?>{
        'format': 'dashronym.glossary',
        'schemaVersion': 1,
        'name': 'Glossary',
        'entries': <Object?>[],
      };
      final invalidValues = [
        '2026-01-42T08:30:00Z',
        '2025-02-29T08:30:00Z',
        '2026-00-01T08:30:00Z',
        '2026-13-01T08:30:00Z',
        '2026-07-00T08:30:00Z',
        '2026-07-19T24:30:00Z',
        '2026-07-19T08:60:00Z',
        '2026-07-19T08:30:61Z',
        '2026-07-19T08:30:60Z',
        '2026-07-19T08:30:00+24:00',
        '2026-07-19T08:30:00-01:60',
      ];

      for (final updatedAt in invalidValues) {
        expect(
          () => DashronymGlossary.fromJson({
            ...base,
            'updatedAt': updatedAt,
          }),
          _formatExceptionContaining('RFC 3339'),
          reason: updatedAt,
        );
      }
    });

    test('requires a schema-serializable four-digit UTC year', () {
      final glossary = DashronymGlossary(name: 'Glossary');
      expect(
        DashronymGlossary(
          name: 'First supported year',
          updatedAt: DateTime.utc(0),
        ).toJson()['updatedAt'],
        '0000-01-01T00:00:00.000Z',
      );
      expect(
        DashronymGlossary(
          name: 'Last supported year',
          updatedAt: DateTime.utc(9999, 12, 31, 23, 59, 59),
        ).toJson()['updatedAt'],
        '9999-12-31T23:59:59.000Z',
      );

      final outOfRangeYears = [DateTime.utc(-1), DateTime.utc(10000)];

      for (final updatedAt in outOfRangeYears) {
        expect(
          () => DashronymGlossary(
            name: 'Glossary',
            updatedAt: updatedAt,
          ),
          throwsArgumentError,
          reason: '$updatedAt',
        );
        expect(
          () => glossary.copyWith(updatedAt: updatedAt),
          throwsArgumentError,
          reason: '$updatedAt',
        );
      }

      final encodedBase = <String, Object?>{
        'format': 'dashronym.glossary',
        'schemaVersion': 1,
        'name': 'Glossary',
        'entries': <Object?>[],
      };
      expect(
        () => DashronymGlossary.fromJson({
          ...encodedBase,
          'updatedAt': '0000-01-01T00:00:00+00:01',
        }),
        _formatExceptionContaining('four-digit year'),
      );
      expect(
        () => DashronymGlossary.fromJson({
          ...encodedBase,
          'updatedAt': '9999-12-31T23:59:59-00:01',
        }),
        _formatExceptionContaining('four-digit year'),
      );
    });

    test('reports nested entry paths and invalid encoded JSON', () {
      expect(
        () => DashronymGlossary.fromJson({
          'format': 'dashronym.glossary',
          'schemaVersion': 1,
          'name': 'Glossary',
          'entries': [
            {
              'acronym': 'API',
              'expansion': 42,
            },
          ],
        }),
        _formatExceptionContaining(r'$.entries[0].expansion'),
      );
      expect(
        () => DashronymGlossary.fromJsonString('{not json'),
        _formatExceptionContaining('Invalid Dashronym glossary'),
      );
    });

    test('published schema is valid JSON and matches model constants', () {
      final schema =
          jsonDecode(
                File(
                  'schema/v1/dashronym-glossary.schema.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final properties = schema['properties'] as Map<String, Object?>;

      expect(schema[r'$schema'], contains('2020-12'));
      expect(
        schema[r'$id'],
        'https://raw.githubusercontent.com/dancingskylab/dashronym/'
        'v0.1.0/schema/v1/dashronym-glossary.schema.json',
      );
      expect(
        schema['description'],
        contains('canonical acronym'),
      );
      expect(
        (properties['format'] as Map<String, Object?>)['const'],
        DashronymGlossary.supportedFormat,
      );
      expect(
        (properties['schemaVersion'] as Map<String, Object?>)['const'],
        DashronymGlossary.supportedSchemaVersion,
      );
    });
  });
}

Matcher _formatExceptionContaining(String text) => throwsA(
  isA<FormatException>().having(
    (error) => error.message,
    'message',
    contains(text),
  ),
);
