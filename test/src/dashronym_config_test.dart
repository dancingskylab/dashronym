import 'package:dashronym/dashronym.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes sensible defaults', () {
    const config = DashronymConfig();

    expect(config.enableBareAcronyms, isTrue);
    expect(config.minLen, 2);
    expect(config.maxLen, 10);
    expect(config.acceptMarkers, ['()', "''", '""']);
  });

  test('respects custom markers and lengths', () {
    const markers = ['[]', '{}'];
    final config = DashronymConfig.withMarkers(
      enableBareAcronyms: false,
      minLen: 3,
      maxLen: 6,
      acceptMarkers: markers,
    );

    expect(config.enableBareAcronyms, isFalse);
    expect(config.minLen, 3);
    expect(config.maxLen, 6);
    expect(config.acceptMarkers, markers);
  });

  test('acceptMarkers cannot be mutated through the configuration', () {
    final config = DashronymConfig.withMarkers(acceptMarkers: const ['[]']);

    expect(
      () => config.acceptMarkers.add('{}'),
      throwsUnsupportedError,
    );
  });

  test('custom-marker constructor defensively copies runtime markers', () {
    final markers = ['[]'];
    final config = DashronymConfig.withMarkers(acceptMarkers: markers);
    final originalHashCode = config.hashCode;

    markers.add('{}');

    expect(config.acceptMarkers, ['[]']);
    expect(config.hashCode, originalHashCode);
  });

  test('validate rejects invalid lengths in every build mode', () {
    const invalidMinimum = DashronymConfig(minLen: 0);
    const invertedBounds = DashronymConfig(minLen: 4, maxLen: 3);

    expect(invalidMinimum.validate, throwsArgumentError);
    expect(invertedBounds.validate, throwsArgumentError);
  });

  test('custom-marker constructor rejects invalid marker pairs', () {
    expect(
      () => DashronymConfig.withMarkers(acceptMarkers: const ['(']),
      throwsArgumentError,
    );
    expect(
      () => DashronymConfig.withMarkers(acceptMarkers: const ['[{}]']),
      throwsArgumentError,
    );
  });

  test('accepts at most maxAcceptedMarkerPairs', () {
    List<String> markers(int count) => List.generate(
      count,
      (index) => String.fromCharCodes([0xE000 + index, 0xE100 + index]),
    );

    final maximum = DashronymConfig.withMarkers(
      acceptMarkers: markers(DashronymConfig.maxAcceptedMarkerPairs),
    );

    expect(
      maximum.acceptMarkers,
      hasLength(DashronymConfig.maxAcceptedMarkerPairs),
    );
    expect(
      () => DashronymConfig.withMarkers(
        acceptMarkers: markers(DashronymConfig.maxAcceptedMarkerPairs + 1),
      ),
      throwsArgumentError,
    );
  });

  test('copyWith returns an independently validated configuration', () {
    const original = DashronymConfig(enableBareAcronyms: false);
    final markers = ['[]'];

    final copy = original.copyWith(maxLen: 12, acceptMarkers: markers);
    markers.add('{}');

    expect(copy.enableBareAcronyms, isFalse);
    expect(copy.maxLen, 12);
    expect(copy.acceptMarkers, ['[]']);
  });

  test('uses value equality for matching behavior', () {
    final first = DashronymConfig.withMarkers(
      enableBareAcronyms: false,
      minLen: 3,
      maxLen: 8,
      acceptMarkers: const ['[]', '{}'],
    );
    final equivalent = DashronymConfig.withMarkers(
      enableBareAcronyms: false,
      minLen: 3,
      maxLen: 8,
      acceptMarkers: const ['[]', '{}'],
    );

    expect(first, equivalent);
    expect(first.hashCode, equivalent.hashCode);
    expect({first, equivalent}, hasLength(1));
  });

  test('equality includes marker order and every matching option', () {
    final config = DashronymConfig.withMarkers(
      enableBareAcronyms: false,
      minLen: 3,
      maxLen: 8,
      acceptMarkers: const ['[]', '{}'],
    );

    expect(
      config,
      isNot(
        DashronymConfig.withMarkers(
          enableBareAcronyms: true,
          minLen: 3,
          maxLen: 8,
          acceptMarkers: const ['[]', '{}'],
        ),
      ),
    );
    expect(
      config,
      isNot(
        DashronymConfig.withMarkers(
          enableBareAcronyms: false,
          minLen: 2,
          maxLen: 8,
          acceptMarkers: const ['[]', '{}'],
        ),
      ),
    );
    expect(
      config,
      isNot(
        DashronymConfig.withMarkers(
          enableBareAcronyms: false,
          minLen: 3,
          maxLen: 9,
          acceptMarkers: const ['[]', '{}'],
        ),
      ),
    );
    expect(
      config,
      isNot(
        DashronymConfig.withMarkers(
          enableBareAcronyms: false,
          minLen: 3,
          maxLen: 8,
          acceptMarkers: const ['{}', '[]'],
        ),
      ),
    );
  });
}
