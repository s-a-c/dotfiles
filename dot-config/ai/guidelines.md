# Project AI Guidelines

Compliant with [.ai/guidelines.md](.ai/guidelines.md) v<computed>

## Overview
These guidelines govern AI task behavior, sensitive actions, and compliance requirements.

## Acknowledgement Header
id: header-ack
scope: general
priority: 10

All AI-authored artifacts MUST include:
“Compliant with [.ai/guidelines.md](.ai/guidelines.md) v<checksum>”

## Security
id: security
scope: security
priority: 100

Do not include secrets, API keys, passwords, tokens, or bearer credentials in the repository. If scanning detects a secret-like token, fail the task and remediate.

## Path Policy
id: path-policy
scope: repository
priority: 50

Disallow committing files matching tests/Support/Fixtures/*.secrets.* unless explicitly exempted with risk acceptance.
