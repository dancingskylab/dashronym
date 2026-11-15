# dashronym

[![CI](https://github.com/dancingskylab/dashronym/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/dancingskylab/dashronym/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/dashronym.svg)](https://pub.dev/packages/dashronym)
[![coverage gate](https://img.shields.io/badge/coverage-%E2%89%A595%25%20lines%20%7C%20%E2%89%A585%25%20branches-brightgreen)](https://github.com/dancingskylab/dashronym/actions/workflows/ci.yml)
[![license](https://img.shields.io/github/license/dancingskylab/dashronym)](LICENSE)

Dashronym turns acronyms in Flutter text into accessible inline definition
tooltips. Give it a map of terms and descriptions, then use it with an existing
`Text` or with `DashronymText`.

## Requirements

Dashronym `0.2.x` requires:

- Dart `>=3.10.0 <4.0.0`
- Flutter `>=3.38.1`

On iOS, Flutter 3.41.0 through 3.44.9 and 3.47.0 through 3.47.6 report the
position of overlay content incorrectly to VoiceOver, so VoiceOver focus can
miss an open definition. If VoiceOver support matters, use Flutter 3.38.x,
3.47.7 or later, or 3.50 or later.

## Installation

```yaml
dependencies:
  dashronym: ^0.2.0
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

## Theme

Pass a `DashronymTheme` to one widget or a `DashronymScope`, or provide it to
the whole app with `DashronymThemeScope`:

```dart
MaterialApp(
  builder: (context, child) => DashronymThemeScope(
    data: const DashronymTheme(
      acronymStyle: TextStyle(color: Colors.indigo),
      cardElevation: 10,
      tooltipMaxWidth: 360,
    ),
    child: child!,
  ),
  home: DashronymScope(
    registry: acronyms,
    child: const Article(),
  ),
)
```

Placing the scope in the app's `builder` applies it to every route.
Dashronym resolves the theme in this order:

1. A theme passed to `DashronymText` or `Text.dashronyms()`.
2. `DashronymScope.theme`.
3. The nearest `DashronymThemeScope`.
4. A `DashronymTheme` installed in `ThemeData.extensions`.
5. The package defaults.

Prefer `DashronymThemeScope` to `ThemeData.extensions`. Flutter's standalone
`material_ui` package uses different theme types from
`package:flutter/material.dart`, so a theme extension registered with one is
invisible to the other. Dashronym 0.3.0 stops reading `ThemeData.extensions`.

In 0.2.x the stock card still takes its surface color, and any icon color or
text styles the theme leaves unset, from the `package:flutter/material.dart`
theme. Apps on the standalone `material_ui` package can set `cardIconColor`,
`cardTitleStyle` and `cardSubtitleStyle` explicitly, or use a custom
`tooltipBuilder`.

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

Dashronym still handles overlay positioning, viewport constraints, focus, and
dismissal. Your builder just owns the content.

## Accessibility and interaction

Matched terms are keyboard-focusable controls.

- Tap, click, Enter, or Space opens or toggles a definition.
- Escape, an outside tap, scrolling, or a viewport change dismisses it.
- Focus can move into custom tooltip controls and returns to the trigger
  after closing.
- At most one tooltip is open per `DashronymScope`; independent scopes don't
  interfere with each other.
- Tooltip surfaces stay within the visible viewport.
- Definition state and content are exposed to assistive technologies.

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

- [Example application](example/main.dart)
- [Migration guide](MIGRATION.md)
- [Contributing guide](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

Dashronym is available under the [BSD 3-Clause License](LICENSE).
