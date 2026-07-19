# dashronym

Dashronym turns known acronyms inside Flutter text into accessible inline
controls with viewport-safe definition tooltips. It supports simple maps,
rich glossary entries and aliases, shared app-level configuration, existing
rich-text trees, and a versioned JSON interchange format.

The package is local-first: rendering a glossary does not require an account,
network connection, telemetry, or a hosted Dashronym service.

## Highlights

- Add glossary behavior to a `Text` with `.dashronyms()` or use
  `DashronymText` directly.
- Share a registry, parser configuration, theme, and tooltip builder through
  `DashronymScope`.
- Install `DashronymTheme` as a Flutter `ThemeExtension`.
- Keep nested `TextSpan` styling, locale metadata, existing `WidgetSpan`s,
  layout options, selection, directionality, text scaling, and recognizers on
  unmatched text; matched terms intentionally become glossary controls.
- Use immutable `AcronymEntry` values with expansions, longer definitions,
  aliases, tags, sources, and JSON-safe metadata.
- Import and export deterministic, versioned `DashronymGlossary` JSON.
- Resolve alias collisions with explicit reject, keep-first, or keep-last
  policies.
- Support touch, mouse, keyboard, screen readers, RTL layouts, compact
  viewports, visible keyboards, and long definitions.
- Replace the tooltip surface while retaining Dashronym's overlay, focus,
  dismissal, and viewport constraints.

## Requirements

Dashronym `0.1.0` requires:

- Dart `>=3.10.0 <4.0.0`
- Flutter `>=3.38.1`

CI validates the exact minimum and the latest supported stable Flutter release.
See the [migration guide](MIGRATION.md) before upgrading from `0.0.x`.

## Installation

Add Dashronym to your Flutter application:

```yaml
dependencies:
  dashronym: ^0.1.0
```

Then run:

```sh
flutter pub get
```

## Quick start

For one text widget, pass a registry directly:

```dart
import 'package:dashronym/dashronym.dart';
import 'package:flutter/material.dart';

final registry = AcronymRegistry({
  'SDK': 'Software Development Kit',
  'API': 'Application Programming Interface',
});

class Overview extends StatelessWidget {
  const Overview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Our SDK exposes a lightweight API.',
    ).dashronyms(
      registry: registry,
      config: const DashronymConfig(enableBareAcronyms: true),
    );
  }
}
```

Marker-wrapped terms work without enabling bare matching:

```dart
DashronymText(
  'Install the (SDK) before using the (API).',
  registry: registry,
)
```

Only terms present in the registry become interactive.

## Share one glossary across a subtree

Use `DashronymScope` when a feature or application uses the same glossary in
several places:

```dart
DashronymScope(
  registry: registry,
  config: const DashronymConfig(enableBareAcronyms: true),
  child: const Article(),
)
```

Descendants can omit the shared values:

```dart
const Text('The SDK calls the API.').dashronyms()

const DashronymText('The API is also available from the CLI.')
```

Resolution precedence is:

1. an explicit widget or extension argument;
2. the nearest `DashronymScope`;
3. a `DashronymTheme` in `ThemeData.extensions` for visual configuration; and
4. package defaults.

Omitting a registry without a surrounding scope produces a focused
`FlutterError` explaining both valid setup options.

## Rich entries, aliases, and portable JSON

Use `AcronymEntry` when a definition needs more structure than a single
description string:

```dart
final glossary = DashronymGlossary(
  name: 'Software basics',
  id: 'com.example.software-basics',
  version: '2026.07.1',
  locale: 'en-CA',
  license: 'LicenseRef-Example',
  entries: [
    AcronymEntry(
      acronym: 'API',
      expansion: 'Application Programming Interface',
      definition: 'A defined interface used by software components.',
      aliases: const ['APIS'],
      tags: const ['software', 'integration'],
      source: 'https://example.com/editorial-method',
      metadata: const {
        'entryId': 'software.api',
        'status': 'reviewed',
      },
    ),
  ],
);

final registry = glossary.toRegistry();

registry.descriptionOf('apis');
// Application Programming Interface — A defined interface used by
// software components.

registry.entryOf('APIS')?.source;
// https://example.com/editorial-method
```

Decode or encode the same model at an application boundary:

```dart
final glossary = DashronymGlossary.fromJsonString(encodedJson);
final prettyJson = glossary.toJsonString(pretty: true);
```

The decoder is intentionally strict. Unknown fields, unsupported schema
versions, malformed timestamps, invalid metadata, and duplicate aliases fail
with descriptive errors. Put application-specific JSON values in `metadata`.
When the document is converted with `toRegistry()`, its default duplicate
policy also rejects normalized canonical/alias collisions across entries.

The authoritative version-1 contract is
[`schema/v1/dashronym-glossary.schema.json`](schema/v1/dashronym-glossary.schema.json).

### Core entry point

Flutter-SDK projects can import the model and registry layer without importing
Flutter APIs:

```dart
import 'package:dashronym/dashronym_core.dart';
```

