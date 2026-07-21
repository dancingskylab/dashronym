# Releasing Dashronym

This checklist is for maintainers. A release is complete only when the
published package, source commit, tag, documentation, and migration guidance
all describe the same behavior.

## Version policy

Before 1.0:

- patch releases fix defects and documentation without intentionally breaking
  supported public behavior;
- minor releases may change public behavior, but every intentional break needs
  an explicit migration path and should use deprecation first where practical;
  and
- a security, privacy, or correctness issue can justify an accelerated change,
  with the rationale documented.

After 1.0, follow Semantic Versioning.

## 1. Define the release

1. Choose the version and list its user-visible outcomes.
2. Confirm which documented priority or tracked issue it advances.
3. Identify public API, semantics, focus, matching, layout, visual, minimum-SDK,
   and performance changes.
4. For every breaking change, add compile-ready before/after examples to
   `MIGRATION.md`.
5. Update `CHANGELOG.md` with the release date and group entries under Added,
   Changed, Fixed, Deprecated, Removed, Security, as applicable.
6. Update README examples and package metadata without making claims that are
   not covered by tests.

Do not include an unrelated refactor simply because a release is already in
progress.

## 2. Verify compatibility

The supported Flutter matrix is declared in `pubspec.yaml` and
`.github/workflows/ci.yml`.

- Test the exact minimum Flutter version.
- Test the latest stable Flutter patch listed in the
  [official Flutter SDK archive][flutter-archive].
- Keep the minimum as low as the implementation can honestly support; do not
  raise it solely because a newer SDK exists.
- When the latest pin changes, update CI, README, and release notes together.
- Verify the Dart constraint can actually be supplied by the minimum Flutter
  SDK.

The example must compile on every supported SDK even though it is not a
separately published application.

## 3. Run release checks

Start from a clean worktree:

```sh
git status --short
flutter --version
flutter pub get
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

Run `flutter test --tags golden` on macOS, which is the canonical renderer for
the checked-in pixel baselines. Linux CI runs all behavioral tests but excludes
platform-dependent golden comparisons.

Treat dartdoc warnings as failures. Inspect all publication files listed by the
dry run. Confirm that generated output, credentials, internal planning data,
and customer glossary data are absent.

For interaction or visual work, also verify:

- Android TalkBack and iOS VoiceOver;
- keyboard traversal, Escape, focus restoration, mouse, and touch;
- browser semantics;
- RTL and mixed-direction text;
- nonlinear text scaling through at least 200%, plus a stress check at 400%;
- compact portrait, landscape, split-screen, and visible-keyboard viewports;
- stock and custom tooltip builders; and
- all intentional golden changes.

Record the devices, OS versions, assistive technologies, and exceptions in the
release pull request.

## 4. Review the public contract

- Inspect exports from `lib/dashronym.dart`.
- Confirm every public declaration has useful dartdoc.
- Compare the generated API with the previous release.
- Confirm equality, immutability, matching, locale, serialization, and null
  behavior for new models.
- Benchmark large inputs or registries when parser/cache behavior changes.
- Verify that separate registries, widgets, views, and tenants cannot leak
  definitions or state to one another.
- Confirm custom builders cannot bypass required viewport and accessibility
  behavior without that limitation being documented.

## 5. Prepare the release commit

The release commit must contain:

- the version in `pubspec.yaml`;
- final `CHANGELOG.md`, `MIGRATION.md`, and README updates;
- refreshed examples and intentional goldens;
- no temporary debug output or skipped tests; and
- a clean `dart pub publish --dry-run`.

Merge the release pull request and wait for required CI checks on `main`.
Do not publish from an unreviewed local-only commit.

## 6. Publish and tag

From the exact green commit on `main`:

```sh
git pull --ff-only
git status --short
git tag -a vX.Y.Z -m "Dashronym X.Y.Z"
git show --stat vX.Y.Z
dart pub publish --dry-run
dart pub publish
git push origin vX.Y.Z
```

Publishing is irreversible. Read the package name and version in the
confirmation prompt instead of approving by habit.

Create a GitHub release from the tag. Copy the concise user-facing changes from
the changelog, link `MIGRATION.md` for any compatibility work, and acknowledge
security reporters where appropriate.

If publication fails, do not reuse or move a tag that has already been pushed.
Fix the release on a new commit and choose a new version if pub.dev accepted the
original version.

## 7. Post-release verification

- Confirm pub.dev shows the expected version, README, badges, screenshots, SDK
  constraints, repository link, topics, platform icons, license, and score.
- Install the published version into a clean temporary Flutter app.
- Run the README quick start.
- Confirm the GitHub tag resolves to the published source.
- Close the milestone and move incomplete work to a later milestone.
- Monitor new issues for installation, accessibility, and migration regressions.

## Future automation

Trusted publishing from protected GitHub tags can eventually replace the
interactive publish step. Add it only after branch protection, required
reviews, tag naming, environment approvals, and a dry-run artifact have been
tested. Keep publication separate from ordinary CI so a pull request can never
release a package.

[flutter-archive]: https://docs.flutter.dev/install/archive
