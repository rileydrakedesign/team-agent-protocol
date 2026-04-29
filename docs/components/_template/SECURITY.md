---
status: draft
phase: N
owners: [@your-github-handle]
last-reviewed: YYYY-MM-DD
component: <component-name>
---

# `<component>` — Security Posture

Component-specific security posture. The project-wide threat model is at [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md); the per-phase delta is at `../../phases/phase-N/threat-model.md`. This document is the engineering-facing reference for the operator and the implementer of `<component>`.

---

## 1. Trust boundaries

Boundaries the component sits across, with the auth and integrity controls at each.

| Boundary | Other side | Auth | Integrity | Confidentiality |
|---|---|---|---|---|
| … | … | … | … | … |

## 2. Sensitive data

Data the component handles that has elevated sensitivity. For each: storage, transit, retention, access control.

| Data | At rest | In transit | Retention | Access |
|---|---|---|---|---|
| … | … | … | … | … |

## 3. Cryptographic primitives used

Which primitives, where. Cross-link to [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §7.

| Use | Primitive | Library |
|---|---|---|
| … | … | … |

## 4. Authentication

How the component authenticates inbound requests, and how it authenticates itself outbound.

## 5. Authorization

What the component checks before honoring a request. Where policy is evaluated. What is logged.

## 6. Logging & redaction

What the component logs at each level. Field-level redaction policy. PII handling.

## 7. Common vulnerability classes addressed

For relevant OWASP-style classes, what mitigation the component applies. SQL injection, command injection, prompt injection, deserialization, SSRF, path traversal, etc.

## 8. Sandboxing (if applicable)

If the component handles inbound agent message content, the implementation of the structured-envelope sandboxing rule per [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §5. Concretely: how content reaches the LLM (or how it does not).

## 9. Supply chain

Which third-party libraries and tools this component depends on. Pinning, audit, SBOM.

## 10. Operational security

Secret rotation cadence. Audit log integration. Backup encryption.

## 11. Known residual risks

Risks not fully mitigated by this component, with cross-link to [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md).

## 12. Disclosure

If a vulnerability is found in this component, the disclosure path. Defer to [`../../SECURITY.md`](../../SECURITY.md).

## 13. Related

- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`INTERFACES.md`](INTERFACES.md)
- [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md)
- [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md)
