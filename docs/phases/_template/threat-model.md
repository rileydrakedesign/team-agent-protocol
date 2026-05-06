---
status: draft
phase: N
owners: ["@your-github-handle"]
last-reviewed: YYYY-MM-DD
---

# Phase N — Threat Model Addendum

This document is the phase-specific delta to [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md). It captures threats introduced, mitigated, or transferred by Phase N's deliverables.

The structure mirrors the project-wide threat model so additions can be folded back at phase exit.

---

## 1. New assets (if any)

Assets that were not previously in scope or were not at risk. For each asset: what it is, why it matters, where it lives.

- …

## 2. New trust boundaries (if any)

Boundaries introduced by this phase. Each boundary identifies the components on each side, the transport, and the authentication mechanism.

- …

## 3. New adversaries (if any)

Adversaries newly relevant to this phase.

| Adversary | Capability | Motivation |
| --------- | ---------- | ---------- |
| …         | …          | …          |

## 4. STRIDE delta

Threats introduced by this phase, by STRIDE category. Each row carries the threat and the control. Cross-link controls to the RFC, component, or test that enforces them.

### 4.1 Spoofing

| Threat | Control |
| ------ | ------- |
| …      | …       |

### 4.2 Tampering

| Threat | Control |
| ------ | ------- |
| …      | …       |

### 4.3 Repudiation

| Threat | Control |
| ------ | ------- |
| …      | …       |

### 4.4 Information disclosure

| Threat | Control |
| ------ | ------- |
| …      | …       |

### 4.5 Denial of service

| Threat | Control |
| ------ | ------- |
| …      | …       |

### 4.6 Elevation of privilege

| Threat | Control |
| ------ | ------- |
| …      | …       |

## 5. Resolved threats

Threats listed as open in [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §8 that this phase closes. Each entry cites the original line and the resolution.

- …

## 6. Required tests

- Conformance fixtures added by this phase that exercise the controls above.
- Negative tests in `<component>/tests/security/`.

## 7. Open issues

Threats identified during this phase but not addressed within it. These move into [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md) §8 (Open issues) at phase exit.

- …

## 8. Pen-test scope (if applicable)

If this phase triggers an external pen-test (Phase 4 ship criterion), this section lists the scope, exclusions, and methodology. Otherwise: "N/A — no pen-test in this phase."

## 9. References

- [`../../THREAT_MODEL.md`](../../THREAT_MODEL.md)
- [`../../RISK_REGISTER.md`](../../RISK_REGISTER.md)
- Phase RFCs that introduce new attack surfaces.
