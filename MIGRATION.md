# Migration guide

This guide covers changes that need more explanation than a changelog entry.
Always read the release notes between the version you use and the version you
are adopting.

Dashronym is currently pre-1.0. A minor release can contain breaking changes,
but the project still aims to deprecate public APIs before removal whenever a
safe compatibility path exists. A critical correctness, privacy, or security
fix may require a faster change.

## 0.0.10 to 0.1.0

### Consistent package type names

Version 0.1.0 standardizes package-owned Dart declarations and filenames on
the `Dashronym` name. The domain language remains unchanged: entries still
have an `acronym` field, glossary JSON still uses `"acronym"`, and matching
options such as `enableBareAcronyms` keep their established names.

Update these public names:

| Before or development-preview name | 0.1.0 name |
| --- | --- |
| `AcronymRegistry` | `DashronymRegistry` |
| `AcronymEntry` | `DashronymEntry` |
| `AcronymDuplicatePolicy` | `DashronymDuplicatePolicy` |
| `AcronymTooltipDetails` | `DashronymTooltipDetails` |
| `DashronymsTextX` | `DashronymTextExtension` |
| `AcronymRegistry.fromAcronymEntries(...)` | `DashronymRegistry.fromEntries(...)` |
| `AcronymRegistry.fromEntries(...)` | `DashronymRegistry.fromMapEntries(...)` |

No deprecated aliases are exported. This is an intentional pre-1.0 cleanup so
applications have one canonical vocabulary before the package stabilizes.
Imports from `package:dashronym/src/` remain unsupported; their filenames now
also match their primary `Dashronym…` declarations.

Ordinary `Text(...).dashronyms()` calls are unchanged. The extension rename
only affects code that explicitly refers to the extension declaration by name.

The original map data shape remains supported. Most map-based applications
only need to rename the registry type:

```dart
DashronymText(
  'Install the (SDK).',
  registry: DashronymRegistry({
    'SDK': 'Software Development Kit',
  }),
);
```

Review the SDK floor and the interaction, semantics, and layout changes below
before updating visual or accessibility expectations.

### Minimum SDK

Version 0.1.0 requires Dart 3.10 or later and Flutter 3.38.1 or later. The
previous metadata paired a Dart minimum with a Flutter minimum that could not
provide that Dart version.

Upgrade Flutter before upgrading Dashronym:

```sh
flutter --version
flutter upgrade
flutter pub get
```

Applications that must remain on an older Flutter SDK should keep their current
Dashronym constraint until they can upgrade. The package is validated on both
the minimum supported SDK and the latest stable SDK in CI.

### Rich entries, aliases, and duplicate handling

Use `DashronymEntry` when a definition needs aliases, tags, provenance, metadata,
or a longer explanation:

```dart
final entry = DashronymEntry(
  acronym: 'API',
  expansion: 'Application Programming Interface',
  definition: 'A contract used by software components.',
  aliases: const ['Web API'],
  tags: const ['software'],
  source: 'https://example.com/methodology',
);

final registry = DashronymRegistry.fromEntries([entry]);
```

`descriptionOf('Web API')` and `entryOf('Web API')` now resolve the canonical
entry. Custom tooltip builders can read the same rich value through
`details.entry`:

```dart
DashronymText(
  'Call the API.',
  registry: registry,
  config: const DashronymConfig(enableBareAcronyms: true),
  tooltipBuilder: (context, details) {
    return Text(details.entry?.source ?? details.description);
  },
);
```

`details.entry` can be `null` for a legacy map value that cannot form a valid
rich entry. Collection meanings are explicit:

- `entries` and `length` contain/count canonical entries only;
- `lookupTerms` and `lookupTermCount` include canonical terms and aliases; and
- `richEntries` contains each retained `DashronymEntry` once.

The map constructor and `fromMapEntries` preserve the historical normalized
last-value-wins behavior. Rich registries created with `fromEntries` reject
canonical/alias collisions by default. Select
`DashronymDuplicatePolicy.keepFirst` or
`DashronymDuplicatePolicy.keepLast` only when silent conflict resolution is an
intentional import policy. Resolution is atomic: a conflicting rich entry is
kept or discarded as a whole, including all its aliases.

### Versioned glossary JSON

`DashronymGlossary` provides strict, deterministic version-1 import/export:

```dart
import 'package:dashronym/dashronym_core.dart';

final glossary = DashronymGlossary.fromJsonString(encodedJson);
final registry = glossary.toRegistry();

final updatedJson = glossary.toJsonString(pretty: true);
```

