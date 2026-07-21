## Unreleased

### Changed

- Removed unreliable pub.dev vanity-metric badges while retaining badges for
  CI, the published version, enforced coverage floors, and licensing.

## 0.1.0 - 2026-07-20

This release establishes the accessible Flutter interaction contract and the
first portable glossary-data contract. See [MIGRATION.md](MIGRATION.md) for
upgrade examples and behavior changes.

### Added

- Added immutable `DashronymEntry` and `DashronymGlossary` models with aliases,
  tags, provenance fields, deeply immutable JSON metadata, deterministic
  serialization, value equality, clear-safe `copyWith`, and direct
  glossary-to-registry conversion.
- Published the strict, versioned Dashronym glossary JSON Schema at
  `schema/v1/dashronym-glossary.schema.json`.
- Added the Flutter-import-free `dashronym_core.dart` entry point for domain
  code running within Flutter-SDK projects.
- Added rich registry construction, canonical and alias lookup,
  `DashronymDuplicatePolicy`, and rich-entry access from custom tooltip details.
- Added `DashronymScope` for shared registry, matching, theme, and tooltip
  defaults.
- Made `DashronymTheme` a Flutter `ThemeExtension` with animated interpolation
  and explicit clearing of nullable settings.
- Added recursive `DashronymText.rich` and `Text.rich(...).dashronyms()`
  support while preserving authored span metadata and existing widget spans.
- Added a minimum/latest Flutter CI matrix, coverage gates, warning-free
  dartdoc and publication checks, a canonical macOS golden job, plus
  contributing, security, migration, release, and roadmap documentation.
- Added README badges for CI, pub.dev health metrics, enforced coverage floors,
  and licensing.

### Changed

- Standardized package-owned public types and source filenames on the
  `Dashronym` name. This includes `DashronymEntry`, `DashronymRegistry`,
  `DashronymDuplicatePolicy`, and `DashronymTooltipDetails`; see
  `MIGRATION.md` for the complete rename table.
- Clarified registry factories: `DashronymRegistry.fromEntries` accepts rich
  `DashronymEntry` values, while `fromMapEntries` accepts legacy
  `MapEntry<String, String>` values.
- Raised the supported SDK floor to Dart 3.10 and Flutter 3.38.1 so the package
  constraints match the APIs used by the implementation.
- Made `DashronymText` registry, configuration, theme, and tooltip builder
  inheritable. Explicit arguments take precedence over `DashronymScope`, then
  app theme and package defaults.
- Rebuilt tooltip ownership around `OverlayPortal` with layout-time anchor
  positioning so inherited context, lifecycle, focus traversal, nested
  overlays, and root-overlay geometry stay consistent.
- Defined keyboard, hover, outside-tap, Escape, scroll, resize, focus
  restoration, and single-active-tooltip behavior.
- Applied one capability-aware screen-reader announcement path that exposes the
  complete definition, and kept the inserted tooltip available through
  semantics.
- Exposed expanded/collapsed state on each inline glossary control.
- Unified stock and custom tooltip constraints, including safe areas, keyboard
  insets, compact viewports, maximum height, and scrollable long content.
- Preserved selection registration, directionality, locale, semantics
  identifiers, rich styles, and effective text scaling through transformed
  text.
- Moved `flutter_localizations` to development dependencies because the
  package library does not import it.
- Updated package metadata and links to the canonical
  `dancingskylab/dashronym` repository.
- Reduced the roadmap to forward-looking priorities so completed release work
  remains in this changelog instead of going stale in two places.

### Fixed

- Isolated parser caches so definitions can never leak between registries.
- Bounded and corrected LRU promotion, eviction, nullable-value, and validation
  behavior.
- Enforced configuration invariants in release builds and defensively copied
  runtime marker collections.
- Supported marker pairs made from non-BMP Unicode scalar values.
- Expanded explicit marker matching to registered punctuation and mixed-case
  terms such as `(C++)`, `(.NET)`, `(R&D)`, and `(OAuth)`, while keeping bare
  matching conservative.
- Prevented rapid hide/reopen animation completions from removing a replacement
  tooltip.
- Prevented hover tooltips inside stock or custom card controls from triggering
  Flutter `RenderFollowerLayer` layout assertions.
- Kept hover-open tooltips visible while the pointer moves between the trigger
  and surface.
- Prevented WidgetSpan trigger text from receiving the effective scale twice
  while retaining that scale for tooltip content and direct inline widgets.
- Kept interactive acronym semantics reachable when callers provide an outer
  `semanticsLabel`.
