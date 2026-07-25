# Migration guide

Dashronym is pre-1.0, so minor releases can contain breaking changes. This
guide covers the changes needed to move from `0.1.x` to `0.2.0`.

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
