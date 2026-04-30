---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP Conformance Policy

This document specifies how an implementation claims TAP conformance, what conformance means, and how the conformance program is governed.

Conformance is binary at a given protocol version: an implementation either passes the entire suite or it does not. Partial conformance is not a recognized status.

---

## 1. What conformance means

A conformant TAP implementation:

1. Validates every TAP envelope against [`../protocol/schemas/envelope.cue`](../protocol/schemas/envelope.cue) and rejects any message that fails validation.
2. Implements every method specified in [`../protocol/SPEC.md`](../protocol/SPEC.md) at or below the claimed protocol version.
3. Honors every MUST clause in the specification at the claimed version.
4. Passes every fixture in [`../protocol/conformance/fixtures/`](../protocol/conformance/fixtures/) at the claimed version.
5. Negotiates protocol versions per [`VERSIONING.md`](VERSIONING.md).
6. Implements the inbound-message sandboxing requirements specified in [`THREAT_MODEL.md`](THREAT_MODEL.md) §5 (mandatory for any implementation that surfaces inbound content to an LLM).

Implementations MAY support newer or older protocol versions in addition to the claimed version. Conformance is asserted against a specific version.

---

## 2. Implementation classes

Different parts of TAP have different conformance surfaces. An implementation declares its class.

| Class | Required behavior |
|---|---|
| **Daemon** | Full conformance: lifecycle, awareness, conflict, plus the relay-side methods it depends on. Sandboxing required. |
| **Relay** | Full conformance: all methods at all phases the relay supports. Sandboxing required for messages it routes. |
| **Adapter** | Daemon-side methods relevant to the editor (registration, awareness announce, conflict check, message receive). Sandboxing required at the boundary to the editor's LLM. |
| **SDK / library** | Schema validation, envelope construction, version negotiation. No mandatory wire behavior, but its consumers MUST pass the corresponding daemon/relay/adapter class. |

A TAP-conformant *deployment* (the word used in `../protocol/SPEC.md` §1) consists of conformant daemons, relays, and adapters at compatible versions per [`VERSIONING.md`](VERSIONING.md) §3.3.

---

## 3. The conformance suite

Lives at [`../protocol/conformance/`](../protocol/conformance/). Format documented in [`../protocol/conformance/README.md`](../protocol/conformance/README.md). Style rules in [`SPEC_STYLE.md`](SPEC_STYLE.md) §7.

The suite is pinned to a protocol version in `protocol/conformance/VERSION` (created in the Phase 1 follow-up). To run the suite at protocol version `vX.Y.Z`, check out the corresponding git tag.

### 3.1 What the suite covers

- **Schema validation.** Positive and negative fixtures for every CUE definition.
- **Round-trip fidelity.** Where `expected_round_trip: true`, the implementation MUST be able to deserialize, re-serialize, and produce byte-identical output (modulo whitespace; canonicalization rules are TBD in a Phase 1 follow-up RFC).
- **Error codes.** Negative fixtures specify the exact error code expected (where `expected_error_code` is set).
- **Sandboxing patterns** (Phase 1 deliverable per [`THREAT_MODEL.md`](THREAT_MODEL.md) §5.3 — currently tracked as an open item until fixtures land in `conformance/fixtures/sandboxing/`).

### 3.2 What the suite does not cover

- Performance against [`../project-context.md` §3.3](../project-context.md#33-service-level-objectives) SLOs. Performance is measured separately per `docs/perf/REGRESSION_METHODOLOGY.md` (continuing concern).
- Operational properties (availability, observability). Operational conformance is addressed in deployment guidance, not the wire-format suite.
- End-to-end semantic correctness in the presence of a real codebase (e.g., conflict-detection precision/recall). Those are measured against the Phase 5 benchmark corpus.

---

## 4. Test runner contract

Every official binding ships a conformance runner:

- `crates/tap-protocol/tests/conformance.rs` (Rust)
- `pkg/protocol/conformance_test.go` (Go)
- `packages/tap-protocol/src/test/conformance.test.ts` (TypeScript)

External implementations are not required to use these runners but MUST produce equivalent output.

### 4.1 Required output

A runner MUST produce a machine-readable summary on success or failure:

```json
{
  "tap_version_target": "0.1.0",
  "suite_version": "0.1.0",
  "fixtures_total": 14,
  "fixtures_passed": 14,
  "fixtures_failed": 0,
  "fixtures_skipped": 0,
  "failures": []
}
```

`failures[]` carries `{fixture_path, expected, actual, message}` for each failure.

### 4.2 Exit codes

- `0` — every fixture passed.
- `1` — at least one fixture failed.
- `2` — runner error (e.g., suite missing, fixture malformed).

### 4.3 Determinism

Runners MUST be deterministic given the same suite input. No flakes; no "retry on failure".

---

## 5. Claiming conformance

An implementation claims conformance by:

1. Running the suite at a specific protocol version.
2. Producing the machine-readable output above with all fixtures passing.
3. Publishing an attestation containing:
   - Implementation name and version.
   - Implementation class (per §2).
   - Protocol version claimed.
   - Suite version (matches protocol version).
   - Suite output (the JSON from §4.1).
   - Date of the test run.
   - Reference to the source revision tested.
4. Linking the attestation from the implementation's README.

The attestation may be a JSON or YAML file in the implementation's repository, or a release note. There is no central registry in Phase 1; a public registry is a Phase 5 deliverable per `../project-context.md` §8.

---

## 6. Trademark

The "TAP-conformant" mark and the TAP logo (when published) MAY be used by implementations that:

- Maintain a current attestation against the latest non-EOL protocol version.
- Disclose any deviations from the specification clearly in their documentation.
- Pass the corresponding implementation-class requirements.

Trademark policy is administered per [`GOVERNANCE.md`](GOVERNANCE.md). Misuse is grounds for revocation.

The mark is reserved; first publication of brand assets is in Phase 5 alongside the public conformance program.

---

## 7. Re-certification

Implementations are not formally re-certified on a schedule. However:

- A claim against a protocol version that has reached end-of-life (per [`VERSIONING.md`](VERSIONING.md) §3.3 — relay supports current and previous MAJOR) is no longer current.
- A new MAJOR or MINOR version of the suite invalidates prior claims at that version. Implementations SHOULD re-run the suite against the new version and update their attestation.

---

## 8. Disputes

If an implementation claims conformance and a peer believes the claim is false:

1. The challenger files a dispute issue in this repository with the specific fixtures or behaviors at issue.
2. The implementation maintainer responds within 14 days with the suite output or a fix plan.
3. If unresolved within 30 days, the project's steering process per [`GOVERNANCE.md`](GOVERNANCE.md) is invoked.

A sustained dispute may result in trademark revocation.

---

## 9. Future: public conformance program

Phase 5 introduces:

- A public registry of conformance attestations.
- A community certification process for new adapters.
- A badge that pages may display.
- A challenge / response process for community-reported gaps in the suite.

The Phase 5 program is governed by `docs/conformance/external-adapter-process.md` (created in Phase 5).

---

## 10. References

- [`../protocol/SPEC.md`](../protocol/SPEC.md) — normative protocol.
- [`../protocol/conformance/README.md`](../protocol/conformance/README.md) — fixture format.
- [`SPEC_STYLE.md`](SPEC_STYLE.md) — fixture authoring rules.
- [`VERSIONING.md`](VERSIONING.md) — version pinning and N-1 support.
- [`THREAT_MODEL.md`](THREAT_MODEL.md) §5 — sandboxing requirements.
- [`GOVERNANCE.md`](GOVERNANCE.md) — trademark and dispute administration.
