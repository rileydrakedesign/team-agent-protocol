---
status: draft
phase: N
owners: [@your-github-handle]
last-reviewed: YYYY-MM-DD
component: <component-name>
---

# `<component>` — Interfaces

The boundary contracts of `<component>`. Every external surface — the methods it exposes, the methods it calls, the data it reads or writes — is documented here.

If `<component>` exposes a wire-protocol surface, the canonical definition is in [`../../../protocol/SPEC.md`](../../../protocol/SPEC.md) and [`../../../protocol/schemas/`](../../../protocol/schemas/). This document is the component-side restatement: what `<component>` does with each method.

---

## 1. Exposed surfaces

Surfaces this component publishes for others to consume.

### 1.1 Wire-protocol surface (if applicable)

| Method | Direction | Schema | Notes |
|---|---|---|---|
| … | inbound / outbound | `protocol/schemas/...` | … |

### 1.2 Local IPC surface (if applicable)

For example, the daemon's Unix socket, the relay's admin API, the dashboard's HTTP API.

| Endpoint | Transport | Auth | Schema | Notes |
|---|---|---|---|---|
| … | … | … | … | … |

### 1.3 CLI surface (if applicable)

Cross-link to `docs/components/cli/REFERENCE.md` (when it exists). Do not duplicate.

## 2. Consumed surfaces

Other components or external systems this component depends on.

| Dependency | Surface | Failure behavior |
|---|---|---|
| … | … | … |

## 3. Data interfaces

Persistent stores read or written. For each: the schema, the access pattern, the consistency requirement.

| Store | Schema | Read / Write / Both | Consistency |
|---|---|---|---|
| … | … | … | … |

## 4. Event interfaces

Events produced or consumed (NATS subjects, webhooks, etc.).

| Channel | Direction | Payload schema |
|---|---|---|
| … | produce / consume | … |

## 5. Configuration interfaces

Cross-link to [`CONFIG.md`](CONFIG.md). Every consumer of this component's configuration is listed here.

## 6. Telemetry interfaces

Logs, metrics, traces. Cross-link to a per-component metrics catalog when present.

## 7. Versioning of interfaces

How each interface is versioned. Wire protocol per [`../../VERSIONING.md`](../../VERSIONING.md). Local APIs per their own component-level policy stated here.

## 8. Stability guarantees

Which interfaces are stable, which are unstable, which are private.

| Interface | Stability |
|---|---|
| … | stable / unstable / private |

## 9. Examples

Worked examples for the most-used surfaces. Schemas in fenced code blocks.

## 10. Related

- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`../../../protocol/SPEC.md`](../../../protocol/SPEC.md) (for wire-format surfaces)
- RFCs that define each surface
