# Dashronym roadmap

Dashronym aims to be the dependable acronym-glossary foundation for Flutter:
local-first, accessible across input methods, resilient under real layouts,
and easy to adopt without owning an overlay system.

This document contains forward-looking priorities, not shipped history or date
commitments. Completed work belongs in [CHANGELOG.md](../CHANGELOG.md), and
specific proposals belong in the
[issue tracker](https://github.com/dancingskylab/dashronym/issues).

## Current priorities

The next `0.1.x` releases focus on validation and adoption:

- record VoiceOver, TalkBack, and browser screen-reader results;
- stress-test stock and custom surfaces at 400% scaling on compact real-device
  viewports;
- turn the example into a conventional, independently runnable Flutter app;
- add focused recipes for localization, app-level scope, custom accessible
  surfaces, selection, dynamic registries, and large glossaries;
- validate behavior across Android, iOS, web, macOS, Windows, and Linux;
- add scheduled stable/beta compatibility signals without weakening the
  minimum-supported SDK job; and
- detect accidental public API changes before release.

## Matching and schema

Future matching work must be explicit and backward-compatible. Areas under
consideration include:

- escaping literal marker characters;
- registry-driven punctuation, Unicode, and mixed-case bare-term policies;
- property/fuzz tests and large-glossary benchmarks;
- typed fields for stable entry IDs, per-entry locale, pronunciation, semantic
  labels, review status, and effective dates; and
- conformance fixtures and compatibility rules before any schema version 2.

Legacy matching remains available through a documented migration window. New
matching policies must define case, locale, overlap, marker, alias, and
duplicate behavior rather than changing those rules implicitly.

## Portable Dart runtime

`package:dashronym/dashronym_core.dart` has no Flutter imports in its import
graph, but it is still distributed from a package whose pubspec depends on the
Flutter SDK. A standalone Dart CLI, server, or extension backend therefore
cannot consume it without Flutter installed.

Before extracting a separate `dashronym_core` package, the project will:

- validate at least one real non-Flutter consumer and its required API;
- define independent package-version and glossary-schema compatibility;
- move shared fixtures and conformance tests to a runtime-neutral location;
  and
- keep the Flutter package as a thin consumer without circular dependencies.

## Before 1.0

- Hold at least one stable release cycle with the current overlay, entry model,
  matching behavior, and interchange schema.
- Publish a complete compatibility and accessibility contract.
- Maintain minimum-SDK coverage across automated and manual test matrices.
- Freeze the version-1 glossary schema or document its independent evolution
  policy.
- Publish protected, reviewed source with an exact release tag.

## Product boundaries

Dashronym will not:

- require accounts, telemetry, network access, or a hosted service to render a
  local glossary;
- read private documents or message history automatically;
- present generated explanations as verified industry definitions;
- claim complete accessibility from coverage or widget tests alone; or
- expose parser, cache, card, or overlay internals merely to expand the public
  API.
