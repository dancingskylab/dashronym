# dashronym

[![CI](https://github.com/dancingskylab/dashronym/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/dancingskylab/dashronym/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/dashronym.svg)](https://pub.dev/packages/dashronym)
[![coverage gate](https://img.shields.io/badge/coverage-%E2%89%A595%25%20lines%20%7C%20%E2%89%A585%25%20branches-brightgreen)](https://github.com/dancingskylab/dashronym/actions/workflows/ci.yml)
[![license](https://img.shields.io/github/license/dancingskylab/dashronym)](LICENSE)

Dashronym turns acronyms in Flutter text into accessible inline definition
tooltips. Give it a map of terms and descriptions, then use it with an existing
`Text` or with `DashronymText`. It works in any Flutter app, whatever its design
system.

## Requirements

Dashronym `0.3.x` requires:

- Dart `^3.14.0`
- Flutter `>=3.50.0`

Apps on older Flutter releases can keep using Dashronym `0.2.x`, which supports
Flutter 3.38.1 and later. See the [migration guide](MIGRATION.md) to move from
0.2.x.

## Installation

```yaml
dependencies:
  dashronym: ^0.3.0
```

Then run `flutter pub get` and import the package:

```dart
import 'package:dashronym/dashronym.dart';
```

## Quick start

```dart
final acronyms = DashronymRegistry({
  'API': 'Application Programming Interface',
  'SDK': 'Software Development Kit',
});

class Overview extends StatelessWidget {
  const Overview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'The SDK provides an API for your application.',
    ).dashronyms(registry: acronyms);
  }
}
```

Registered uppercase acronyms containing 2–10 ASCII letters match in ordinary
text by default. Only terms in the registry become interactive. Change the
length bounds with `DashronymConfig` when needed.

`DashronymText` provides the same behavior directly:

```dart
DashronymText(
  'The SDK provides an API for your application.',
  registry: acronyms,
)
```

## Share a registry

Use `DashronymScope` when several widgets use the same definitions:

```dart
DashronymScope(
  registry: acronyms,
  child: const Article(),
)
```

Widgets below the scope can omit the registry:

```dart
const Text('Install the SDK first.').dashronyms()

const DashronymText('Then call the API.')
```

Explicit widget arguments override values inherited from the nearest scope.
At most one tooltip is open within a `DashronymScope`; independent scopes
coordinate their tooltips separately and do not interfere with each other.

## Matching

Bare uppercase acronyms are enabled by default. Marker-wrapped terms such as
`(API)`, `'API'`, and `"API"` are also supported.

To require markers, disable bare matching:

```dart
DashronymScope(
  registry: acronyms,
  config: const DashronymConfig(enableBareAcronyms: false),
  child: const Article(),
)
```

`DashronymConfig` also controls the accepted marker pairs and minimum and
maximum term lengths. Use its copying factory for custom markers:

```dart
final config = DashronymConfig.withMarkers(
  acceptMarkers: const ['()', '«»'],
);
```

## Rich text

The extension also works with `Text.rich` and keeps the surrounding span
styles:

```dart
Text.rich(
  TextSpan(
    children: [
      const TextSpan(text: 'Use the '),
      TextSpan(
        text: 'SDK',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const TextSpan(text: ' to call the API.'),
    ],
  ),
).dashronyms(registry: acronyms)
```

Existing `WidgetSpan`s are preserved. A `TextSpan` with its own
`semanticsLabel` remains an author-controlled accessibility boundary.

`DashronymText` takes the same layout arguments as `Text`, including `hyphens`,
and applies the text-spacing overrides that platforms such as the web publish
for accessibility. Acronyms keep their order in right-to-left and
mixed-direction text.

## Works with any design system

Dashronym uses only Flutter's widgets library, so it works the same in a
`MaterialApp` (from `package:flutter/material.dart` or the standalone
`material_ui` package), a `CupertinoApp`, a `WidgetsApp`, or an app with its own
design system. It adds no design-system package to your dependencies.

Out of the box, the definition card takes its look from the app around it:

- The surface is light or dark to contrast with the surrounding text color,
  falling back to the platform brightness.
- Text uses the ambient `DefaultTextStyle` when it's readable on the surface.
- Icons use the ambient `IconTheme` color when it contrasts with the surface.
- The info and close icons are painted, so no icon font is needed.

To match a design system exactly, map its theme to a `DashronymTheme` once, as
shown in [Theme](#theme).

## Theme

Pass a `DashronymTheme` to one widget or a `DashronymScope`, or provide it to
the whole app with `DashronymThemeScope`. Placing the scope in the app's
`builder` applies it to every route:

```dart
// In MaterialApp, CupertinoApp or WidgetsApp:
builder: (context, child) => DashronymThemeScope(
  data: const DashronymTheme(
    acronymStyle: TextStyle(color: Color(0xFF3F51B5)),
    tooltipMaxWidth: 360,
  ),
  child: child!,
),
```

Dashronym resolves the theme in this order:

1. A theme passed to `DashronymText` or `Text.dashronyms()`.
2. The nearest `DashronymScope.theme` or `DashronymThemeScope`, whichever is
   closer.
3. The package defaults.

Colors the theme leaves unset come from the host app, as described in
[Works with any design system](#works-with-any-design-system). Set `cardColor`,
`cardShadowColor`, `cardBorderSide`, `cardIconColor` or `acronymFocusColor` to
choose them yourself, and `cardIcon` or `cardCloseIcon` to use your own icons.

### Material

This recipe from the [example app](example/lib/material_theme.dart) gives the
card the colors, type and icons of a Material theme, as Dashronym 0.2 did:

```dart
/// Maps a Material [ThemeData] onto a [DashronymTheme].
///
/// Dashronym does not depend on Material. Install the result with a
/// [DashronymThemeScope] in `MaterialApp.builder` to give the tooltip card
/// Material colors, type and icons. The builder runs below `AnimatedTheme`, so
/// the card follows light, dark and animated theme changes.
DashronymTheme dashronymThemeFromMaterial(ThemeData theme) {
  final colors = theme.colorScheme;
  return DashronymTheme(
    acronymStyle: TextStyle(color: colors.primary),
    acronymFocusColor: theme.focusColor,
    cardColor: colors.surface,
    cardShadowColor: colors.shadow,
    cardIconColor: colors.primary,
    cardTitleStyle: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
    ),
    cardSubtitleStyle: theme.textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    ),
    cardIcon: Icons.info_outline,
    cardCloseIcon: Icons.close,
  );
}
```

Install it in `MaterialApp.builder`:

```dart
MaterialApp(
  theme: ThemeData(colorSchemeSeed: Colors.indigo),
  darkTheme: ThemeData(
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.dark,
  ),
  builder: (context, child) => DashronymThemeScope(
    data: dashronymThemeFromMaterial(Theme.of(context)),
    child: child!,
  ),
  home: const Article(),
)
```

### Cupertino

The [Cupertino recipe](example/lib/cupertino_theme.dart) uses system colors and
Cupertino icons:

```dart
/// Maps the ambient Cupertino theme onto a [DashronymTheme].
///
/// Install the result with a [DashronymThemeScope] in `CupertinoApp.builder`
/// to give the tooltip card system colors, type and SF Symbols-style icons.
DashronymTheme dashronymThemeFromCupertino(BuildContext context) {
  final theme = CupertinoTheme.of(context);
  final body = theme.textTheme.textStyle;
  return DashronymTheme(
    acronymStyle: TextStyle(color: theme.primaryColor),
    cardColor: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    ),
    cardIconColor: theme.primaryColor,
    cardTitleStyle: body.copyWith(fontWeight: FontWeight.w600),
    cardSubtitleStyle: body.copyWith(
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    ),
    cardIcon: CupertinoIcons.info,
    cardCloseIcon: CupertinoIcons.xmark,
  );
}
```

```dart
CupertinoApp(
  builder: (context, child) => DashronymThemeScope(
    data: dashronymThemeFromCupertino(context),
    child: child!,
  ),
  home: const Article(),
)
```

## Custom tooltip content

Use `tooltipBuilder` when the definition needs an application-owned surface:

```dart
DashronymText(
  'Review the API.',
  registry: acronyms,
  tooltipBuilder: (context, details) {
    return Card(
      child: ListTile(
        title: Text(details.acronym),
        subtitle: Text(details.description),
        trailing: IconButton(
          tooltip: 'Close definition',
          onPressed: details.hideTooltip,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  },
)
```

The builder can use widgets from any design system. Dashronym still handles
overlay positioning, viewport constraints, focus, and dismissal. Your builder
just owns the content.

## Accessibility and interaction

Matched terms are keyboard-focusable disclosure buttons.

- Tap, click, Enter, or Space opens or toggles a definition, including Enter on
  the web.
- Tab moves from an acronym into its open card, then on to the next control.
- Escape closes the open card and returns focus to the acronym, without also
  closing an enclosing dialog.
- An outside tap, scrolling, or resizing the window dismisses the card.
- At most one tooltip is open per `DashronymScope`; independent scopes don't
  interfere with each other.
- Cards stay within the visible viewport, clear of the keyboard and system
  bars.
- Screen readers meet each acronym once, as a button with an expanded state,
  expand and collapse actions, and a hint. The open card is read right after
  the acronym.
- With Reduce Motion on, cards fade in without scaling. With high contrast on,
  cards get an outline and focus indicators get stronger.

Custom builders should keep their controls keyboard-reachable, label them
clearly, and call `details.hideTooltip` to close. Test with real assistive
tech, not just automated checks.

## Localization

Dashronym includes English strings and safely falls back to English when its
delegate is not installed. Apps that configure Flutter localization can add:

```dart
localizationsDelegates: const [
  DashronymLocalizations.delegate,
  // Keep your app's existing Flutter and application delegates here.
],
```

Keep the app's existing `supportedLocales`; Dashronym's English strings fall
back safely for other locales.

## Resources

- [Example application](example/lib/main.dart), with Material, Cupertino and
  widgets-only hosts
- [Agent skill](skills/dashronym-usage/SKILL.md) that teaches AI coding
  assistants to use Dashronym, for example with
  `npx skills add dancingskylab/dashronym --skill dashronym-usage`
- [Migration guide](MIGRATION.md)
- [Contributing guide](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

Dashronym is available under the [BSD 3-Clause License](LICENSE).
