---
status: draft
phase: N
owners: [@your-github-handle]
last-reviewed: YYYY-MM-DD
---

# Phase N — Migration & Compatibility

What changes for users, operators, and implementers when Phase N ships? If nothing changes ("N/A" with a one-line reason is acceptable), state that explicitly.

This document is consumed by:

- Implementers, to know whether to bump their conformance claim.
- Operators, to know whether to upgrade in place or to plan a deployment.
- Users (developers running TAP), to know whether anything in their workflow changes.

---

## 1. Protocol changes

Per [`../../VERSIONING.md`](../../VERSIONING.md):

| Change | Class (MAJOR / MINOR / PATCH) | Notes |
|---|---|---|
| … | … | … |

If any change here is MAJOR, the deprecation window per [`../../VERSIONING.md`](../../VERSIONING.md) §4.2 MUST have been observed.

## 2. Daemon changes

Behavioral changes visible to adapters or to operators of the daemon. Configuration changes (new keys, removed keys, defaults).

- …

## 3. Relay changes

Schema migrations, deployment requirement changes, observability changes.

- …

## 4. Adapter changes

Effects on adapter implementations. New required hooks, new MCP tools, new error paths.

- …

## 5. Conformance suite changes

Fixtures added or removed. Effect on existing claims.

- …

## 6. Configuration migration

For every config file touched by this phase: before, after, and migration command (if automatic).

> Example:
> ```diff
>  # ~/.tap/config.toml
>  [relay]
>  url = "wss://relay.tap.dev"
> + ca_pin = "sha256:..."
> ```

## 7. Data migration (relay)

Schema changes to Postgres, Redis, or S3. Migration plan: forward-compatible writes, rolling deploy, downtime requirement (if any).

- …

## 8. Operator runbook references

Runbooks under [`../../runbooks/`](../../runbooks/) that operators MUST follow during the upgrade window.

- …

## 9. User-visible changes

Anything a developer running TAP would notice without reading release notes.

- …

## 10. Roll-back

If the upgrade goes wrong, how to roll back. State whether roll-back is supported, supported with effort, or not supported.

- Supported: …
- Supported with effort: …
- Not supported: …
