# Security policy

## Supported versions

Security fixes are provided for the latest release published on pub.dev.
Upgrade to that release before reporting an issue that is already resolved.
Pre-release branches and older `0.x` versions are not guaranteed to receive
backports.

## Reporting a vulnerability

Do not open a public issue for a suspected vulnerability.

Use GitHub's private vulnerability reporting for the
[`dancingskylab/dashronym` repository][advisories]. Include:

- the affected version and Flutter/Dart versions;
- affected platforms;
- a minimal reproduction or clear sequence of events;
- the security or privacy impact;
- whether the issue is already public; and
- any suggested mitigation.

Do not include real credentials, private documents, personal information, or
proprietary glossary data. Replace them with synthetic examples.

If private vulnerability reporting is unavailable, open a public issue that
asks the maintainer for a private contact method without describing the
vulnerability.

## What to expect

The maintainer will aim to acknowledge a complete report within five business
days and provide an initial assessment within ten business days. These are
targets, not a service-level agreement. Complex or coordinated disclosures may
take longer.

Please allow a reasonable remediation and release window before disclosure.
Credit will be offered when requested unless anonymity is necessary.

## Scope

Reports may include:

- unintended access to document, glossary, or account data;
- injection or unsafe rendering caused by package behavior;
- cross-tenant or cross-registry data leakage;
- credential or token exposure in an official integration;
- denial-of-service risks from untrusted input; or
- a vulnerability in release artifacts or the publishing pipeline.

Ordinary bugs without a security or privacy impact belong in the public issue
tracker. Vulnerabilities in Flutter, Dart, or another dependency should also be
reported to that upstream project.

The core Flutter package is designed to process glossary data locally. Future
hosted services or integrations must publish their own operational security,
privacy, retention, incident-response, and support policies before accepting
customer data.

[advisories]: https://github.com/dancingskylab/dashronym/security/advisories
