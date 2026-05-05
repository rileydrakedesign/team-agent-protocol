# tap-protocol (Rust)

Rust bindings for the [TAP — Team Agent Protocol](https://github.com/tap-dev/tap).

```toml
[dependencies]
tap-protocol = "0.1.0-draft"
```

## What's in here

- Hand-written envelope helpers (version negotiation, error taxonomy).
- Conformance test runner that validates every fixture under `protocol/conformance/fixtures/` against the JSON Schema produced from `protocol/schemas/*.cue`. 46/46 passing as of 2026-05-04.
- A `generated/` module that will hold strongly-typed wire bindings once `cargo-typify` upstream supports the `allOf+not` patterns the TAP schemas emit. For Phase 1 the conformance runner uses JSON Schema validation directly, so generated types are not on the critical path.

## Status

Phase 1 draft. The wire format is not yet stable; this crate tracks `protocol/SPEC.md` v0.1.0-draft.

## Generated code

Files under `src/generated/` are produced by `tools/codegen/generate.sh`. Do not hand-edit. Schema changes go in `protocol/schemas/*.cue`; running the codegen driver refreshes this directory. See [`../../tools/codegen/README.md`](../../tools/codegen/README.md) for the pipeline overview.

## Running the conformance suite

```bash
cargo test --test conformance
```

Bazel doesn't yet wire `rules_rust` crate-universe, so Bazel-based testing of this crate is deferred to Phase 2. Use `cargo` directly until then.

## License

Apache 2.0. See the root `LICENSE` file.
