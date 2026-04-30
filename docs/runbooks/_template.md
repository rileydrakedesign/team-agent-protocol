---
status: draft
phase: N
owners: [@your-github-handle]
last-reviewed: YYYY-MM-DD
runbook_id: RB-NNN
component: <daemon | relay | dashboard | ...>
severity: routine | elevated | incident
---

# Runbook — Title

> **How to use this template.** Copy `docs/runbooks/_template.md` to `docs/runbooks/<short-slug>.md`. Fill in front-matter (especially `runbook_id`, `component`, `severity`) and every required section. Runbooks are short, scannable, action-oriented; if you need to explain *why*, link to the relevant RFC or component doc.

This runbook covers the procedure for: **<one-sentence purpose>**.

---

## 1. When to use this runbook

The trigger condition. Concrete, observable, paged-able.

> Example: "Awareness propagation P95 alert fires for ≥ 5 minutes" or "Operator wants to deploy a new daemon release to staging."

## 2. Severity & impact

- **Severity:** routine / elevated / incident.
- **Customer impact:** what users see during execution.
- **Internal impact:** what the team experiences (paging, on-call hours).

## 3. Prerequisites

What must be true before starting.

- Access: …
- Tools: …
- Approvals: …

## 4. Procedure

Numbered, executable steps. Each step is a single action with a verifiable outcome.

1. **Step.** Action. Expected outcome. Where to verify.
2. **Step.** …
3. …

If a step fails, jump to §6 (Rollback) or §7 (Escalation).

## 5. Verification

How to confirm the procedure succeeded. Each check is a concrete signal an operator can read.

- Check 1: …
- Check 2: …

## 6. Rollback

If the procedure fails part-way, how to return to the prior state. State whether rollback is automatic, manual, or unavailable.

1. …
2. …

## 7. Escalation

When to escalate, to whom, with what evidence.

- After step N fails.
- If verification fails after step M.
- Contact: @handle (primary), @handle (secondary). Page via …

## 8. Post-execution

What to do after the procedure completes successfully.

- Update incident channel / status page.
- Record outcome in [`../phases/phase-N/decisions.md`](../phases/) or post-mortem template if applicable.
- Bump `last-reviewed` on this runbook.

## 9. Related

- Component docs: [`../components/<component>/`](../components/)
- RFCs: …
- Related runbooks: …

## 10. Change history

A short list of substantive changes to this runbook. Format: `YYYY-MM-DD — change — @handle`.

- YYYY-MM-DD — created — @handle