- Kept authored locale semantics compatible with Flutter 3.38 by establishing
  the required semantics container.
- Corrected RTL/edge positioning, compact-height clamping, long-definition
  scrolling, and stale overlay dismissal during viewport changes.
- Allowed Material elevation shadows to paint outside tooltip layout bounds
  instead of cropping them to a rectangular viewport clamp.

## 0.0.10

- Updated inline tooltip semantics to use `SemanticsService.sendAnnouncement` with `View.of(context)` so screen reader announcements remain polite and compatible with multi-window Flutter apps.
- Bumped tooling to `flutter_lints` ^6.0.0 and refreshed formatting to keep `dart analyze` clean on Dart 3.10 / Flutter 3.38.
- Verified package health on pub.dev (160/160 score) and dry-run publishing on the latest stable toolchain.
- Slimmed the public API surface to focus on `DashronymText`, `AcronymRegistry`, `DashronymConfig`, `DashronymTheme`, and `DashronymLocalizations`, keeping overlay widgets, parsers, and LRU caching as internal `lib/src/` details.
- Kept the `Text.dashronyms()` extension as a convenient way to enhance existing `Text` widgets, while implementing it in terms of `DashronymText` so both paths share the same behavior.
- Renamed internal files to clearer, feature-oriented names (for example: `acronym_inline.dart`, `acronym_parser.dart`, `lru_cache.dart`, `dashronym_theme.dart`, `dashronym_localizations.dart`) and updated docs/tests to match.
- Split the parsing pipeline into a pure-Dart core (`DashronymParserCore` + `DashronymToken`s) and a small Flutter adapter (`DashronymParser`) that builds spans and inline widgets.
- Documented the internal layering and responsibilities in the codebase so domain logic and presentation concerns are clearly separated.
- Tightened README and in-code documentation to keep `DashronymText` as the primary API while keeping the `Text.dashronyms()` extension as a convenience helper for existing `Text` widgets.
- Made tooltip positioning explicitly respect [TextDirection], so RTL layouts bias the tooltip horizontally from the anchor’s right edge and updated the inline goldens to match.

## 0.0.9

- Introduced a shared `TooltipConstraintsResolver` so every tooltip (stock or custom) respects viewport gutters plus new orientation caps: 360 px portrait, 600 px landscape.
- Wrapped inline tooltips with the resolver, ensuring custom builders inherit the same clamp logic while overlays keep the existing follower nudge/scroll dismissal behaviour.
- Expanded unit and widget coverage (100 % lines) with constraint, positioner, orientation-change, and scroll-dismiss tests; refreshed all inline goldens.
- Replaced the published screenshots with the latest portrait/landscape captures and updated README guidance to highlight the new sizing rules.

## 0.0.8

- Fixed pubspec screenshot metadata quoting for pub.dev

## 0.0.7

- Added annotated screenshots and an animated tooltip walkthrough to the package metadata so pub.dev showcases behavior.
- Expanded pub.dev topics with acronym and accessibility tags to improve discoverability.
- Documented localization constructors to maintain full dartdoc coverage for pub scoring.
- Updated README installation instructions to reference version 0.0.7.

## 0.0.6

- Clamp inline tooltip overlays so they stay within the visible viewport on mobile, desktop, and when the window resizes.
- Made tooltip positioning responsive to safe areas, keyboard insets, and RTL layouts, and prevented teardown setState calls.
- Added regression test coverage for the viewport-clamping behavior.

## 0.0.5

- Expanded dartdoc coverage across public APIs, including constructors and library documentation.
- Clarified usage examples for `DashronymText`, `Text.dashronyms`, and configuration helpers.
- Ran `dart format` on source and tests to keep style aligned with Flutter guidelines.

## 0.0.4

- Added configurable hover hide delay and tooltip fade duration to `DashronymTheme`.
- Introduced animated tooltip dismissal with fade transitions and deferred hover hide timers.
- Improved focus handling to auto-show tooltips and prevent lingering overlays when unmounted.
- Excluded tests from static analysis to speed up local iteration and updated theme tests for new fields.

## 0.0.3

- Refactored inline tooltip widgets for richer semantics and accessibility.
- Added localizations, theme customization options, and comprehensive tests.
- Expanded the example app with advanced customization and localization demos.

## 0.0.2

- Applied `dart format .` and refreshed documentation to align with pub.dev publishing guidelines.

## 0.0.1

- Initial release with `Text.dashronyms()` extension, `DashronymText` widget, and configurable registry/theme support.
