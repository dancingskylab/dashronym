import 'package:dashronym/dashronym.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores entries case-insensitively by default', () {
    final registry = DashronymRegistry({'SDK': 'Software Development Kit'});

    expect(registry.contains('SDK'), isTrue);
    expect(registry.contains('sdk'), isTrue);
    expect(registry.descriptionOf('sdk'), 'Software Development Kit');
  });

  test('respects case sensitivity when disabled', () {
    final registry = DashronymRegistry({
      'API': 'Application Programming Interface',
    }, caseInsensitive: false);

    expect(registry.contains('API'), isTrue);
    expect(registry.contains('api'), isFalse);
    expect(registry.descriptionOf('api'), isNull);
  });

  test('defensively copies source entries', () {
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

  test('exposes collection-style conveniences', () {
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

  test('preserves exact string values', () {
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
  });

  test('keeps the later normalized key', () {
    final registry = DashronymRegistry({
      'api': 'First',
      'API': 'Second',
    });

    expect(registry.length, 1);
    expect(registry.descriptionOf('api'), 'Second');
  });

  test('fromMapEntries keeps the later duplicate', () {
    final registry = DashronymRegistry.fromMapEntries(const [
      MapEntry('API', 'First'),
      MapEntry('api', 'Second'),
      MapEntry('API', 'Third'),
    ]);

    expect(registry.entries, {'API': 'Third'});
  });

  test('uses value equality for normalized contents', () {
    final first = DashronymRegistry({
      'api': 'Application Programming Interface',
      'SDK': 'Software Development Kit',
    });
    final equivalent = DashronymRegistry({
      'sdk': 'Software Development Kit',
      'API': 'Application Programming Interface',
    });

    expect(first, equivalent);
    expect(first.hashCode, equivalent.hashCode);
    expect({first, equivalent}, hasLength(1));
  });

  test('equality includes descriptions and case sensitivity', () {
    final registry = DashronymRegistry({'API': 'First'});

    expect(registry, isNot(DashronymRegistry({'API': 'Second'})));
    expect(
      registry,
      isNot(
        DashronymRegistry(
          {'API': 'First'},
          caseInsensitive: false,
        ),
      ),
    );
  });
}
