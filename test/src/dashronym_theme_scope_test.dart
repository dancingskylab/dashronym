import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});

const _extensionTheme = DashronymTheme(cardWidth: 210);
const _themeScopeTheme = DashronymTheme(cardWidth: 220);
const _scopeTheme = DashronymTheme(cardWidth: 230);
const _explicitTheme = DashronymTheme(cardWidth: 240);

/// Pumps [child] inside an app whose ThemeData carries [_extensionTheme].
Future<void> _pumpInApp(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [_extensionTheme]),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

DashronymTheme _resolvedTheme(WidgetTester tester) {
  return tester.widget<DashronymInline>(find.byType(DashronymInline)).theme;
}

void main() {
  testWidgets('maybeOf is null and of falls back without a scope', (
    tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    );

    expect(DashronymThemeScope.maybeOf(captured), isNull);
    expect(DashronymThemeScope.of(captured), const DashronymTheme());
  });

  testWidgets('of and maybeOf return the nearest scope', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      DashronymThemeScope(
        data: _themeScopeTheme,
        child: DashronymThemeScope(
          data: _scopeTheme,
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(DashronymThemeScope.maybeOf(captured), _scopeTheme);
    expect(DashronymThemeScope.of(captured), _scopeTheme);
  });

  test('updateShouldNotify compares theme values', () {
    const scope = DashronymThemeScope(
      data: DashronymTheme(cardWidth: 200),
      child: SizedBox(),
    );

    expect(
      const DashronymThemeScope(
        data: DashronymTheme(cardWidth: 200),
        child: SizedBox(),
      ).updateShouldNotify(scope),
      isFalse,
    );
    expect(
      const DashronymThemeScope(
        data: DashronymTheme(cardWidth: 300),
        child: SizedBox(),
      ).updateShouldNotify(scope),
      isTrue,
    );
  });

  testWidgets('captured themes carry the scope into another subtree', (
    tester,
  ) async {
    late BuildContext source;
    await tester.pumpWidget(
      DashronymThemeScope(
        data: _themeScopeTheme,
        child: Builder(
          builder: (context) {
            source = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final themes = InheritedTheme.capture(from: source, to: null);

    DashronymTheme? carried;
    await tester.pumpWidget(
      themes.wrap(
        Builder(
          builder: (context) {
            carried = DashronymThemeScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(carried, _themeScopeTheme);
  });

  group('DashronymText theme resolution', () {
    testWidgets('uses the ThemeData extension without a theme scope', (
      tester,
    ) async {
      await _pumpInApp(tester, DashronymText('SDK', registry: _registry));
      expect(_resolvedTheme(tester), _extensionTheme);
    });

    testWidgets('prefers the theme scope over the ThemeData extension', (
      tester,
    ) async {
      await _pumpInApp(
        tester,
        DashronymThemeScope(
          data: _themeScopeTheme,
          child: DashronymText('SDK', registry: _registry),
        ),
      );
      expect(_resolvedTheme(tester), _themeScopeTheme);
    });

    testWidgets('prefers DashronymScope.theme over the theme scope', (
      tester,
    ) async {
      await _pumpInApp(
        tester,
        DashronymThemeScope(
          data: _themeScopeTheme,
          child: DashronymScope(
            registry: _registry,
            theme: _scopeTheme,
            child: const DashronymText('SDK'),
          ),
        ),
      );
      expect(_resolvedTheme(tester), _scopeTheme);
    });

    testWidgets('prefers an explicit theme over every inherited source', (
      tester,
    ) async {
      await _pumpInApp(
        tester,
        DashronymThemeScope(
          data: _themeScopeTheme,
          child: DashronymScope(
            registry: _registry,
            theme: _scopeTheme,
            child: const DashronymText('SDK', theme: _explicitTheme),
          ),
        ),
      );
      expect(_resolvedTheme(tester), _explicitTheme);
    });

    testWidgets('Text.dashronyms() resolves the theme scope too', (
      tester,
    ) async {
      await _pumpInApp(
        tester,
        DashronymThemeScope(
          data: _themeScopeTheme,
          child: const Text('SDK').dashronyms(registry: _registry),
        ),
      );
      expect(_resolvedTheme(tester), _themeScopeTheme);
    });
  });
}
