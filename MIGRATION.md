# Migration guide

Dashronym is pre-1.0, so minor releases can contain breaking changes. This
guide covers the changes needed to move between minor releases.

## 0.2.x to 0.3.0

Flutter froze its Material and Cupertino libraries in 3.44, published them as
the standalone `material_ui` and `cupertino_ui` packages in 3.47, and
deprecated `package:flutter/material.dart` in 3.50. The two copies of Material
use different theme types, so a package built on one doesn't see the other's
theme.

Dashronym 0.3.0 depends only on Flutter's widgets library. It works the same
in Material apps (either copy), Cupertino apps, and apps with their own design
system. Most apps need two changes: raise their SDK constraints, and install a
`DashronymThemeScope`, with the Material recipe if they want to keep the 0.2
look. `dart fix` can't make these changes for you.

### Update your SDK constraints

0.3.0 requires Dart 3.14 and Flutter 3.50:

```yaml
environment:
  sdk: ^3.14.0
  flutter: '>=3.50.0'

dependencies:
  dashronym: ^0.3.0
```

Apps that must stay on an older Flutter release can keep `dashronym: ^0.2.1`.

### Move themes out of `ThemeData.extensions`

`DashronymTheme` is no longer a `ThemeExtension`, and Dashronym no longer reads
`ThemeData.extensions`. If you followed the 0.2.1 advice and use
`DashronymThemeScope`, there's nothing to change. Otherwise, the compiler points
you to each theme you need to move:

```dart
// Before
MaterialApp(
  theme: ThemeData(extensions: const [DashronymTheme(cardElevation: 2)]),
  home: const Article(),
);

// After
MaterialApp(
  builder: (context, child) => DashronymThemeScope(
    data: const DashronymTheme(cardElevation: 2),
    child: child!,
  ),
  home: const Article(),
);
```

`DashronymTheme.type` is gone with the base class. `copyWith`, `merge` and
`lerp` keep working.

### Keep the Material look

In 0.2.x the card was built from Material widgets and took its colors, type
and icons from the Material theme. In 0.3.0 the card is built from widgets
primitives and takes unset colors from the app around it: a light or dark
surface that contrasts with the surrounding text, the ambient text style, and
painted icons.

