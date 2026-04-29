# TAP — Team Agent Protocol

> A protocol and platform for cross-developer AI agent coordination, conflict prevention, and bilateral consults during active development.

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Status: Phase 1 — Protocol & foundations](https://img.shields.io/badge/status-phase%201-yellow)](project-context.md#9-working-state)

TAP is two products fused:

1. **Cross-developer awareness and conflict prevention** — a real-time map of who is touching what across the team, with file-level, hunk-level, and semantic conflict detection delivered to agents *before* they write.
2. **Agent-to-agent consults** — a first-class primitive for one developer's agent to open a stateful, contextual conversation with another developer's agent, with full security, audit, and human-oversight guarantees.

TAP is editor-agnostic (works with any agent that speaks MCP), conformant with Google A2A for identity and discovery, and aspires to be the IETF-track protocol for team-scoped agent collaboration.

## Status

Phase 1 — Protocol & foundations. The wire format, schemas, conformance suite, and threat model are being drafted. Nothing is shippable yet.

The full project plan and locked architectural decisions live in [`project-context.md`](project-context.md).

## Repository layout

```
protocol/        Wire-protocol spec, CUE schemas, conformance fixtures
crates/          Rust components (tap-protocol, tap-daemon, tap-cli)
pkg/             Go components (protocol bindings, relay tiers)
packages/        TypeScript components (protocol bindings, web)
adapters/        Editor adapters (Claude Code, Cursor, Codex, Aider) — Phase 2+
tools/codegen/   CUE → JSON Schema → Rust/Go/TS bindings
docs/            Architecture, threat model, contributing, governance
.github/         CI workflows, issue/PR templates
```

## Building

TAP uses [Bazel](https://bazel.build) with [bzlmod](https://bazel.build/external/module) as the top-level build system. Install Bazelisk and the rest of the toolchain follows automatically:

```bash
brew install bazelisk          # macOS
# or: go install github.com/bazelbuild/bazelisk@latest

bazel build //...
bazel test //...
```

The pinned Bazel version lives in [`.bazelversion`](.bazelversion); Bazelisk reads it.

## Contributing

See [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) for development workflow, [`docs/GOVERNANCE.md`](docs/GOVERNANCE.md) for project governance, and [`docs/SECURITY.md`](docs/SECURITY.md) for vulnerability disclosure.

## License

Apache 2.0 for the protocol, daemon, SDKs, and adapters. The hosted relay tier (forthcoming in Phase 3) will be Business Source License 1.1 with a 4-year conversion to Apache 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
