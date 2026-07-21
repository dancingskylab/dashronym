import 'package:dashronym/dashronym.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DashronymConfig exposes sensible defaults', () {
    const config = DashronymConfig();
    expect(config.enableBareAcronyms, isFalse);
    expect(config.minLen, 2);
    expect(config.maxLen, 10);
    expect(config.acceptMarkers, ['()', "''", '""']);
  });

  test('DashronymConfig respects custom markers and lengths', () {
    const markers = ['[]', '{}'];
    const config = DashronymConfig(
      enableBareAcronyms: true,
      minLen: 3,
      maxLen: 6,
      acceptMarkers: markers,
    );

    expect(config.enableBareAcronyms, isTrue);
    expect(config.minLen, 3);
    expect(config.maxLen, 6);
    expect(config.acceptMarkers, markers);
  });

  test('acceptMarkers cannot be mutated through the configuration', () {
    const config = DashronymConfig(acceptMarkers: ['[]']);

    expect(
      () => config.acceptMarkers.add('{}'),
      throwsUnsupportedError,
    );
  });

  test('immutable constructor defensively copies runtime markers', () {
    final markers = ['[]'];
    final config = DashronymConfig.immutable(acceptMarkers: markers);

    markers.add('{}');

    expect(config.acceptMarkers, ['[]']);
  });

  test('validate rejects invalid lengths in every build mode', () {
    const invalidMinimum = DashronymConfig(minLen: 0);
    const invertedBounds = DashronymConfig(minLen: 4, maxLen: 3);

    expect(invalidMinimum.validate, throwsArgumentError);
    expect(invertedBounds.validate, throwsArgumentError);
  });

  test('validate rejects marker pairs that are not two Unicode scalars', () {
    const tooShort = DashronymConfig(acceptMarkers: ['(']);
    const tooLong = DashronymConfig(acceptMarkers: ['[{}]']);

    expect(tooShort.validate, throwsArgumentError);
    expect(tooLong.validate, throwsArgumentError);
  });

  test('copyWith returns an independently validated configuration', () {
    const original = DashronymConfig(enableBareAcronyms: true);
    final markers = ['[]'];

    final copy = original.copyWith(maxLen: 12, acceptMarkers: markers);
    markers.add('{}');

    expect(copy.enableBareAcronyms, isTrue);
    expect(copy.maxLen, 12);
    expect(copy.acceptMarkers, ['[]']);
  });
}
