# tap-protocol (Rust)

Rust bindings for the [TAP — Team Agent Protocol](https://github.com/tap-dev/tap).

```toml
[dependencies]
tap-protocol = "0.1.0-draft"
```

## What's in here

- Generated wire types from `protocol/schemas/*.cue` (under `src/generated/`).
- Hand-written envelope helpers (version negotiation, error taxonomy).
- Round-trip serializers backed by `serde` + `serde_json`.

## Status

Phase 1 draft. The wire format is not yet stable; this crate tracks `protocol/SPEC.md` v0.1.0-draft.

## Generated code

Files under `src/generated/` are produced by `tools/codegen/generate.sh`. Do not hand-edit. Schema changes go in `protocol/schemas/*.cue`; running the codegen driver updates this directory.

## License

Apache 2.0. See the root `LICENSE` file.
