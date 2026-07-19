import 'package:dashronym/dashronym.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AcronymRegistry stores entries case-insensitively by default', () {
    final registry = AcronymRegistry({'SDK': 'Software Development Kit'});

    expect(registry.contains('SDK'), isTrue);
    expect(registry.contains('sdk'), isTrue);
    expect(registry.descriptionOf('sdk'), 'Software Development Kit');
  });

  test('AcronymRegistry respects case sensitivity when disabled', () {
    final registry = AcronymRegistry({
      'API': 'Application Programming Interface',
    }, caseInsensitive: false);

    expect(registry.contains('API'), isTrue);
    expect(registry.contains('api'), isFalse);
    expect(registry.descriptionOf('api'), isNull);
  });

  test('AcronymRegistry defensively copies source entries', () {
    final entries = {'SDK': 'Software Development Kit'};
    final registry = AcronymRegistry(entries);

    entries['SDK'] = 'Changed';
    entries['API'] = 'Application Programming Interface';

    expect(registry['sdk'], 'Software Development Kit');
    expect(registry.containsKey('api'), isFalse);
  });

  test('entries exposes an unmodifiable normalized map', () {
    final registry = AcronymRegistry({
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
    final registry = AcronymRegistry.fromEntries([
      const MapEntry('SDK', 'Software Development Kit'),
      const MapEntry('API', 'Application Programming Interface'),
    ]);

    expect(registry, hasLength(2));
    expect(registry.isEmpty, isFalse);
    expect(registry.isNotEmpty, isTrue);
    expect(registry['api'], 'Application Programming Interface');
    expect(AcronymRegistry.empty().isEmpty, isTrue);
  });
}
