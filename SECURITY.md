# Security policy

## Supported versions

Security fixes land in the latest release on pub.dev. Upgrade before
reporting an issue against an older `0.x` version.

## Reporting a vulnerability

Don't open a public issue. Use GitHub's [private vulnerability
reporting][advisories] and include the affected version, platform, a minimal
reproduction, and the impact. Leave out real credentials or private data —
use synthetic examples.

If private reporting isn't available to you, open a public issue asking for
a contact method, without describing the vulnerability itself.

## What to expect

Expect an acknowledgment within a few business days and a fix or mitigation
plan soon after, depending on severity. Credit is offered on request.

## Scope

Dashronym is a local, offline text-rendering widget: no network calls, no
accounts, no backend. Realistic reports look like unsafe rendering of
untrusted definition text, or a vulnerability in the release pipeline.

Ordinary bugs belong in the [issue tracker][issues]. Bugs in Flutter or Dart
itself belong upstream.

[advisories]: https://github.com/dancingskylab/dashronym/security/advisories
[issues]: https://github.com/dancingskylab/dashronym/issues
