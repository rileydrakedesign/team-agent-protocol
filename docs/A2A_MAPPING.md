---
status: draft
phase: 1
owners: [@rileydrakedesign]
last-reviewed: 2026-04-29
---

# TAP ↔ Google A2A Mapping

> **Status note.** This document is a draft scaffold. The detailed message-level mapping below MUST be verified against the live Google Agent2Agent specification before TAP v0.1 is finalized. Items marked `[verify]` need a check against the current upstream spec.

This document specifies how TAP relates to Google's [Agent2Agent (A2A) protocol](https://github.com/google-a2a/A2A). TAP's positioning per [`../project-context.md` §1.3](../project-context.md#13-positioning) is that TAP is "conformant with Google A2A for agent identity and discovery; extends with development-specific primitives." This document operationalizes that claim.

The mapping has three categories:

1. **Conforming** — TAP uses A2A verbatim. Identity, discovery, and the basic agent metadata model.
2. **Extending** — TAP adds messages and concepts A2A does not specify: cross-developer awareness, conflict detection, consults, task handoff (where TAP's task model goes beyond A2A's), trust pairs, scopes, policy.
3. **Deviating** — Where TAP's needs require behavior that differs from A2A. Each deviation MUST be justified in this document.

---

## 1. Why this mapping exists

TAP claims interoperability with A2A. That claim only holds if:

- A TAP daemon or relay can identify itself in an A2A-style discovery flow.
- A TAP agent's identity is consistent with how A2A talks about agents.
- A non-TAP A2A peer can interact with TAP's lifecycle and discovery surfaces without bespoke shimming.

Without this document, "conformant with A2A" is a marketing claim. With it, it's a checkable property and a stable contract.

---

## 2. Maintenance

A2A is an external standard not under TAP's control. This document MUST be re-checked:

- On every A2A spec release.
- Before any TAP MAJOR version bump.
- Whenever a TAP RFC introduces a new message that touches the conforming or deviating surfaces.

Owner: see front-matter. Drift is tracked in [`RISK_REGISTER.md`](RISK_REGISTER.md) under risk `TR-A2A-DRIFT`.

---

## 3. Conforming surface

The following A2A primitives are adopted verbatim. TAP's wire format expresses them through TAP's JSON-RPC envelope, but the semantics are A2A's.

### 3.1 Agent identity model `[verify]`

A2A defines an `Agent` as a discoverable, addressable entity with stable identity. TAP's `agent_id` (per [`../protocol/SPEC.md`](../protocol/SPEC.md) §4.2) is consistent with this model: ephemeral per session, but bound to a stable developer identity. The relay's discovery surface MAPS as follows:

| A2A concept | TAP concept | Notes |
|---|---|---|
| Agent identifier | `agent_id` | Same role; TAP's derivation is more specific. |
| Agent capabilities | `capabilities` field on `agent.register` | Same role. |
| Agent endpoint | (relay-managed) | TAP does not expose direct agent-to-agent endpoints; routing goes through the relay. See §5.1. |

### 3.2 Discovery `[verify]`

TAP's `state.query` and the future agent-discovery method (Phase 4 follow-up) MAP to A2A's discovery API.

### 3.3 Capability advertisement `[verify]`

TAP's `agent.register.capabilities[]` field uses A2A capability strings where they exist for a behavior TAP supports. TAP-specific capabilities are namespaced `tap.<category>.<feature>`.

---

## 4. Extending surface

TAP introduces concepts A2A does not specify. These are TAP-original and do not interoperate with A2A peers.

| TAP concept | Why outside A2A | Reference |
|---|---|---|
| Cross-developer awareness state | A2A is agent-pair oriented; TAP awareness is team-scoped. | [`../project-context.md` §3](../project-context.md#3-system-overview), [`../protocol/SPEC.md`](../protocol/SPEC.md) §7 |
| Conflict detection | Development-domain primitive; not a generic agent-protocol concern. | [`../project-context.md` §7](../project-context.md#7-conflict-detection-engine), [`../protocol/SPEC.md`](../protocol/SPEC.md) §8 |
| Consults | A2A messages are one-shot or RPC-style; TAP consults are stateful, multi-turn, multi-party with lifecycle. | [`../project-context.md` §6.3](../project-context.md#63-message-taxonomy), Phase 4 |
| Trust pairs | Per-developer-pair directional trust state with signed mutations. | [`../project-context.md` §6.2](../project-context.md#62-identity), Phase 4 |
| Scopes | Five-value privilege ladder bound to messages and consults. | [`GLOSSARY.md`](GLOSSARY.md), Phase 4 |
| Approval gates | Human-in-the-loop primitive bound to scope. | [`../protocol/SPEC.md`](../protocol/SPEC.md) §12, Phase 4 |
| Policy DSL | Per-repo and per-user policy with rate limits, redaction, auto-accept. | Phase 4 |
| Audit chain | Cryptographically chained audit log over all TAP messages. | [`../project-context.md` §2](../project-context.md#2-locked-architectural-decisions), [`THREAT_MODEL.md`](THREAT_MODEL.md) §4.3 |
| Sandboxing rule | Inbound message content is never prepended into a peer's prompt. | [`THREAT_MODEL.md`](THREAT_MODEL.md) §5 |

A2A peers without TAP support do not see, request, or interfere with the extending surface. Conversely, TAP peers SHOULD NOT assume A2A peers can interoperate at the extending surface.

---

## 5. Deviating surface

Areas where TAP's needs require behavior that differs from A2A. Every deviation MUST be justified.

### 5.1 No direct agent-to-agent endpoints

A2A allows direct agent-to-agent communication. TAP routes all cross-developer agent traffic through the relay.

**Rationale.** TAP's security model depends on the relay enforcing policy, scope, and audit. Direct endpoints would bypass the audit chain, the trust graph, and the sandboxing requirement. Cross-developer reachability without the relay is out of scope for v0.1.

**Compatibility note.** A TAP-native agent never opens a direct WS connection to a peer agent. It addresses the peer via the relay using the peer's `agent_id` or developer ID.

### 5.2 Mandatory mTLS

A2A's transport requirements `[verify]` are weaker than TAP's. TAP's daemon ↔ relay link MUST use mTLS with daemon-side pinned CA per [`../project-context.md` §2](../project-context.md#2-locked-architectural-decisions).

**Rationale.** Source code in transit is high-value. System-trust fallback is a known privilege-escalation surface. The decision is locked.

### 5.3 Versioning

A2A's versioning model `[verify]` is not adopted. TAP versions independently per [`VERSIONING.md`](VERSIONING.md).

**Rationale.** TAP's release cadence and breaking-change policy are scoped to the TAP project. Coupling versioning would introduce external blocking dependencies.

### 5.4 Sandboxing rule

A2A does not specify how a receiving agent ingests inbound message content. TAP requires the structured-envelope sandboxing rule per [`THREAT_MODEL.md`](THREAT_MODEL.md) §5.

**Rationale.** Cross-developer prompt injection is the highest-impact threat in TAP's threat model. The rule is mandatory and non-negotiable.

---

## 6. Per-message mapping table

> **Status:** placeholder. The detailed per-message mapping is filled in once the conforming surface is verified against the current A2A spec. Until then, the table above (§3, §4, §5) is the binding mapping at the conceptual level.

When complete, this section will list every TAP method (per [`../protocol/SPEC.md`](../protocol/SPEC.md) §6.3) and one of:

- `conforming` — semantically identical to a named A2A method.
- `extending` — TAP-original, no A2A counterpart.
- `deviating` — semantically related to an A2A method but differs; cross-link to §5.

---

## 7. Open questions

- **A2A spec versioning.** Which version of A2A does TAP claim conformance with? Pinned in front-matter once verified.
- **Discovery wire format.** Does TAP's `state.query` actually conform to A2A's discovery API, or is a separate `discover.*` method needed?
- **Capability namespace.** Does A2A reserve a namespace for vendor extensions? If yes, TAP's `tap.*` capabilities should sit inside it.
- **Relay-as-gateway model.** A2A may or may not have a notion of trusted intermediaries. Confirm.
- **Identity attestation.** A2A may require signed identity attestations. TAP currently uses relay-issued JWTs; if A2A specifies a different attestation format, decide whether to add a translation layer at the relay edge.

---

## 8. References

- [Google Agent2Agent Protocol (A2A)](https://github.com/google-a2a/A2A) — the upstream specification.
- [`../project-context.md` §1.3](../project-context.md#13-positioning) — TAP positioning claim.
- [`../protocol/SPEC.md`](../protocol/SPEC.md) — TAP wire format.
- [`VERSIONING.md`](VERSIONING.md) — TAP version policy.
- [`THREAT_MODEL.md`](THREAT_MODEL.md) — security model TAP imposes regardless of A2A.
- [`RISK_REGISTER.md`](RISK_REGISTER.md) — A2A-drift risk tracking.
