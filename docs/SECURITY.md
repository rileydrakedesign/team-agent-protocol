# Security Policy

TAP is a coordination layer that sits in the path of every agent edit and carries inter-developer messages and consults. Vulnerabilities in TAP can compromise the integrity of users' source code, leak proprietary context between agents, or enable cross-team prompt-injection attacks. We take reports seriously and ask reporters to follow this policy so we can respond effectively.

## Supported versions

Until TAP reaches a stable release, security fixes are issued only against `main` and the most recent tagged release. Once Phase 4 ships, this section will be updated with the supported-version matrix.

## Reporting a vulnerability

**Do not open a public issue for security reports.**

Email reports to **security@tap.dev** (forthcoming — until the address is provisioned, file a private security advisory via the GitHub Security tab on this repository).

Encrypt sensitive reports with the project PGP key:

```
[ PGP key fingerprint to be published with first tagged release ]
```

Include in your report:

- A description of the issue and its potential impact.
- Steps to reproduce, including any required configuration.
- The affected component (protocol, daemon, relay, adapter, web).
- The version, commit, or release in which you observed it.
- Whether the issue has been disclosed elsewhere.

## What to expect

- **Acknowledgement** within 2 business days.
- **Triage and severity assessment** within 5 business days, using CVSS 3.1.
- **Fix and coordinated disclosure plan** for confirmed issues, including embargo timing and credit. The default embargo window is 90 days, extendable by mutual agreement.
- **Post-fix advisory** published as a GitHub Security Advisory and linked from the release notes.

## Scope

In scope:

- The TAP protocol specification (e.g., logical flaws that allow scope escalation, identity spoofing, or message-integrity bypass).
- The daemon, relay tiers, official adapters, SDKs, and dashboards in this repository.
- Cryptographic protocols used for transport (mTLS pinning, JWT issuance) and audit chaining.
- Supply-chain integrity of TAP releases (signing, reproducible builds, transparency log).

Out of scope:

- Vulnerabilities in third-party agents (Claude Code, Cursor, Codex, Aider). Report those to the upstream vendor; if the issue is exploitable specifically because of how an adapter integrates with TAP, that *is* in scope.
- Issues in self-hosted deployments where the operator has disabled documented security controls.
- Denial-of-service from clients that have already authenticated and exceeded documented rate limits — these are policy concerns, not vulnerabilities.

## Threat model

The full threat model for TAP is maintained in [`THREAT_MODEL.md`](THREAT_MODEL.md). It covers:

- Identity (developer, agent, repo, trust pairs)
- Transport (mTLS, JWT lifecycle, replay defense)
- Message integrity and audit chain
- Sandboxing of inbound agent messages (the "structured envelope, never raw prompt prepending" rule)
- Supply chain (codegen integrity, signed releases, dependency review)

Reports should reference the threat model where applicable.

## Safe-harbor

Researchers acting in good faith and within the bounds of this policy will not be subject to legal action by the project. We follow the principles of the [disclose.io](https://disclose.io) safe-harbor language.
