# Dashronym roadmap

Dashronym's goal is to become the dependable acronym-glossary foundation for
Flutter: correct across registries, accessible across input methods, resilient
under real layouts, and simple enough to adopt without owning an overlay
system. Product integrations can build on that foundation, but they must not
make the open-source package dependent on a hosted service.

This is a sequence, not a date commitment. A checked item is implemented in the
repository; it is not a claim that an unpublished release has shipped. A stage
exits only when all of its quality gates pass.

## Product principles

1. **Local-first core.** The Flutter package works offline with an
   application-owned glossary.
2. **Accessibility is behavior.** Focus, semantics, reading order, text scale,
   and dismissal are part of the public contract.
3. **Registry isolation.** Definitions and state never cross registry, widget,
   view, user, or tenant boundaries.
4. **Additive evolution.** Prefer small public surfaces, immutable models, and
   deprecation paths.
5. **Portable data.** Glossaries use a versioned, documented interchange model
   that is independent of Flutter or any particular consumer. The current
   Flutter package's core entrypoint is extraction-ready, not yet a standalone
   Dart package.

## Stage 0 — `0.1.0` foundation and glossary API

- [x] Validate the exact minimum and latest stable Flutter SDKs in CI.
- [x] Gate formatting, fatal-info analysis, tests, line/branch coverage,
      warning-free dartdoc, and publication dry-run.
- [x] Correct the advertised SDK constraints.
- [x] Fix cross-registry parser cache contamination.
- [x] Fix stale state after registry, configuration, style, or content changes.
- [x] Resolve rapid tooltip reopen/dismiss lifecycle races.
- [x] Remove known dartdoc warnings and stale documentation claims.
- [x] Establish contributing, security, migration, and release processes.
- [x] Connect Dart/Flutter MCP runtime and inspector tools where supported.
- [x] Add immutable `AcronymEntry` and `DashronymGlossary` models.
- [x] Add aliases, provenance, metadata, and atomic duplicate policies while
      keeping `AcronymRegistry(Map<String, String>)`.
- [x] Publish a strict version-1
      [glossary JSON Schema](../schema/v1/dashronym-glossary.schema.json) with
      deterministic serialization.
- [x] Add `DashronymScope` and Flutter `ThemeExtension` integration.
- [x] Process supported nested `TextSpan` trees and preserve existing
      `WidgetSpan`s and explicit semantics boundaries.
- [x] Validate marker pairs and length bounds in release builds.
- [x] Match registered punctuation and mixed-case terms inside explicit
      markers while retaining conservative legacy bare matching.

Exit gates:

- all CI jobs pass on minimum and latest SDKs;
- at least 95% line and 85% branch coverage;
- zero analyzer, formatter, dartdoc, or publication warnings;
- explicit regression tests for registry isolation and rapid reopen; and
- clean installation and README quick start from a packed artifact.

## Stage 1 — `0.1.0` accessible interaction and layout contract

- [x] Give each inline trigger stable overlay ownership and eliminate mutable
      entry races.
- [x] Keep the surface open while pointer or keyboard focus is inside it.
- [x] Define focus entry, traversal, Escape, outside dismissal, scroll
      dismissal, and focus restoration for every activation method.
- [x] Use one non-duplicative semantics announcement strategy, with platform
      capability checks where a manual announcement remains necessary.
- [x] Exclude the dismiss barrier from semantics.
- [x] Make long definitions and custom content viewport-height aware and
      scrollable without trapping focus.
- [x] Propagate text scaler, locale, directionality, strut, selection, and
      surrounding style consistently through inline spans.
- [x] Resolve tooltip constraints once so stock and custom surfaces receive the
      same geometry contract.
- [x] Apply `cardMinLeadingWidth`, support nullable theme clearing, and
      interpolate app-theme changes.

Exit gates:

- widget tests cover touch, mouse, keyboard, focus, semantics, RTL, nonlinear
  scaling, compact windows, view insets, and custom builders;
