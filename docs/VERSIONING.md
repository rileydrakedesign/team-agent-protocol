---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP Versioning Policy

This document is the canonical specification of how TAP — the protocol and its components — is versioned. Wire-format implementations, daemon and relay binaries, SDKs, and adapters all follow the rules below.

The protocol version is independent from component versions. The protocol is what implementations conform to; components are what users install.

---

## 1. Scope

| Versioned thing | Versioning scheme | Source of truth |
|---|---|---|
| Protocol (TAP wire format) | Semantic versioning, `MAJOR.MINOR.PATCH` | This document and [`../protocol/SPEC.md`](../protocol/SPEC.md) §5 |
| Daemon | Semantic versioning per release | `crates/tap-daemon/Cargo.toml` (Phase 2+) |
| Relay | Semantic versioning per release | `pkg/relay/...` build metadata (Phase 3+) |
| SDKs (Rust, Go, TypeScript) | Semantic versioning per release | Native package manifests |
| Adapters | Semantic versioning per release | Adapter source repos |
| Conformance suite | Pinned to a protocol version | `protocol/conformance/VERSION` |

Component versions and the protocol version evolve at different rates. A daemon at v3.4.1 may speak protocol v0.2.0; a v4.0.0 daemon may still speak v0.2.0. Component releases never bump the protocol version implicitly.

---

## 2. Protocol versioning rules

### 2.1 Semantic version triple

`MAJOR.MINOR.PATCH`:

- **MAJOR** — backward-incompatible change to the envelope or to the semantics of an existing method or field. Old clients cannot interoperate without code changes.
- **MINOR** — backward-compatible addition: a new method, a new optional field, a new error code, a new scope value, a new enum variant.
- **PATCH** — clarifications that do not change the wire format or its semantics: prose fixes, fixture additions covering already-specified behavior, schema reorganizations that produce identical wire output.

Pre-1.0.0, MAJOR is `0` and MINOR carries breaking changes. The first stable release is v1.0.0 and follows the rules above strictly.

### 2.2 What counts as breaking

The following require a MAJOR bump:

- Removing or renaming a method.
- Removing a required field from a request, response, or notification.
- Adding a new required field to a request (existing senders will omit it).
- Tightening a constraint (e.g., shortening max length, narrowing a regex).
- Changing the type of a field.
- Changing the semantics of an existing field even if the type is unchanged.
- Removing or renaming an error code.
- Changing the meaning of an existing error code.
- Removing a scope value or trust level.

The following are MINOR:

- Adding a new method.
- Adding a new optional field.
- Adding a new error code.
- Adding a new enum variant where consumers MUST gracefully ignore unknown values (this requirement MUST be set in the original specification of the enum; if it was not, adding a variant is breaking).
- Loosening a constraint (e.g., increasing max length).

The following are PATCH:

- Prose clarification.
- Adding fixtures for already-specified behavior.
- Schema reorganization that produces identical wire output.
- Fixing a typo in an example.

### 2.3 Pre-1.0 grace

While `MAJOR` is `0`, breaking changes are permitted on MINOR bumps but MUST be announced with at least one release of advance notice in `protocol/SPEC.md` Appendix A and in [`ROADMAP.md`](ROADMAP.md).

---

## 3. Negotiation

### 3.1 At handshake

The daemon advertises its supported protocol version in the `agent.register` request. The relay's response carries the version selected for the session.

### 3.2 Algorithm

```
function negotiate(client_version, server_versions_supported):
  if client_version.major not in {v.major for v in server_versions_supported}:
    return error(code=1001, "Version unsupported")
  candidates = [v for v in server_versions_supported if v.major == client_version.major]
  selected = min(candidates, key=ver) if min(candidates) <= client_version else min(client_version, max(candidates))
  return selected
```

In prose: pick the lowest version both peers can speak within the same MAJOR. The reference implementation lives in `crates/tap-protocol/src/envelope.rs::negotiate_version`, `pkg/protocol`, and `packages/tap-protocol/src/envelope.ts`. All three MUST agree.

### 3.3 N-1 support

