---
status: accepted
phase: continuing
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP Specification Style Guide

This document specifies the conventions used in [`../protocol/SPEC.md`](../protocol/SPEC.md), the CUE schemas in [`../protocol/schemas/`](../protocol/schemas/), and the conformance fixtures in [`../protocol/conformance/`](../protocol/conformance/). Other TAP documentation inherits a relaxed version of these conventions.

The protocol specification is the most-stylized document in the project. Discipline here is non-negotiable — implementations parse the spec; small inconsistencies become bugs.

---

## 1. Normative vs. informative text

### 1.1 Normative text

Binding. Implementations MUST conform. Identified by the use of RFC 2119 keywords.

### 1.2 Informative text

Non-binding. Provides context, examples, motivation, or rationale. SHOULD NOT contain RFC 2119 keywords. May appear in:

- Sections explicitly marked `*(informative)*`.
- Block quotes introduced by "Rationale:", "Note:", or "Example:".
- The "Overview" section of the spec.
- Appendices unless explicitly marked normative.

### 1.3 RFC 2119 vocabulary

Per RFC 2119 / RFC 8174:

| Keyword | Meaning |
|---|---|
| MUST, SHALL, REQUIRED | Absolute requirement. |
| MUST NOT, SHALL NOT | Absolute prohibition. |
| SHOULD, RECOMMENDED | Strongly suggested; deviation requires careful justification documented in implementation notes. |
| SHOULD NOT, NOT RECOMMENDED | Strongly discouraged; deviation requires careful justification. |
| MAY, OPTIONAL | Truly optional. Implementations choose. |

These keywords appear in uppercase only when used as RFC 2119 keywords. Lowercase "must" and "should" in prose are not normative.

---

## 2. Method naming

JSON-RPC methods use the form `category.action` with both parts in `snake_case`.

| Form | Example |
|---|---|
| Lifecycle | `agent.register`, `agent.heartbeat`, `agent.deregister`, `agent.disconnect` |
| Awareness | `state.announce`, `state.query`, `state.subscribe`, `state.diff` |
| Conflict | `conflict.check`, `conflict.declare`, `conflict.release`, `conflict.notify` |
| Messaging | `msg.send`, `msg.deliver`, `msg.ack`, `msg.error` |
| Consults | `consult.request`, `consult.accept`, `consult.message`, `consult.resolve` |
| Tasks | `task.handoff`, `task.accept`, `task.update`, `task.complete` |
| Policy | `policy.evaluate` |
| Trust | `trust.grant`, `trust.revoke` |
| Approval | `approval.request`, `approval.respond` |

Rules:

- Both `category` and `action` MUST be lowercase.
- Underscores within `action` are allowed (`context_update`).
- The `category` is one of the names listed above; new categories require an RFC.
- Server-pushed notifications use the same form. Direction is documented in prose, not encoded in the name.

---

## 3. Field naming

### 3.1 JSON / wire fields

`snake_case`. No abbreviations except those listed in [`GLOSSARY.md`](GLOSSARY.md) Acronyms (e.g., `jwt`, `mtls`).

| Good | Bad |
|---|---|
| `agent_id` | `agentId`, `AgentID`, `agent-id` |
| `tap_version` | `tapVersion`, `version` |
| `developer_id` | `dev_id`, `userId` |
| `start_line` | `startLine`, `start` |

### 3.2 CUE definitions

CUE definitions use `#PascalCase` for top-level types and `snake_case` for fields, matching the wire format.

```cue
#AgentRegisterRequest: {
    developer_id: string
    machine_id:   string
    editor:       string
    session_id:   string
    capabilities: [...string]
}
```

Constraint regexes are stored as named definitions where reused:

```cue
#TraceID: =~"^[0-9a-f]{32}$"
```

### 3.3 Required vs. optional

CUE definitions mark optional fields with `?:`. Spec prose lists every field as Required (yes/no) in the section's field table.

---

## 4. Identifier formats

| Identifier | Format | Source of truth |
|---|---|---|
| `developer_id` | Lowercase ASCII; matches identity provider login | [`../protocol/schemas/identity.cue`](../protocol/schemas/identity.cue) |
| `agent_id` | 64 lowercase hex characters | [`../protocol/SPEC.md`](../protocol/SPEC.md) §4.2 |
| `machine_id` | UUIDv4 | identity.cue |
| `session_id` | UUIDv4 | identity.cue |
| `trace_id` | 32 lowercase hex characters (W3C Trace Context) | envelope.cue |
| `tap_version` | semver `MAJOR.MINOR.PATCH` | envelope.cue, [`VERSIONING.md`](VERSIONING.md) |

When a new identifier is introduced, add it to `../protocol/schemas/identity.cue` and to this table.

---

## 5. Error codes

### 5.1 Allocation policy

JSON-RPC reserves `-32768` through `-32000`. TAP application errors use `1000`–`9999`.

The full registry is in [`../protocol/SPEC.md`](../protocol/SPEC.md) §13. Allocation rules:

