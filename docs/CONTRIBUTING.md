# Contributing to TAP

Thank you for your interest in TAP. This document covers the development workflow; see [`GOVERNANCE.md`](GOVERNANCE.md) for how decisions are made and [`SECURITY.md`](SECURITY.md) for vulnerability disclosure.

## Before you start

- Read sections 1, 2, and 9 of [`project-context.md`](../project-context.md). Section 2 lists architectural decisions that are locked and not up for casual revisitation.
- The protocol specification is the source of truth for wire format. Code generation flows from CUE schemas — do not hand-edit files under `**/generated/`.
- Conformance tests gate every protocol change. Update fixtures in `protocol/conformance/` *before* the spec change lands.

## Development setup

TAP uses [Bazel](https://bazel.build) with [bzlmod](https://bazel.build/external/module) as the top-level build system. The other toolchains (Rust, Go, Node, CUE) are managed by Bazel.

```bash
# Install Bazelisk (it reads .bazelversion and downloads the right Bazel)
brew install bazelisk           # macOS
go install github.com/bazelbuild/bazelisk@latest   # any platform with Go

# Install pre-commit hooks
pip install pre-commit
pre-commit install --install-hooks
pre-commit install --hook-type commit-msg

# Build everything
bazel build //...

# Run all tests, including the protocol conformance suite
bazel test //...
```

For local development outside Bazel (IDE integration, native cargo / go / pnpm workflows), each language directory has its own native workspace file. Bazel remains the source of truth for CI.

## Workflow

1. Open an issue describing the change before writing code, unless it's a trivial fix.
2. Branch from `main`. Branch names: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, `chore/<topic>`.
3. Make changes. If you change a CUE schema, regenerate bindings (`bazel run //tools/codegen:generate`) and commit the regenerated files.
4. Add or update conformance fixtures for protocol-level changes.
5. Run `bazel test //...` and ensure pre-commit passes.
6. Open a pull request. Fill in the template.
7. PRs require one approving review and passing CI before merge.

## Commit messages

This project follows [Conventional Commits](https://www.conventionalcommits.org/) v1.0.0. The `commitlint` pre-commit hook enforces this.

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Scope examples: `protocol`, `daemon`, `relay-edge`, `claude-code-adapter`, `codegen`.

Breaking changes use `!` after the type/scope and a `BREAKING CHANGE:` footer.

## Signing commits

`main` requires signed commits. Configure git to sign with your GPG or SSH key:

```bash
git config --global commit.gpgsign true
# or for SSH signing:
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

## Code style

- **Rust:** `rustfmt` (default config) + `clippy -D warnings`. MSRV pinned in `MODULE.bazel`.
- **Go:** `gofmt` + `go vet`. Module path: `github.com/tap-dev/tap`.
- **TypeScript:** `prettier` + `eslint`. Strict mode required.
- **CUE:** `cue fmt`.
- **Bazel:** `buildifier`.

Pre-commit runs all formatters; CI verifies they leave no diff.

## Adding a protocol message type

1. Add the schema in `protocol/schemas/<message>.cue`.
2. Update `protocol/SPEC.md` with the message description, semantics, and lifecycle.
3. Add conformance fixtures in `protocol/conformance/<message>/`.
4. Run `bazel run //tools/codegen:generate` to regenerate bindings.
5. Update per-language envelope helpers if needed.
6. Run `bazel test //...` — all three language conformance suites must pass.

## License header

Every source file (Rust, Go, TS, CUE, Bazel, shell, Python) must carry an SPDX license header. The `addlicense` pre-commit hook enforces this.

```
# SPDX-License-Identifier: Apache-2.0   (most files)
# SPDX-License-Identifier: BUSL-1.1     (relay-tier files only, Phase 3+)
```

## Where to ask questions

- **Bug or feature request:** open an issue.
- **Security:** see [`SECURITY.md`](SECURITY.md). Do not file public issues for vulnerabilities.
- **Protocol design discussion:** open a discussion or join the protocol working group (forthcoming).
