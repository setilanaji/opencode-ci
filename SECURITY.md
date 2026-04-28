# Security Policy

## Supported versions

This project is at an early stage. Only the latest `main` branch receives security updates.

| Version | Supported |
|---------|-----------|
| `main`  | Yes       |
| Older   | No        |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, email **setyajiyudha299@gmail.com** with:

- A description of the issue
- Steps to reproduce
- The impact you believe it has
- Any suggested fix

You can expect:

- An acknowledgement within **3 business days**
- A status update within **7 business days**
- A coordinated disclosure timeline once the issue is confirmed

## Scope

Areas of particular concern for this project:

- **Secret handling** — the workflows pass API keys, SSH keys, and registry credentials. Anything that could leak these via logs, build artifacts, or container images is in scope.
- **Container build** — the reviewer image runs untrusted PR diffs as prompt input; prompt-injection attacks that escalate beyond the review output are in scope.
- **Deploy pipeline** — anything that allows an attacker who can open a PR to influence what gets deployed to `main`.

Out of scope:

- Issues that require physical or local access to a maintainer's machine
- Vulnerabilities in upstream dependencies (please report those upstream)
- Misconfiguration of a forked/derivative repository's secrets
