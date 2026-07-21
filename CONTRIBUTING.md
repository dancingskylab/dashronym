# Contributing to Dashronym

Thank you for helping make acronym-heavy text easier to understand. Dashronym
welcomes focused bug fixes, accessibility improvements, tests, documentation,
and carefully scoped API proposals.

## Before starting

- Search the [issue tracker][issues] for existing work.
- Open an issue before a large feature, public API change, dependency addition,
  or visual redesign. Describe the user problem and proposed compatibility
  story.
- Keep pull requests narrow. Separate mechanical refactors from behavior
  changes where practical.
- Never include confidential documents, proprietary glossaries, credentials,
  or real user/workspace data in issues, fixtures, screenshots, or telemetry.
- Report suspected vulnerabilities through the process in
  [SECURITY.md](SECURITY.md), not a public issue.

## Development setup

Dashronym supports the minimum and latest Flutter versions declared in
`pubspec.yaml` and `.github/workflows/ci.yml`. Install one of those SDKs, then
run:

```sh
flutter pub get
flutter test --exclude-tags golden
```

macOS contributors can additionally run the canonical pixel comparisons with
`flutter test --tags golden`.

The project includes Dart agent skills in `.agents/skills`. Editors that
support the Dart and Flutter MCP server can also use analyzer, test, runtime,
and widget-inspection tools directly. Neither is required to contribute.

## Required checks

Run the same checks as CI before requesting review:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --exclude-tags golden
flutter test --exclude-tags golden --coverage --branch-coverage
python3 .github/scripts/check_lcov.py coverage/lcov.info \
  --min-lines 95 \
  --min-branches 85
dart doc --output .dart_tool/api-docs
dart pub publish --dry-run
```

On macOS, also run `flutter test --tags golden`. Pixel goldens use macOS as
their canonical renderer; Linux CI runs the complete behavioral suite without
comparing platform-dependent pixels.

CI requires at least 95% line coverage and 85% branch coverage. Coverage is a
guardrail, not a substitute for meaningful assertions. New behavior should
exercise success, failure, boundary, lifecycle, and accessibility paths.
Treat every dartdoc warning as a failure even if the command exits
successfully.

## Testing expectations

- Add a regression test before or with every bug fix.
- Prefer small unit tests for parsing, matching, registry, theme, and
  positioning logic.
- Use widget tests for focus, keyboard, hover, semantics, overlay lifecycle,
  text scaling, directionality, and viewport changes.
- Test at high nonlinear text scales, in RTL, and in compact viewports when a
  change affects layout.
- Use goldens only when pixels are the contract. Keep behavioral assertions
  alongside them.
- Do not update goldens merely to make a failure disappear. Inspect and explain
  every intentional visual change in the pull request.

To regenerate the inline goldens after an intentional visual change:

```sh
flutter test --update-goldens test/src/dashronym_inline_golden_test.dart
git diff -- test
```

Regenerate and review these images on macOS so they match the dedicated golden
CI job.

## Public API and compatibility

Dashronym is pre-1.0, but users still deserve predictable upgrades.

- Prefer additive APIs and deprecation periods over immediate removal.
- Do not export implementation helpers solely to make a test or example easier.
- Add dartdoc and a usage example for every public declaration.
- Update `README.md`, `CHANGELOG.md`, and `MIGRATION.md` with any public API,
  behavior, SDK-floor, semantics, or visual change.
- Include old and new code in `MIGRATION.md` for a breaking change.
- Avoid exposing mutable collections. Define equality, serialization, and
  locale/case behavior explicitly for new glossary models.

## Accessibility and interaction

Accessibility is a release requirement, not an optional enhancement.

- Preserve surrounding text style, locale, direction, scaling, selection, and
  reading order.
- Make interactive content reachable by touch, mouse, keyboard, switch access,
  VoiceOver, TalkBack, and browser assistive technology.
- Verify focus entry, traversal, dismissal, and restoration.
- Avoid duplicate announcements. Prefer meaningful semantic state changes over
  unconditional manual announcements.
- Ensure custom tooltip content follows the same viewport, focus, dismissal,
  and semantics contract as the stock tooltip.
- Include the tested platform, assistive technology, text scale, and input
  method in the pull request when interaction behavior changes.

## Commit and pull request guidance

Use a short imperative subject, optionally following Conventional Commits:

```text
fix: keep tooltip open while focus is inside
feat: add registry-driven matching policy
docs: document minimum Flutter support
```

A pull request should explain:

1. The user-visible problem and outcome.
2. Compatibility or migration impact.
3. Tests and manual accessibility checks performed.
4. Screenshots or recordings for visual changes.
5. Follow-up work deliberately left out of scope.

By contributing, you agree that your contribution is licensed under the
repository's BSD 3-Clause license.

[issues]: https://github.com/dancingskylab/dashronym/issues