- manual VoiceOver, TalkBack, and web screen-reader checks are recorded;
- no clipped or unreachable stock content at 400% stress scaling; and
- `MIGRATION.md` contains exact before/after code for every break.

## Stage 2 — `0.1.x` validation and adoption

- [ ] Record manual VoiceOver, TalkBack, and browser screen-reader results.
- [ ] Stress test stock and custom surfaces at 400% scaling on compact
      real-device viewports.
- [ ] Provide a conventional, independently runnable example application.
- [ ] Add recipes for localization, app-level scope, custom accessible
      surfaces, selection, dynamic registry updates, and large glossaries.
- [ ] Validate Android, iOS, web, macOS, Windows, and Linux behavior.
- [ ] Add scheduled latest-stable CI and an informational beta-channel job.
- [ ] Snapshot the public API and detect accidental compatibility changes.
- [ ] Add issue templates for bugs, accessibility reports, and API proposals.

Exit gates:

- examples compile in CI;
- platform and assistive-technology exceptions are documented;
- API compatibility changes cannot land unnoticed; and
- no unresolved critical correctness or accessibility issues remain.

## Stage 3 — `0.2.x` matching and schema evolution

- [ ] Decide whether stable entry IDs, per-entry locale, pronunciation,
      semantic labels, review status, and effective dates graduate from
      `metadata` into typed schema fields.
- [ ] Add an explicit escape policy for literal marker characters.
- [ ] Offer explicit unmarked/bare matching policies:
  - legacy ASCII behavior;
  - exact registry-driven terms; and
  - opt-in Unicode, mixed-case, and punctuation-aware terms such as `C++`,
    `C#`, `.NET`, `R&D`, and `OAuth`.
- [ ] Add parser property/fuzz tests and large-glossary benchmarks.
- [ ] Define compatibility rules and fixtures before accepting schema version
      2 or signed/delta packs.
- [ ] Publish matching conformance fixtures for other runtimes.

Exit gates:

- legacy behavior remains available for a documented deprecation window;
- versioned JSON fixtures round-trip, and unsupported versions fail clearly;
- matching behavior is documented for case, locale, aliases, punctuation,
  markers, overlap, and duplicate entries; and
- benchmarks protect interactive rendering from large-registry regressions.

## Stage 4 — standalone portable runtime

`package:dashronym/dashronym_core.dart` deliberately has no Flutter imports in
its import graph, but it is distributed from a package whose pubspec depends on
the Flutter SDK. It is useful for separation inside Flutter projects; it is not
yet consumable by a Dart-only server, CLI, or extension backend.

- [ ] Validate a real non-Flutter consumer and its required matching surface.
- [ ] Extract and publish a separately versioned, Flutter-independent
      `dashronym_core` Dart package before shipping any non-Flutter Dart
      integration.
- [ ] Move shared schema fixtures and conformance tests to a runtime-neutral
      location.
- [ ] Keep the Flutter package as a thin consumer without creating circular
      dependencies.
- [ ] Document package-version and glossary-schema compatibility independently.

Exit gates:

- `dart pub get`, analysis, and tests succeed without a Flutter SDK in a
  standalone consumer;
- the Flutter package passes its complete minimum/latest matrix against the
  extracted core; and
- the extraction has a proven consumer and ownership plan, not only a new
  package name.

## Stage 5 — `1.0.0`

- [ ] Hold at least one stable release cycle with the new overlay, entry model,
      matching policies, and interchange schema.
- [ ] Remove only APIs whose deprecation window has elapsed.
- [ ] Publish a complete compatibility and accessibility contract.
- [ ] Support the minimum SDK across the full CI and manual test matrix.
- [ ] Freeze the version-1 glossary schema or document its independent
      compatibility rules.
- [ ] Publish from protected, reviewed source with an exact release tag.

## Deliberate non-goals

- Requiring accounts, telemetry, network access, or a hosted service to render
  local glossary entries.
- Automatically reading private documents or message history.
- Treating generated explanations as verified industry definitions.
- Claiming complete accessibility based only on line coverage or widget tests.
- Expanding the public API with internal parser, cache, card, or overlay
  implementation types.
