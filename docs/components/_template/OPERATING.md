---
status: draft
phase: N
owners: [@your-github-handle]
last-reviewed: YYYY-MM-DD
component: <component-name>
---

# `<component>` — Operating Guide

How to install, run, monitor, upgrade, and recover this component. Aimed at the operator on call.

---

## 1. Install

Per platform, the recommended installation path. Link to [`CONFIG.md`](CONFIG.md) for what to set after install.

| Platform | Path |
|---|---|
| macOS | `brew install ...` |
| Linux | `apt install ...` / `dnf install ...` |
| Windows | `scoop install ...` |
| From source | `bazel build //…:...` |

## 2. Verify

How to confirm the install is healthy.

- …

## 3. Run

How to start the component. Service-manager integration where applicable (launchd, systemd, Windows services).

- …

## 4. Monitor

Metrics and logs to watch. Reference dashboards (when they exist) and alert rules.

| Signal | Source | Alert threshold |
|---|---|---|
| … | … | … |

## 5. Upgrade

In-place upgrade procedure. Roll-back procedure. Cross-link to [`../../runbooks/`](../../runbooks/) when there is a dedicated runbook.

## 6. Backup & restore

If the component holds durable state, the backup procedure and the restore procedure.

## 7. Common operational tasks

Each task with a one-line description and a runbook reference.

- Add a developer: …
- Rotate a secret: …
- Rebuild a cache: …

## 8. Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| … | … | … |

## 9. Capacity planning

Resource consumption per scale unit. Limits to know about.

## 10. Disaster recovery

The procedure for catastrophic loss. Cross-link to [`../../runbooks/disaster-recovery.md`](../../runbooks/) (Phase 3+).

## 11. Related

- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`CONFIG.md`](CONFIG.md)
- [`SECURITY.md`](SECURITY.md)
- Runbooks: [`../../runbooks/`](../../runbooks/)
