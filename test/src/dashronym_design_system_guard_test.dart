// Dashronym is design-system agnostic: lib/ builds on the widgets layer only,
// so it works the same in Material, Cupertino and custom-design apps.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _designSystemDirective = RegExp(
  r'''^\s*(import|export)\s+['"]package:(flutter/(material|cupertino)\.dart|material_ui/|cupertino_ui/)''',
);

void main() {
  test('lib/ imports no design system', () {
    final offenders = <String>[];
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in sources) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_designSystemDirective.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('the package depends on no design system', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies =
        RegExp(
          r'^dependencies:\n((?:[ \t]+.*\n|\n)*)',
          multiLine: true,
        ).firstMatch(pubspec)?.group(1) ??
        '';

    expect(dependencies, isNot(contains('material_ui')));
    expect(dependencies, isNot(contains('cupertino_ui')));
  });
}