- Codes are allocated in blocks of 10.
- Each block has a category: `1000`–`1009` reserved for transport, `1010`–`1019` rate limits, etc.
- Once allocated, a code MUST NOT be reused for a different meaning. If a code is retired, mark it deprecated; do not reuse.
- New codes require an RFC referencing the registry change.

### 5.2 Error object shape

```json
{
  "code": 1010,
  "message": "Rate limited",
  "data": {
    "retry_after_seconds": 30
  }
}
```

- `code` MUST be an integer.
- `message` MUST be a short, human-readable summary.
- `data` MAY carry structured fields. Schema in CUE per error code.

---

## 6. Schema authoring (CUE)

### 6.1 Coupling with the spec

Wire-format facts are authoritative in CUE. The spec's prose is summary. If prose and CUE disagree, CUE wins and the prose is fixed in the same change.

Every `protocol/SPEC.md` section that introduces a message MUST link to its CUE file.

### 6.2 File layout

One CUE file per logical unit:

- `envelope.cue` — JSON-RPC envelope and shared types.
- `identity.cue` — identifiers (developer, agent, machine, session, trace, repo).
- `<category>_<action>.cue` — one file per method, named after the method (e.g., `agent_register.cue`, `state_announce.cue`).
- Common types shared across messages live in `common.cue` (created when needed).

### 6.3 Imports and packages

All schemas live in package `tap`. Import shared types by package-qualified reference.

### 6.4 Definitions vs. values

Schemas use CUE definitions (`#Name`) for types. Concrete values are not stored in `protocol/schemas/`.

### 6.5 Constraint style

Prefer named constraints over inline regexes when reused:

```cue
// good
#TraceID: =~"^[0-9a-f]{32}$"
trace_id: #TraceID

// bad
trace_id: =~"^[0-9a-f]{32}$"
```

---

## 7. Conformance fixtures

Per [`../protocol/conformance/README.md`](../protocol/conformance/README.md), each fixture is a JSON document with this shape:

```json
{
  "name": "valid_request",
  "description": "Minimal valid agent.register request",
  "schema_ref": "agent_register.cue#AgentRegisterRequest",
  "data": { ... },
  "expected_valid": true,
  "expected_round_trip": true,
  "expected_error_code": null
}
```

Rules:

- Every CUE definition that types a wire message MUST have at least one positive (`expected_valid: true`) and one negative fixture.
- Negative fixtures MUST exercise a specific failure: missing required field, wrong type, constraint violation, length-bound violation, etc. The `description` field MUST identify which.
- Fixtures are organized as `protocol/conformance/fixtures/<category>/<filename>.json` (e.g., `agent_register/valid_request.json`).
- Fixture names are `snake_case`, prefixed with `valid_` or `invalid_`.

---

## 8. Versioning vocabulary

The wire spec is versioned per [`VERSIONING.md`](VERSIONING.md). Within `protocol/SPEC.md`:

- Section headings are stable across MINOR/PATCH versions. New sections may be appended.
- Anchor names MUST NOT change without a MAJOR bump (external implementers link to them).
- Removing or renaming a method requires a MAJOR bump and a deprecation period.

Spec change log lives in `protocol/SPEC.md` Appendix A.

---

## 9. Cross-references

### 9.1 From spec prose

- Cite a section by its number and title: "as specified in §6.1".
- Cite an external standard by document name + section: "RFC 6455 §5.2".
- Hyperlinks to schemas use relative paths: `[\`schemas/envelope.cue\`](schemas/envelope.cue)`.
- Do not embed bare URLs in normative text.

### 9.2 From other docs

Use the relative path from the document's location:

- Inside `docs/`: `../protocol/SPEC.md`, `GLOSSARY.md`.
- Inside RFCs: `../GLOSSARY.md`, `../../protocol/SPEC.md`.

### 9.3 Anchors

Use GitHub-flavored auto-anchors. Headings of the form "## 6.1 `agent.register` (request)" yield anchors like `61-agentregister-request`. When in doubt, view the rendered file on GitHub and copy the anchor from the heading link.

---

## 10. Tone

- Spec prose is terse, declarative, present tense. No first or second person.
- Avoid hedging: "MAY" or "SHOULD" where you mean it; otherwise, an indicative statement of fact.
- Examples in informative blocks may be more conversational, but never use "you".
- Capitalize TAP, JSON-RPC, WSS, MCP, A2A. Lowercase "json", "yaml", "toml" when not at the start of a sentence and not in a code reference.

---

## 11. Examples

Every method section in `protocol/SPEC.md` SHOULD include at least one informative example showing a complete envelope. Examples use `<placeholder>` braces for variables and are syntactically valid JSON. Put examples in fenced code blocks tagged `json`.

---

## 12. Rules of thumb

- Schemas first. Prose second. Examples third.
- One method = one section = one CUE file = at least one positive + one negative fixture.
- Every change to the spec ships with the matching schema and fixture changes in the same PR.
- If you cannot decide between two phrasings, the more boring one is correct.