That library's import graph is pure Dart, but the current `dashronym` package
still declares an SDK dependency on Flutter. A Dart-only project that does not
install Flutter cannot consume this package yet. Publishing a separately
versioned core package is tracked in the
[roadmap](https://github.com/dancingskylab/dashronym/blob/main/docs/ROADMAP.md)
before non-Flutter integrations.

## Matching behavior

`DashronymConfig` has two matching modes:

- Marker matching is enabled by default. The default pairs recognize `(API)`,
  `'API'`, and `"API"`. A registered marker-wrapped term can contain
  punctuation or mixed case, so `(C++)`, `(.NET)`, `(R&D)`, and `(OAuth)` are
  supported within the configured Unicode-scalar length bounds.
- Bare matching is opt-in with `enableBareAcronyms: true` and recognizes known
  all-uppercase terms within `minLen` and `maxLen`.

Registries are case-insensitive by default, so a marker such as `(api)` can
resolve an `API` entry. Pass `caseInsensitive: false` when case is meaningful.

Rich registries reject normalized canonical or alias collisions by default:

```dart
final registry = AcronymRegistry.fromAcronymEntries(
  glossary.entries,
  duplicatePolicy: AcronymDuplicatePolicy.reject,
);
```

Use `keepFirst` or `keepLast` only when the import workflow has an intentional,
documented precedence rule.

Punctuation-aware *bare* terms, escaping, and broader Unicode-aware unmarked
matching policies are planned explicitly rather than being silently folded
into legacy bare matching. See the
[roadmap](https://github.com/dancingskylab/dashronym/blob/main/docs/ROADMAP.md).

## Existing rich text

`Text.rich(...).dashronyms()` recursively processes text inside nested
`TextSpan`s:

```dart
Text.rich(
  TextSpan(
    children: [
      const TextSpan(text: 'Use the '),
      TextSpan(
        text: 'SDK',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const TextSpan(text: ' from your IDE.'),
    ],
  ),
).dashronyms(
  registry: registry,
  config: const DashronymConfig(enableBareAcronyms: true),
)
```

Existing `WidgetSpan`s are preserved. A `TextSpan` with an explicit
`semanticsLabel` is treated as an author-controlled accessibility boundary and
is left unchanged. Use `DashronymText.rich` when constructing the
glossary-aware tree directly.

## Theming

Pass a theme locally:

```dart
DashronymText(
  'Tap (API) for its definition.',
  registry: registry,
  theme: DashronymTheme(
    decorationStyle: TextDecorationStyle.dashed,
    cardWidth: 360,
    tooltipMaxWidth: 420,
    hoverShowDelay: Duration(milliseconds: 120),
  ),
)
```

Or install an app-level theme extension:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      DashronymTheme(
        acronymStyle: TextStyle(color: Colors.indigo),
        cardElevation: 10,
      ),
    ],
  ),
  home: const HomePage(),
)
```

`DashronymTheme.copyWith` uses `clear…` flags for nullable settings (for
example, `clearTooltipMaxWidth: true`), and `lerp` participates in animated
Flutter theme transitions.

## Custom tooltip content

`tooltipBuilder` receives the visible term, display description, effective
theme, close callback, and the rich entry when one exists:

```dart
DashronymText(
  'Review the (API).',
  registry: registry,
  tooltipBuilder: (context, details) {
    final entry = details.entry;

    return Material(
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        title: Text(entry?.expansion ?? details.acronym),
        subtitle: Text(entry?.definition ?? details.description),
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

Dashronym constrains custom surfaces to the usable viewport and makes oversized
content scrollable. The builder still owns the content's labels, reading order,
and control semantics.

## Accessibility and interaction contract

Inline terms expose a button role, expanded/collapsed state, and a dynamic
show/hide hint.

- Tap, click, Enter, or Space opens or toggles a definition.
- Keyboard focus opens a definition; Escape dismisses it.
- Focus can move into tooltip controls and is restored to the trigger after a
  close action.
- Hover can move from the trigger into the tooltip without closing it.
- Outside activation, scrolling, resizing, or orientation changes dismiss a
  stale surface.
- At most one Dashronym tooltip is active at a time.
- Supported platforms receive the complete definition through one
  capability-appropriate announcement path, so opening a tooltip does not
  produce duplicate or content-free announcements.
- The trigger keeps the surrounding text scale, locale, direction, baseline,
  style, and selection behavior. Tooltip text retains the effective scale
  without applying it twice to inline widgets.
- Stock and custom surfaces share safe-area, keyboard-inset, width, and height
  constraints. Long stock definitions remain scrollable.

Automated tests cover these behaviors, but assistive-technology checks on each
target platform remain part of the release process. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the manual matrix.

## Localization

Dashronym includes English strings and falls back safely when its delegate is
not installed. Applications that configure Flutter localization can add:

```dart
localizationsDelegates: const [
  DashronymLocalizations.delegate,
  // GlobalMaterialLocalizations.delegate,
  // GlobalWidgetsLocalizations.delegate,
  // GlobalCupertinoLocalizations.delegate,
],
supportedLocales: DashronymLocalizations.supportedLocales,
```

## Project resources

- [Migration guide](MIGRATION.md)
- [Roadmap](https://github.com/dancingskylab/dashronym/blob/main/docs/ROADMAP.md)
- [Contributing guide](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Release process](RELEASING.md)
- [Example application](example/main.dart)

Issues and feature proposals belong in the
[GitHub tracker](https://github.com/dancingskylab/dashronym/issues).

When a visual change is intentional, inspect and regenerate the inline goldens
with:

```sh
flutter test --update-goldens test/src/acronym_inline_golden_test.dart
```

Dashronym is available under the [BSD 3-Clause License](LICENSE).
