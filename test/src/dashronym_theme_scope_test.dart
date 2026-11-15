import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_inline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _registry = DashronymRegistry({'SDK': 'Software Development Kit'});

const _themeScopeTheme = DashronymTheme(cardWidth: 220);
const _scopeTheme = DashronymTheme(cardWidth: 230);
const _explicitTheme = DashronymTheme(cardWidth: 240);

/// Pumps [child] inside a widgets-only app.
Future<void> _pumpInApp(WidgetTester tester, Widget child) {
  return tester.pumpWidget(TestWidgetsApp(home: Center(child: child)));
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
    testWidgets('uses the package defaults without any theme', (tester) async {
      await _pumpInApp(tester, DashronymText('SDK', registry: _registry));
      expect(_resolvedTheme(tester), const DashronymTheme());
    });

    testWidgets('uses the nearest theme scope', (tester) async {
      await _pumpInApp(
        tester,
        DashronymThemeScope(
          data: _scopeTheme,
          child: DashronymThemeScope(
            data: _themeScopeTheme,
            child: DashronymText('SDK', registry: _registry),
          ),
        ),
      );
      expect(_resolvedTheme(tester), _themeScopeTheme);
    });

    testWidgets('DashronymScope.theme beats an outer theme scope', (
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

    testWidgets('a theme scope inside a DashronymScope beats its theme', (
      tester,
    ) async {
      await _pumpInApp(
        tester,
        DashronymScope(
          registry: _registry,
          theme: _scopeTheme,
          child: const DashronymThemeScope(
            data: _themeScopeTheme,
            child: DashronymText('SDK'),
          ),
        ),
      );
      expect(_resolvedTheme(tester), _themeScopeTheme);
    });

    testWidgets('a nested DashronymScope without a theme inherits one', (
      tester,
    ) async {
      await _pumpInApp(
        tester,
        DashronymScope(
          registry: _registry,
          theme: _scopeTheme,
          child: DashronymScope(
            registry: DashronymRegistry({'API': 'Application interface'}),
            child: const DashronymText('API'),
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

    testWidgets('toggling DashronymScope.theme keeps descendant state', (
      tester,
    ) async {
      final probeKey = GlobalKey<_StateProbeState>();
      Widget build(DashronymTheme? theme) => DashronymScope(
        registry: _registry,
        theme: theme,
        child: Column(
          children: [
            _StateProbe(key: probeKey),
            const DashronymText('SDK'),
          ],
        ),
      );

      await _pumpInApp(tester, build(null));
      final state = probeKey.currentState;
      expect(_resolvedTheme(tester), const DashronymTheme());

      await _pumpInApp(tester, build(_scopeTheme));
      expect(_resolvedTheme(tester), _scopeTheme);
      expect(probeKey.currentState, same(state));

      await _pumpInApp(tester, build(null));
      expect(_resolvedTheme(tester), const DashronymTheme());
      expect(probeKey.currentState, same(state));
    });
  });

  testWidgets('InheritedTheme.capture carries the theme to other subtrees', (
    tester,
  ) async {
    const theme = DashronymTheme(cardWidth: 280);
    late CapturedThemes themes;
    await _pumpInApp(
      tester,
      DashronymThemeScope(
        data: theme,
        child: Builder(
          builder: (context) {
            themes = InheritedTheme.capture(from: context, to: null);
            return const SizedBox();
          },
        ),
      ),
    );

    // Like an overlay or a new route, outside the scope.
    DashronymTheme? seen;
    await _pumpInApp(
      tester,
      themes.wrap(
        Builder(
          builder: (context) {
            seen = DashronymThemeScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, theme);
  });
}

class _StateProbe extends StatefulWidget {
  const _StateProbe({super.key});

  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
