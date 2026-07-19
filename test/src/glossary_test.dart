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

    test('requires an ISO date-time with an explicit timezone', () {
      final base = <String, Object?>{
        'format': 'dashronym.glossary',
        'schemaVersion': 1,
        'name': 'Glossary',
        'entries': <Object?>[],
      };

      expect(
        () => DashronymGlossary.fromJson({
          ...base,
          'updatedAt': '2026-07-19T08:30:00',
        }),
        _formatExceptionContaining('timezone'),
      );
      expect(
        () => DashronymGlossary.fromJson({
          ...base,
          'updatedAt': 'not-a-dateZ',
        }),
        _formatExceptionContaining('ISO 8601'),
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
                  'schema/dashronym-glossary.schema.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final properties = schema['properties'] as Map<String, Object?>;

      expect(schema[r'$schema'], contains('2020-12'));
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
