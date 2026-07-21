import 'package:dashronym/dashronym_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashronymRegistry stores entries case-insensitively by default', () {
    final registry = DashronymRegistry({'SDK': 'Software Development Kit'});

    expect(registry.contains('SDK'), isTrue);
    expect(registry.contains('sdk'), isTrue);
    expect(registry.descriptionOf('sdk'), 'Software Development Kit');
  });

  test('DashronymRegistry respects case sensitivity when disabled', () {
    final registry = DashronymRegistry({
      'API': 'Application Programming Interface',
    }, caseInsensitive: false);

    expect(registry.contains('API'), isTrue);
    expect(registry.contains('api'), isFalse);
    expect(registry.descriptionOf('api'), isNull);
  });

  test('DashronymRegistry defensively copies source entries', () {
    final entries = {'SDK': 'Software Development Kit'};
    final registry = DashronymRegistry(entries);

    entries['SDK'] = 'Changed';
    entries['API'] = 'Application Programming Interface';

    expect(registry['sdk'], 'Software Development Kit');
    expect(registry.containsKey('api'), isFalse);
  });

  test('entries exposes an unmodifiable normalized map', () {
    final registry = DashronymRegistry({
      'api': 'Application Programming Interface',
    });

    expect(registry.entries, {
      'API': 'Application Programming Interface',
    });
    expect(
      () => registry.entries['SDK'] = 'Software Development Kit',
      throwsUnsupportedError,
    );
  });

  test('registry exposes collection-style conveniences', () {
    final registry = DashronymRegistry.fromMapEntries([
      const MapEntry('SDK', 'Software Development Kit'),
      const MapEntry('API', 'Application Programming Interface'),
    ]);

    expect(registry, hasLength(2));
    expect(registry.isEmpty, isFalse);
    expect(registry.isNotEmpty, isTrue);
    expect(registry['api'], 'Application Programming Interface');
    expect(DashronymRegistry.empty().isEmpty, isTrue);
  });

  test('legacy registry preserves blank and whitespace string values', () {
    final registry = DashronymRegistry({
      '': '',
      ' spaced ': ' padded description ',
    });

    expect(registry.contains(''), isTrue);
    expect(registry.descriptionOf(''), '');
    expect(registry.descriptionOf(' spaced '), ' padded description ');
    expect(registry.entries, {
      '': '',
      ' SPACED ': ' padded description ',
    });
    expect(registry.entryOf(''), isNull);
    expect(registry.entryOf(' spaced '), isNull);
  });

  test('legacy map keeps the later normalized key by default', () {
    final registry = DashronymRegistry({
      'api': 'First',
      'API': 'Second',
    });

    expect(registry.length, 1);
    expect(registry.descriptionOf('api'), 'Second');
  });

  test('rich entries support aliases without changing canonical length', () {
    final entry = DashronymEntry(
      acronym: 'API',
      expansion: 'Application Programming Interface',
      definition: 'A software contract.',
      aliases: const ['Web API', 'Application Interface'],
    );
    final registry = DashronymRegistry.fromEntries([entry]);

    expect(registry.length, 1);
    expect(registry.lookupTermCount, 3);
    expect(registry.entries.keys, ['API']);
    expect(registry.lookupTerms.keys, [
      'API',
      'WEB API',
      'APPLICATION INTERFACE',
    ]);
    expect(registry.descriptionOf('web api'), entry.displayDescription);
    expect(identical(registry.entryOf('application interface'), entry), isTrue);
    expect(registry.richEntries, [entry]);
    expect(
      () => registry.richEntries.add(entry),
      throwsUnsupportedError,
    );
  });

  test('rich alias lookup respects case sensitivity', () {
    final upper = DashronymEntry(
      acronym: 'API',
      expansion: 'Upper',
      aliases: const ['Web API'],
    );
    final lower = DashronymEntry(
      acronym: 'api',
      expansion: 'Lower',
      aliases: const ['web api'],
    );
    final registry = DashronymRegistry.fromEntries(
      [upper, lower],
      caseInsensitive: false,
    );

    expect(registry.descriptionOf('API'), 'Upper');
    expect(registry.descriptionOf('api'), 'Lower');
    expect(registry.entryOf('Web API'), upper);
    expect(registry.entryOf('web api'), lower);
  });

  test('rich registry rejects canonical and alias ambiguity by default', () {
    final first = DashronymEntry(
      acronym: 'API',
      expansion: 'First',
      aliases: const ['Shared'],
    );
    final second = DashronymEntry(
      acronym: 'SDK',
      expansion: 'Second',
      aliases: const ['shared'],
    );

    expect(
      () => DashronymRegistry.fromEntries([first, second]),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('conflicts'),
        ),
      ),
    );
  });

  test('keepFirst skips the complete later conflicting rich entry', () {
    final first = DashronymEntry(
      acronym: 'API',
      expansion: 'First',
      aliases: const ['Shared'],
    );
    final second = DashronymEntry(
      acronym: 'SDK',
      expansion: 'Second',
      aliases: const ['shared'],
    );
    final registry = DashronymRegistry.fromEntries(
      [first, second],
      duplicatePolicy: DashronymDuplicatePolicy.keepFirst,
    );

    expect(registry.entries, {'API': 'First'});
    expect(registry.contains('SDK'), isFalse);
    expect(registry.entryOf('shared'), first);
    expect(registry.richEntries, [first]);
  });

  test('keepLast atomically displaces complete earlier rich entries', () {
    final first = DashronymEntry(
      acronym: 'API',
      expansion: 'First',
      aliases: const ['Shared'],
    );
    final second = DashronymEntry(
      acronym: 'SDK',
      expansion: 'Second',
      aliases: const ['shared'],
    );
    final registry = DashronymRegistry.fromEntries(
      [first, second],
      duplicatePolicy: DashronymDuplicatePolicy.keepLast,
    );

    expect(registry.entries, {'SDK': 'Second'});
    expect(registry.contains('API'), isFalse);
    expect(registry.entryOf('shared'), second);
    expect(registry.richEntries, [second]);
  });

  test('fromMapEntries honors duplicate policies before map collapsing', () {
    const source = [
      MapEntry('API', 'First'),
      MapEntry('API', 'Second'),
    ];

    expect(
      () => DashronymRegistry.fromMapEntries(
        source,
        duplicatePolicy: DashronymDuplicatePolicy.reject,
      ),
      throwsArgumentError,
    );
    expect(
      DashronymRegistry.fromMapEntries(
        source,
        duplicatePolicy: DashronymDuplicatePolicy.keepFirst,
      ).descriptionOf('API'),
      'First',
    );
    expect(
      DashronymRegistry.fromMapEntries(source).descriptionOf('API'),
      'Second',
    );
  });
}
