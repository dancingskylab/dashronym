import 'package:dashronym/dashronym.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashronymScope exposes shared defaults', (tester) async {
    final registry = AcronymRegistry({
      'API': 'Application Programming Interface',
    });
    const config = DashronymConfig(enableBareAcronyms: true);
    const theme = DashronymTheme(cardWidth: 240);
    DashronymScope? resolved;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DashronymScope(
          registry: registry,
          config: config,
          theme: theme,
          child: Builder(
            builder: (context) {
              resolved = DashronymScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(resolved?.registry, same(registry));
    expect(resolved?.config, same(config));
    expect(resolved?.theme, same(theme));
  });

  testWidgets('DashronymScope.maybeOf returns null outside a scope', (
    tester,
  ) async {
    DashronymScope? resolved;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            resolved = DashronymScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, isNull);
  });
}
