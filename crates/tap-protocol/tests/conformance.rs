// SPDX-License-Identifier: Apache-2.0
//
// Conformance test runner — Rust.
//
// Loads every fixture in protocol/conformance/fixtures/ and asserts the
// documented behavior. Runs as a normal `cargo test` and as a Bazel target.
//
// Fixture format documented in protocol/conformance/README.md.

use std::fs;
use std::path::{Path, PathBuf};

use serde::Deserialize;
use serde_json::Value;

#[derive(Debug, Deserialize)]
struct Fixture {
    name: String,
    #[serde(rename = "schema_ref")]
    _schema_ref: String,
    data: Value,
    expected_valid: bool,
    #[serde(default = "default_round_trip")]
    expected_round_trip: bool,
    #[serde(default)]
    _expected_error_code: Option<i64>,
}

fn default_round_trip() -> bool {
    true
}

fn fixtures_root() -> PathBuf {
    // Bazel runfiles path takes precedence; fall back to repo-relative for
    // direct `cargo test` runs.
    if let Ok(p) = std::env::var("TAP_CONFORMANCE_FIXTURES") {
        return PathBuf::from(p);
    }
    let crate_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    crate_dir.join("../../protocol/conformance/fixtures")
}

fn load_fixtures(root: &Path) -> Vec<(PathBuf, Fixture)> {
    let mut out = Vec::new();
    walk(root, &mut out);
    out
}

fn walk(dir: &Path, out: &mut Vec<(PathBuf, Fixture)>) {
    for entry in fs::read_dir(dir).unwrap_or_else(|e| panic!("read_dir {dir:?}: {e}")) {
        let entry = entry.expect("dir entry");
        let path = entry.path();
        if path.is_dir() {
            walk(&path, out);
        } else if path.extension().and_then(|s| s.to_str()) == Some("json") {
            let bytes = fs::read(&path).expect("read fixture");
            let fixture: Fixture = serde_json::from_slice(&bytes)
                .unwrap_or_else(|e| panic!("parse {path:?}: {e}"));
            out.push((path, fixture));
        }
    }
}

#[test]
fn fixture_corpus_loads() {
    let root = fixtures_root();
    let fixtures = load_fixtures(&root);
    assert!(
        !fixtures.is_empty(),
        "expected at least one fixture under {root:?}"
    );
}

#[test]
fn every_fixture_round_trips_when_expected() {
    let fixtures = load_fixtures(&fixtures_root());
    for (path, fixture) in fixtures {
        if !fixture.expected_valid || !fixture.expected_round_trip {
            continue;
        }
        // Round-trip through serde_json's generic Value to assert the
        // representation is stable. Once generated bindings exist, this is
        // replaced by per-schema typed parse/serialize.
        let serialized = serde_json::to_string(&fixture.data)
            .unwrap_or_else(|e| panic!("serialize {}: {e}", fixture.name));
        let reparsed: Value = serde_json::from_str(&serialized)
            .unwrap_or_else(|e| panic!("reparse {}: {e}", fixture.name));
        assert_eq!(
            reparsed, fixture.data,
            "round-trip mismatch in fixture {} at {path:?}",
            fixture.name
        );
    }
}

// TODO(phase-1): once codegen runs and generated/agent_register.rs exists,
// add per-schema strict-typing assertions: parse fixture.data as the type
// referenced by schema_ref and verify expected_valid.
