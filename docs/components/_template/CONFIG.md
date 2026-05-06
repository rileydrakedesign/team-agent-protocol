---
status: draft
phase: N
owners: ["@your-github-handle"]
last-reviewed: YYYY-MM-DD
component: <component-name>
---

# `<component>` — Configuration Reference

The complete configuration surface. Every key, every default, every validation rule. Generated where possible from the schema.

If a configuration knob exists, it is documented here. Anything else is a bug.

---

## 1. Configuration sources, in order of precedence

Highest precedence first; later sources override earlier.

1. Command-line flags.
2. Environment variables.
3. Per-repo config (`<repo>/.tap/<file>`), where applicable.
4. User-global config (`~/.tap/<file>`).
5. Compiled-in defaults.

## 2. File locations

| File | Purpose | Owner |
| ---- | ------- | ----- |
| …    | …       | …     |

## 3. Configuration reference

For every key:

```
[section.subsection]
key = default_value      # type — short description
                         # constraints, validation
                         # source (flag / env / file)
```

### 3.1 `[section]`

| Key | Type | Default | Required | Description |
| --- | ---- | ------- | -------- | ----------- |
| …   | …    | …       | …        | …           |

### 3.2 `[other_section]`

…

## 4. Environment variables

| Variable | Maps to         | Notes |
| -------- | --------------- | ----- |
| `TAP_…`  | `[section].key` | …     |

## 5. Command-line flags

| Flag  | Maps to         | Notes |
| ----- | --------------- | ----- |
| `--…` | `[section].key` | …     |

## 6. Validation

What happens when configuration fails to validate. Components MUST refuse to start with an invalid config rather than silently fall back to defaults.

## 7. Reload semantics

For each section: hot-reloadable, restart-required, or operator-coordinated.

| Section | Reload class |
| ------- | ------------ |
| …       | …            |

## 8. Migrations

When a configuration key changes, the migration path. Cross-link to `phases/phase-N/migration.md`.

## 9. Examples

Minimal valid config:

```toml
…
```

Production-grade config with non-defaults:

```toml
…
```

## 10. Related

- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`OPERATING.md`](OPERATING.md)
- [`SECURITY.md`](SECURITY.md)
