// Every Widget Preview builds and opens a definition.
import 'package:dashronym_example/previews.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  final previews = <String, Widget Function()>{
    'light': () => lightHost(lightPreview()),
    'dark': () => darkHost(darkPreview()),
    'right-to-left': () => rtlHost(rtlPreview()),
    'high contrast': () => highContrastHost(highContrastPreview()),
    'large text': () => lightHost(largeTextPreview()),
  };

  previews.forEach((name, build) {
    testWidgets('the $name preview builds and opens a definition', (
      tester,
    ) async {
      await tester.pumpWidget(TestWidgetsApp(home: build()));
      await tester.tap(find.textContaining('SDK').first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(openCard, findsOneWidget);
    });
  });
}
