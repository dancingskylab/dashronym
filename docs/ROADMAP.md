# Dashronym roadmap

Dashronym has one job: make registered acronyms in Flutter text easy to
identify and explain without interrupting the reading flow.

This document contains forward-looking priorities, not release commitments.
Completed work belongs in [CHANGELOG.md](../CHANGELOG.md), and concrete
proposals belong in the
[issue tracker](https://github.com/dancingskylab/dashronym/issues).

## Current priorities

The `0.2.x` line focuses on reliability and adoption:

- verify keyboard, pointer, touch, and screen-reader behavior on each supported
  Flutter platform;
- test large text, compact viewports, right-to-left layouts, selection, and
  nested overlays on real devices;
- keep tooltip coordination scoped to the relevant widget tree and Flutter
  view;
- benchmark matching before adding parser or cache complexity;
- add focused recipes for shared registries, localization, rich text, custom
  tooltip content, and dynamic definitions; and
- detect accidental public API changes before release.

## Before 1.0

- Hold a stable release cycle with the registry, matching, overlay, and
  accessibility contracts.
- Document the supported behavior for each input method and platform.
- Keep the minimum supported Flutter version covered in CI.
- Complete manual assistive-technology checks for release targets.
- Publish reviewed source with an exact release tag.

## Product boundaries

Dashronym will remain a Flutter presentation package. It will not:

- require accounts, telemetry, network access, or a hosted service;
- own application-specific glossary storage, import formats, or editorial
  workflows;
- generate definitions or present generated content as verified;
- claim complete accessibility from automated tests alone; or
- expose parser, cache, card, or overlay internals merely to expand the public
  API.