The relay MUST support the current MAJOR version and the previous MAJOR version. Daemons connecting with an older version MUST receive `agent.disconnect` with `reason: "version_unsupported"`.

### 3.4 No silent downgrade

If the relay selects a lower MINOR, the daemon MUST honor that selection for the entire session. The daemon MUST NOT send messages or fields that postdate the negotiated version.

---

## 4. Deprecation policy

### 4.1 Lifecycle

A method, field, error code, or enum value moves through these states:

1. **Active** — supported.
2. **Deprecated** — supported, but flagged in the spec as scheduled for removal.
3. **Removed** — no longer supported. Removal happens at a MAJOR bump.

### 4.2 Deprecation window

A deprecation MUST be announced at least one MINOR release before the MAJOR release that removes it. The deprecation announcement MUST appear in `protocol/SPEC.md` Appendix A and in the relevant section of the spec, with:

- The deprecated item.
- The reason.
- The replacement, if any.
- The earliest MAJOR version in which removal will occur.

### 4.3 Soft deprecation

Items may be marked deprecated without a removal target ("not recommended; consider X instead"). These remain supported indefinitely until promoted to hard deprecation.

---

## 5. Conformance suite versioning

### 5.1 Pinning

The conformance suite at `protocol/conformance/` is pinned to a protocol version, recorded in `protocol/conformance/VERSION` (created in the Phase 1 follow-up that introduces the file).

### 5.2 Suite-version vs. spec-version

Suite version `X.Y.Z` corresponds to spec version `X.Y.Z`. The suite for spec v0.2.0 lives in the `v0.2.0` git tag of this repository; suites are not retroactively updated to test future protocol behavior.

### 5.3 Implementations claim a target

A conformance claim names the protocol version (and therefore the suite version) it was tested against, per [`CONFORMANCE.md`](CONFORMANCE.md).

---

## 6. Component versioning

### 6.1 Independence

The daemon, relay, and SDKs version independently. Their `MAJOR.MINOR.PATCH` carries the same meaning as for any conventional software release: API changes, new features, fixes.

### 6.2 Compatibility matrix

The repo publishes a compatibility matrix in `docs/compatibility/` (created in Phase 3 when there are multiple components in the wild). Until then, a single repo tag corresponds to a single tested combination.

### 6.3 Release cadence

No fixed cadence. Releases ship when phase ship criteria are met (per `../project-context.md` §8) or when a security fix is required.

---

## 7. Tagging and release

### 7.1 Git tags

Protocol releases: `protocol/v<MAJOR>.<MINOR>.<PATCH>`.

Component releases: `<component>/v<MAJOR>.<MINOR>.<PATCH>` (e.g., `daemon/v0.3.1`, `relay/v0.5.0`).

### 7.2 Release artifacts

Component releases produce signed binaries plus a transparency-log entry per [`../project-context.md` §4.2](../project-context.md#42-distribution).

Protocol releases produce no binary artifacts; they are documentation and schema changes.

### 7.3 Changelog

Each component maintains a `CHANGELOG.md` adjacent to its source. Protocol changes go in `../protocol/SPEC.md` Appendix A.

---

## 8. SDK and adapter compatibility

### 8.1 SDK MAJOR

SDK `MAJOR.MINOR.PATCH` is independent from protocol versioning. An SDK at v2.0.0 may continue to support protocol v0.2.0 alongside protocol v0.3.0.

### 8.2 SDK feature flags

SDKs MAY expose feature flags or capability bits to switch between protocol minor versions. The default MUST be the highest protocol version the SDK supports.

### 8.3 Adapter compatibility

Adapter releases declare in their README the range of daemon versions and protocol versions they support.

---

## 9. References

- RFC 2119 / RFC 8174 — RFC 2119 keywords.
- [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) — the canonical semver definition.
- [`../protocol/SPEC.md`](../protocol/SPEC.md) §5 — wire-side restatement.
- [`SPEC_STYLE.md`](SPEC_STYLE.md) §8 — versioning vocabulary in spec prose.
- [`CONFORMANCE.md`](CONFORMANCE.md) — how implementations claim a target version.
