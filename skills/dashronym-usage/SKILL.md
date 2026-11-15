---
name: dashronym-usage
description: Add accessible acronym definitions to Flutter text with the dashronym package, theme them to match Material, Cupertino or a custom design system, write custom tooltip content, and test apps that use them. Use when an app depends on dashronym or asks for inline glossary, abbreviation or acronym tooltips.
---

# Using dashronym

Dashronym turns registered acronyms in Flutter text into keyboard- and
screen-reader-accessible buttons that open a definition card. It depends only
on Flutter's widgets library, so it works in any app.

## Pick the version

- Flutter 3.50 or later: `dashronym: ^0.3.0`.
- Older Flutter: `dashronym: ^0.2.1`. Its theme APIs differ; see the package's
  MIGRATION.md before mixing advice between versions.

Import only `package:dashronym/dashronym.dart`. Never import from `src/`.

## Build the registry once

Create a `DashronymRegistry` from a `Map<String, String>` at the UI boundary,
such as a top-level `final`, a provider or a state object. Don't build it
inside `build`.

```dart
final acronyms = DashronymRegistry({
  'API': 'Application Programming Interface',
  'SDK': 'Software Development Kit',
});
```

## Render text

- Existing text: `Text('Install the SDK.').dashronyms(registry: acronyms)`.
  It also works on `Text.rich(...)` and keeps span styles and `WidgetSpan`s.
- New text: `DashronymText('Install the SDK.', registry: acronyms)`.
- Many widgets: wrap them in `DashronymScope(registry: acronyms, child: ...)`
  and omit `registry` below it. A scope also keeps one card open at a time.

Registered uppercase acronyms of 2 to 10 ASCII letters match as bare words by
default. `(SDK)`, `'SDK'` and `"SDK"` match too. To require markers, pass
`config: const DashronymConfig(enableBareAcronyms: false)`.

## Theme

Install one `DashronymThemeScope` in the app's `builder`, so it covers every
route. Don't put `DashronymTheme` in `ThemeData.extensions`: 0.3.0 doesn't read
it, and it isn't a `ThemeExtension` anymore.

```dart
MaterialApp(
  builder: (context, child) => DashronymThemeScope(
    data: dashronymThemeFromMaterial(Theme.of(context)),
    child: child!,
  ),
  home: const HomePage(),
)
```

- Without a theme, the card picks a light or dark surface that contrasts with
  the surrounding text, and paints its own icons.
- For a Material or Cupertino look, copy `dashronymThemeFromMaterial` or
  `dashronymThemeFromCupertino` from the package README into the app. They are
  recipes, not package APIs.
- The nearest theme wins: a `theme` passed to the widget, then the nearest
  `DashronymScope.theme` or `DashronymThemeScope`, then the defaults.

## Custom tooltip content

Pass `tooltipBuilder: (context, details) => ...` to a widget or scope. The
package still positions the card, keeps it in the viewport, and handles focus
and dismissal. The builder must:

- Show `details.description`, and usually `details.acronym`.
- Give every control a visible label or tooltip, and keep it reachable by
  keyboard.
- Close through `details.hideTooltip`, which returns focus to the acronym.
- Not trap focus or open its own overlays for the definition.

## Test apps that use dashronym

- Open a card: `await tester.tap(find.text('SDK'))`, then `pumpAndSettle`.
- Find the open card: `find.bySemanticsLabel('Definition for SDK')`.
- Find its close button: `find.byTooltip('Hide definition for SDK')`.
- The acronym is one semantics node: a focusable button labeled `SDK` with an
  expanded state, and an expand or collapse action that matches it.
- Keyboard: Tab focuses an acronym and opens its card, the next Tab reaches the
  close button, and Escape closes the card.
