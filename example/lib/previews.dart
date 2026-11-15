// Flutter Widget Previews of Dashronym in a Material app.
//
// Open them with the Widget Previewer in your IDE, or run
// `flutter widget-preview start` in this directory. They are interactive:
// tap or focus a term to open its definition. The preview API is not stable
// yet, so previews live in this example app rather than in the package.
import 'package:dashronym/dashronym.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import 'material_theme.dart';

final _registry = DashronymRegistry({
  'API': 'Application Programming Interface',
  'SDK': 'Software Development Kit',
});

Widget _host(
  Widget child, {
  required Brightness brightness,
  TextDirection textDirection = TextDirection.ltr,
  bool highContrast = false,
}) {
  final theme = ThemeData(
    colorSchemeSeed: Colors.indigo,
    brightness: brightness,
  );
  return Theme(
    data: theme,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: DashronymScope(
              registry: _registry,
              theme: dashronymThemeFromMaterial(theme),
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Light Material host.
Widget lightHost(Widget child) => _host(child, brightness: Brightness.light);

/// Dark Material host.
Widget darkHost(Widget child) => _host(child, brightness: Brightness.dark);

/// Right-to-left Material host.
Widget rtlHost(Widget child) => _host(
  child,
  brightness: Brightness.light,
  textDirection: TextDirection.rtl,
);

/// High-contrast Material host, which outlines the card.
Widget highContrastHost(Widget child) =>
    _host(child, brightness: Brightness.light, highContrast: true);

/// Light theme.
@Preview(group: 'Dashronym', name: 'Light', wrapper: lightHost)
Widget lightPreview() => const _Paragraph();

/// Dark theme.
@Preview(group: 'Dashronym', name: 'Dark', wrapper: darkHost)
Widget darkPreview() => const _Paragraph();

/// Right-to-left text.
@Preview(group: 'Dashronym', name: 'Right-to-left', wrapper: rtlHost)
Widget rtlPreview() => const _Paragraph('تستخدم أداة SDK واجهة API للمزامنة.');

/// High contrast.
@Preview(group: 'Dashronym', name: 'High contrast', wrapper: highContrastHost)
Widget highContrastPreview() => const _Paragraph();

/// Large text.
@Preview(
  group: 'Dashronym',
  name: 'Large text',
  textScaleFactor: 2,
  wrapper: lightHost,
)
Widget largeTextPreview() => const _Paragraph();

class _Paragraph extends StatelessWidget {
  const _Paragraph([
    this.text = 'The SDK talks directly to the API that powers the app.',
  ]);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DashronymText(text, style: Theme.of(context).textTheme.bodyLarge);
  }
}