The decoder rejects unknown fields, unsupported versions, invalid types,
leading/trailing whitespace, duplicate aliases/tags, non-JSON metadata, and
timestamps that are not strict RFC 3339 date-times with an explicit timezone.
Invalid calendar values are rejected rather than normalized, and decoded
offsets are stored in UTC. Put application extensions in `metadata`. Inspect
the published
[version-1 JSON Schema](schema/v1/dashronym-glossary.schema.json) before
producing packs.
The schema validates the portable JSON shape. Import through
`DashronymGlossary` and build a `DashronymRegistry` as well: those APIs enforce
semantic rules that standard JSON Schema cannot express portably, including an
alias not repeating its sibling canonical acronym and normalized collision
handling across entries.

`dashronym_core.dart` has no Flutter imports in its own import graph, so it
keeps domain code separate inside Flutter-SDK projects. The `dashronym` package
itself still declares an SDK dependency on Flutter. A standalone Dart CLI or
server therefore cannot depend on this package without a Flutter SDK; see the
[portable Dart runtime priorities](docs/ROADMAP.md#portable-dart-runtime) for
the requirements that precede a separate core package.

### Shared configuration and app theming

Arguments can now be inherited from `DashronymScope`:

```dart
DashronymScope(
  registry: registry,
  config: const DashronymConfig(enableBareAcronyms: true),
  tooltipBuilder: buildGlossaryTooltip,
  child: const Article(),
);

// Inside Article:
const DashronymText('The API returns JSON.');
```

For visual defaults, `DashronymTheme` is now a Flutter `ThemeExtension`:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const [
      DashronymTheme(cardWidth: 280),
    ],
  ),
  home: DashronymScope(
    registry: registry,
    child: const Article(),
  ),
);
```

Resolution order is:

1. an explicit `DashronymText` or `Text.dashronyms()` argument;
2. the nearest `DashronymScope`;
3. `DashronymTheme` from `ThemeData.extensions` for theme values; and
4. package defaults.

Omitting `registry` without an ancestor `DashronymScope` throws a descriptive
`FlutterError`. Existing code that passes a registry remains valid.
Theme interpolation now works during animated `ThemeData` changes.

To distinguish an explicit argument from an inherited value,
`DashronymText.registry`, `DashronymText.config`, and
`DashronymText.theme` are now nullable public fields. Existing constructor
calls remain valid, but code that reads those fields as non-null must account
for the source-level type change:

```dart
// 0.0.10: the fields were always non-null.
final AcronymRegistry registry = dashronymText.registry;

// 0.1.0: use ! only when your code supplied the argument...
final DashronymRegistry explicitRegistry = dashronymText.registry!;

