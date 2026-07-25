import 'package:dashronym/dashronym.dart';
import 'package:dashronym/src/dashronym_tooltip_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashronymScope exposes shared defaults', (tester) async {
    final registry = DashronymRegistry({
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

  testWidgets('DashronymScope installs a tooltip controller', (tester) async {
    DashronymTooltipController? resolved;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DashronymScope(
          registry: DashronymRegistry(<String, String>{}),
          child: Builder(
            builder: (context) {
              resolved = DashronymTooltipScope.maybeControllerOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(resolved, isNotNull);
  });

  testWidgets('equal replacement values do not notify dependents', (
    tester,
  ) async {
    var dependentBuilds = 0;
    var cardWidth = 240.0;
    late StateSetter rebuild;
    final dependent = Builder(
      builder: (context) {
        DashronymScope.of(context);
        dependentBuilds++;
        return const SizedBox();
      },
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return DashronymScope(
              registry: DashronymRegistry({
                'API': 'Application Programming Interface',
              }),
              config: DashronymConfig(enableBareAcronyms: true),
              theme: DashronymTheme(cardWidth: cardWidth),
              child: dependent,
            );
          },
        ),
      ),
    );

    expect(dependentBuilds, 1);

    rebuild(() {});
    await tester.pump();
    expect(dependentBuilds, 1);

    rebuild(() {
      cardWidth = 241;
    });
    await tester.pump();
    expect(dependentBuilds, 2);
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
