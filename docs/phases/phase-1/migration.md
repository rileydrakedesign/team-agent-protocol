---
status: draft
phase: 1
owners: ["@rileydrakedesign"]
last-reviewed: 2026-04-29
---

# Phase 1 — Migration & Compatibility

N/A — Phase 1 is the first phase. There is no prior version of TAP to migrate from.

This document exists per [`../../DOCUMENTATION_PLAN.md`](../../DOCUMENTATION_PLAN.md) §3 ("a phase that does not need one of these documents still includes the file with content N/A and why").

---

## 1. First-version posture

TAP v0.1 is the initial public protocol version. There are no compatibility constraints inherited from prior versions.

[`../../VERSIONING.md`](../../VERSIONING.md) §2.3 grants pre-1.0 grace: breaking changes are permitted on MINOR bumps with one release of advance notice. The ROADMAP keeps the protocol pre-1.0 through Phases 1–4; v1.0.0 is targeted alongside Phase 5's public conformance program.

## 2. Future migration concerns sourced from Phase 1

Items future phases must consider when migrating away from Phase 1 artifacts:

- **Spec section anchors.** [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md) §8 requires that anchor names not change without a MAJOR bump. External implementers will deep-link to v0.1 anchors; renames break those links.
- **CUE definition names.** Renaming `#AgentRegisterRequest` and friends MAY require a MAJOR bump under the same rule.
- **Conformance suite version pinning.** [`../../VERSIONING.md`](../../VERSIONING.md) §5 specifies the suite version is pinned to the protocol version; the file `protocol/conformance/VERSION` is created in the Phase 1 follow-up that introduces it.

## 3. References

- [`../../VERSIONING.md`](../../VERSIONING.md) §2.3 — pre-1.0 grace.
- [`../../CONFORMANCE.md`](../../CONFORMANCE.md) §3.1 — suite-version pinning.
- [`../../SPEC_STYLE.md`](../../SPEC_STYLE.md) §8 — versioning vocabulary in the spec.