// ...or read the inherited value from a build context.
final DashronymRegistry inheritedRegistry = DashronymScope.of(context).registry;
```

`DashronymTheme.copyWith` retains strongly typed replacement arguments.
Nullable values other than `hoverHideDelay` are cleared with their matching
flag:

```dart
final updatedTheme = theme.copyWith(
  clearAcronymStyle: true,
  clearCardIconColor: true,
  clearTooltipMaxWidth: true,
);
```

For compatibility, `copyWith(hoverHideDelay: null)` still clears
`hoverHideDelay`. Supplying both a replacement and its `clear…` flag throws
`ArgumentError`.

### Rich text conversion

`Text.rich(...).dashronyms()` and `DashronymText.rich(...)` now process nested
`TextSpan` trees:

```dart
Text.rich(
  const TextSpan(
    children: [
      TextSpan(text: 'Call the '),
      TextSpan(
        text: 'API',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(text: '.'),
    ],
  ),
).dashronyms(
  registry: registry,
  config: const DashronymConfig(enableBareAcronyms: true),
);
```

Existing `WidgetSpan`s are preserved. A `TextSpan` with its own
`semanticsLabel` is treated as an author-controlled semantics boundary and is
left unchanged. Review recognizers around matched terms: an acronym becomes an
interactive glossary control instead of retaining a surrounding
`TextSpan.recognizer`.

### Runtime configuration validation

Invalid `DashronymConfig` values now throw in release builds when validated or
used by the parser. Each marker pair must contain exactly two Unicode scalar
values, `minLen` must be positive, and `maxLen` must be at least `minLen`.

For marker collections assembled at runtime, use the defensive constructor:

```dart
final config = DashronymConfig.immutable(
  acceptMarkers: markersFromSettings,
);
```

The `const DashronymConfig(...)` constructor remains available. It retains the
supplied marker list to support const construction, so use
`DashronymConfig.immutable` for mutable inputs.

Explicit marker matching now accepts any registered single-line term within
the configured Unicode-scalar length bounds. For example, `(C++)`, `(.NET)`,
`(R&D)`, and `(OAuth)` can resolve without enabling bare matching. Version
0.0.10 limited marker contents to ASCII letters and digits, so a registry that
already contains punctuated or mixed-case terms can gain new explicit matches
after upgrading. The first closing delimiter ends the term; delimiters inside
a term require a different marker pair. Bare matching remains opt-in and
conservative ALL-CAPS ASCII.

### Interaction, accessibility, and layout

The tooltip contract is now consistent across stock and custom content:

- tap/click and Enter/Space toggle the tooltip;
- keyboard focus opens it, Tab can move into its controls, and Escape closes
  it;
- closing from a tooltip control restores focus to the trigger without
  immediately reopening;
- moving the pointer from a trigger into its tooltip keeps it open;
- opening another acronym closes the previous tooltip;
- outside activation, focus departure, and ancestor scrolling dismiss it;
- trigger-local inherited theme and media-query values reach the overlay;
- card controls can open nested overlays such as Material hover tooltips;
- safe areas, visible keyboard insets, viewport size, and theme width limits
  produce one bounded geometry contract; and
- long stock or custom content receives a scrollable host.

Applications with a custom `tooltipBuilder` should remove any assumption that
the returned widget receives unlimited height. Make internal controls
keyboard-reachable and call `details.hideTooltip` for custom close actions.

The stock card now applies `DashronymTheme.cardMinLeadingWidth`, so its spacing
is more compact than 0.0.10 at the default value. Refresh intentional golden
expectations after visual review.

Announcements no longer use both a manual event and a live region for the same
state change. Platforms reporting explicit-announcement support receive the
localized acronym and complete definition; other platforms receive the
inserted card, including its description, as a live region. The
outside-dismiss barrier is excluded from semantics.

`DashronymText.semanticsLabel` now replaces the non-interactive prose while
preserving matched acronym buttons. In 0.0.10 it excluded the complete visual
tree, which made those definitions unreachable to assistive technology.
Update tests that expected one replacement semantics node. `DashronymText`
also forwards a `semanticsIdentifier`, participates in `SelectionArea`, and
propagates scaler, direction, locale, and surrounding style to inline content
without double-scaling its `WidgetSpan` triggers.

### Correct registry and widget isolation

Parsed definitions are now isolated to the registry that supplied them. Code
should not rely on definitions parsed by one `DashronymRegistry` appearing in a
widget that uses another registry; that behavior was a cache bug.

No source migration is expected. If tests accidentally depended on leaked
definitions, give each widget the registry it actually needs.

Open overlays also update when their acronym, description, theme, builder, or
inherited values change. Rapid close/reopen animation can no longer remove the
replacement tooltip.

## 0.0.9 to 0.0.10

Version 0.0.10 narrowed the supported public API. The supported entry points
at that release were listed below. When migrating directly to 0.1.0, apply the
type renames from the table above as well.

- `DashronymText`
- `Text.dashronyms()`
- `AcronymRegistry`
- `DashronymConfig`
- `DashronymTheme`
- `DashronymLocalizations`
- `DashronymTooltipBuilder` and `AcronymTooltipDetails`

### Replace direct parser use

Before:

```dart
final spans = DashronymParser(
  registry: registry,
  config: config,
  theme: theme,
  baseStyle: style,
).parseToSpans(message);

return Text.rich(TextSpan(style: style, children: spans));
```

After:

```dart
return DashronymText(
  message,
  registry: registry,
  config: config,
  theme: theme,
  style: style,
);
```

Use `Text.dashronyms()` when adapting an existing `Text` widget. As of 0.1.0,
plain text and supported nested `TextSpan` trees are both processed; see the
rich-text section above for preservation boundaries.

### Replace direct inline widget use

`AcronymInline` is an implementation detail. Pass the acronym in source text
and let `DashronymText` own focus, semantics, matching, and overlay lifecycle.

Before:

```dart
AcronymInline(
  acronym: 'SDK',
  description: 'Software Development Kit',
  theme: theme,
  textStyle: style,
)
```

After:

```dart
DashronymText(
  '(SDK)',
  registry: AcronymRegistry({
    'SDK': 'Software Development Kit',
  }),
  theme: theme,
  style: style,
)
```

### Replace the stock tooltip card

`DashronymTooltipCard` is no longer public. Most callers should use the stock
surface without a builder. For branded content, return an application-owned
widget from `tooltipBuilder`:

```dart
DashronymText(
  '(SDK)',
  registry: registry,
  tooltipBuilder: (context, details) {
    return Card(
      child: ListTile(
        title: Text(details.acronym),
        subtitle: Text(details.description),
        trailing: IconButton(
          tooltip: 'Close',
          onPressed: details.hideTooltip,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  },
)
```

The custom surface must remain usable with large text, compact viewports,
keyboard focus, touch, and assistive technology.

### Replace the exported LRU helper

`Lru` was an internal optimization and has no public replacement. Applications
that need caching should use a cache they own and test. Do not import files
under `package:dashronym/src/`; paths and declarations under `src` can change
without notice.

## Reporting migration problems

Open an issue with the old and new Dashronym versions, Flutter version, target
platform, the smallest reproducing code sample, and the unexpected behavior.
For private security or data-isolation concerns, follow `SECURITY.md`.
