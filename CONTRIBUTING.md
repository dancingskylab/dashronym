# Contributing to Dashronym

Bug fixes, accessibility improvements, tests, docs, and small scoped API
proposals are welcome.

## Before you start

- Search [open issues][issues] first.
- For anything bigger than a bug fix — a new public API, a dependency, a
  visual redesign — open an issue first and describe the problem you're
  solving.
- Keep PRs narrow. Don't mix a refactor with a behavior change.
- Report vulnerabilities through [SECURITY.md](SECURITY.md), not a public
  issue.

## Setup

Dashronym requires Flutter 3.50 or later.

```sh
flutter pub get
flutter test --exclude-tags golden
```

On macOS you can also run the pixel goldens: `flutter test --tags golden`.

The example app in `example/` is its own package with Material, Cupertino and
widgets-only hosts:

```sh
cd example
flutter pub get
flutter test
```

The repo includes Dart agent skills under `.agents/skills` and works with
editors that support the Dart/Flutter MCP server, but neither is required.

## Before opening a PR

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --exclude-tags golden --coverage --branch-coverage
python3 .github/scripts/check_lcov.py coverage/lcov.info \
  --min-lines 95 --min-branches 85
dart doc --output .dart_tool/api-docs
dart pub publish --dry-run
(cd example && flutter analyze --fatal-infos && flutter test)
```

CI enforces 95% line / 85% branch coverage and treats any dartdoc warning as
a failure. Coverage numbers aren't the goal — cover success, failure, and
edge cases, not just lines.

If you touch layout or visuals, regenerate goldens on macOS (the canonical
renderer) and explain what changed and why:

```sh
flutter test --update-goldens test/src/dashronym_inline_golden_test.dart
```

## Design-system neutrality

The package works in any app because `lib/` uses only Flutter's widgets,
foundation, services and semantics libraries:

- `lib/` and the root `test/` must not import `package:flutter/material.dart`,
  `package:flutter/cupertino.dart`, `material_ui` or `cupertino_ui`. A CI step
  and a unit test enforce this.
- Root tests run in the widgets-only host from
  `test/src/support/dashronym_test_host.dart`, built on `TestWidgetsApp`.
- Code that shows Dashronym with a design system belongs in `example/`, which
  also holds the theme recipes that the API docs embed.

## Testing

- Every bug fix needs a regression test.
- Unit-test parsing, matching, registry, theme, and positioning logic.
- Widget-test focus, keyboard, hover, semantics, overlay lifecycle, text
  scaling, and directionality.
- Check RTL and large text scales when a change touches layout.
- When a change touches keyboard handling or semantics, also run the web
  tests: `flutter test --platform chrome --exclude-tags golden`.

## API and accessibility

Dashronym is pre-1.0 but still tries not to break people without warning:

- Prefer additive changes; document breaks in `MIGRATION.md` with
  before/after code.
- Every public declaration needs dartdoc.
- New value types need explicit equality, immutability, and locale/case
  behavior.
- Interactive content must be reachable by touch, mouse, keyboard, and
  screen readers — that's not optional here, it's the point of the package.
- Custom tooltip builders should follow the same focus/dismissal/viewport
  contract as the stock card.

## Commits and PRs

Short, imperative subject line — Conventional Commits style is welcome:

```text
fix: keep tooltip open while focus is inside
feat: add registry-driven matching policy
```

Describe what changed, why, and how you tested it (including manual
accessibility checks for interaction changes). Add screenshots for visual
work.

By contributing, you agree your contribution is licensed under this repo's
BSD 3-Clause license.

[issues]: https://github.com/dancingskylab/dashronym/issues