To keep the 0.2 look in a Material app, copy the
[Material recipe](README.md#material) and install it in `MaterialApp.builder`:

```dart
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  builder: (context, child) => DashronymThemeScope(
    data: dashronymThemeFromMaterial(Theme.of(context)),
    child: child!,
  ),
  home: const Article(),
);
```

The recipe works with `package:flutter/material.dart` and with `material_ui`;
only its import differs. Cupertino apps can use the
[Cupertino recipe](README.md#cupertino) the same way. Other apps need no
changes, and can set `cardColor`, `cardIconColor` and the other theme fields to
match their design.

You can also drop `uses-material-design: true` from your pubspec if you only
added it for Dashronym.

### Icons

`cardIcon` and `cardCloseIcon` are now nullable and default to `null`, which
paints built-in glyphs that need no icon font. In 0.2.x they defaulted to
`Icons.info_outline` and `Icons.close`. Pass any `IconData` to use your own;
the Material recipe passes those two. Code that reads these fields must handle
`null`.

### The close button

The stock card's close button no longer uses `IconButton`:

- It shows a hover and press tint and a focus ring instead of an ink ripple.
- Its touch target is 48 by 48 on every platform.
- Escape first closes its "Hide definition" tooltip, if one is showing, then
  the card.

Its tooltip is unchanged, so `find.byTooltip('Hide definition for SDK')` still
finds it. Tests that used `find.byType(IconButton)` or `find.byIcon(Icons.close)`
should switch to that finder.

### Nested scopes

Each `DashronymScope` now provides its theme the way `DashronymThemeScope`
does, and the nearest one wins:

- A `DashronymScope` without a `theme` inherits the theme of an enclosing
  scope. In 0.2.x it fell back to the app-wide theme instead.
- A `DashronymThemeScope` inside a `DashronymScope` overrides the scope's
  theme. In 0.2.x the scope's theme won.

### Widget tests

- Each acronym is now a single semantics node: a button with its label, hint,
  expanded state and focus. In 0.2.x a second focusable node repeated the
  label. An open card shows the acronym as its title, so a label finder can
  match the card too.
- Tab moves from an acronym into its open card's close button before moving
  on, so tests that tabbed from one acronym straight to the next need one more
  Tab.
- The stock card no longer contains `Material`, `Card`, `ListTile` or
  `IconButton` widgets. Find it by its semantics label, such as
  `find.bySemanticsLabel('Definition for SDK')`.

## 0.2.0 to 0.2.1

0.2.1 has no breaking changes. To prepare for 0.3.0, move an app-wide
`DashronymTheme` out of `ThemeData.extensions` and into `DashronymThemeScope`:

```dart
// Before
MaterialApp(
  theme: ThemeData(extensions: const [DashronymTheme(cardElevation: 2)]),
  home: const Article(),
);

// After
MaterialApp(
  builder: (context, child) => DashronymThemeScope(
    data: const DashronymTheme(cardElevation: 2),
    child: child!,
  ),
  home: const Article(),
);
```

`DashronymScope(theme: ...)` and themes passed directly to widgets keep
working unchanged.

## 0.1.x to 0.2.0

Version 0.2.0 narrows Dashronym back to its presentation job: displaying
definitions for registered acronyms in Flutter text.

### Build registries from strings

The supported data shape is a map from each displayed term to its description:

```dart
final registry = DashronymRegistry({
  'API': 'Application Programming Interface',
  'SDK': 'Software Development Kit',
});
```

If definitions come from a database, asset, or API, keep that model in the
application and create the string map at the UI boundary:

```dart
final registry = DashronymRegistry({
  for (final definition in definitions)
    definition.term: definition.description,
});
```

The following 0.1.x data APIs were removed:

- `DashronymEntry` and `DashronymGlossary`;
- `DashronymDuplicatePolicy`;
- `DashronymRegistry.fromEntries`;
- registry `duplicatePolicy` parameters and getter;
- `entryOf`, `richEntries`, `lookupTerms`, and `lookupTermCount`; and
- `DashronymTooltipDetails.entry`.

`DashronymRegistry.fromMapEntries` remains available. Remove
`duplicatePolicy` arguments from string-map construction; normalized duplicate
keys continue to use the later value.

Custom tooltip builders should use `details.acronym` and
`details.description`. Capture application-specific metadata from the
application's own model when it is needed by a custom surface.

### Bare acronyms match by default

In 0.1.x, ordinary uppercase terms required an explicit option:

```dart
const DashronymConfig(enableBareAcronyms: true)
```

In 0.2.0, registered uppercase terms such as `API` and `SDK` match by default,
so most applications can remove that configuration. Marker-wrapped terms
continue to work.

To retain marker-only matching, opt out explicitly:

```dart
const DashronymConfig(enableBareAcronyms: false)
```

Configurations now accept at most 16 marker pairs. Typical configurations use
the three defaults and need no change. A configuration with `minLen: 1` now
correctly matches registered one-character terms.

Use the defensively copying factory for custom marker pairs:

```dart
final config = DashronymConfig.withMarkers(
  acceptMarkers: const ['()', '«»'],
);
```

The const `DashronymConfig` constructor now uses the default markers and cannot
retain a caller-owned mutable list.

### Use the main package import

Use one import for both registry and Flutter UI APIs:

```dart
import 'package:dashronym/dashronym.dart';
```

`package:dashronym/dashronym_core.dart` has been removed. Replace imports of
that library with the main package import above; `DashronymConfig` and
`DashronymRegistry` are exported from it.

### Tooltip and rebuild behavior

Active-tooltip coordination now belongs to `DashronymScope`. At most one
tooltip is open within a scope, while independent scopes no longer interfere
with each other.

`DashronymRegistry`, `DashronymConfig`, and `DashronymTheme` now use value
equality. Applications that construct equivalent values during `build` no
longer cause unnecessary scope updates or tooltip relayouts.

No source changes are required for either behavior.

### What remains supported

The following APIs continue to be the supported package surface:

- `DashronymRegistry` and `DashronymConfig`;
- `DashronymText` and `Text.dashronyms()`;
- `DashronymScope` and `DashronymTheme`;
- `DashronymTooltipBuilder` and `DashronymTooltipDetails`; and
- `DashronymLocalizations`.

Rich `TextSpan` conversion and custom tooltip content remain supported. The
minimum Dart and Flutter versions are unchanged from `0.1.x`.

## Older releases

For migrations from `0.0.x`, read the
[0.1.0 migration guide](https://github.com/dancingskylab/dashronym/blob/v0.1.0/MIGRATION.md)
before applying the changes above.

## Reporting migration problems

Open an issue with the old and new Dashronym versions, Flutter version, target
platform, and the smallest reproducing example. Follow [SECURITY.md](SECURITY.md)
for private security reports.
