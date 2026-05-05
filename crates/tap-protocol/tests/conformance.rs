// SPDX-License-Identifier: Apache-2.0
//
// Conformance test runner — Rust.
//
// Loads every fixture in protocol/conformance/fixtures/ and validates each
// fixture's `data` against the JSON Schema named by `schema_ref`. Schema docs
// live in protocol/schemas/_generated/<file>.json and are produced by
// tools/codegen/generate.sh.
//
// Implements the runner contract specified in docs/CONFORMANCE.md §4: emits
// the §4.1 JSON output (to stdout, and to $TAP_CONFORMANCE_REPORT if set) and
// asserts at the end so cargo's exit code reflects pass/fail per §4.2 (0 on
// full pass, 1 on any failure; cargo handles 2 on runner panic automatically).
//
// Fixture format documented in protocol/conformance/README.md.

use std::fs;
use std::path::{Path, PathBuf};

use serde::Deserialize;
use serde_json::{json, Value};

#[derive(Debug, Deserialize)]
struct Fixture {
    name: String,
    description: String,
    schema_ref: String,
    data: Value,
    expected_valid: bool,
    #[serde(default = "default_round_trip")]
    expected_round_trip: bool,
    #[serde(default)]
    expected_error_code: Option<i64>,
}

fn default_round_trip() -> bool {
    true
}

// Resolution order for each path:
//   1. Explicit TAP_CONFORMANCE_* env var.
//   2. Bazel runfiles (TEST_SRCDIR is set automatically for `bazel test`;
//      _main is the workspace name under bzlmod).
//   3. cargo's CARGO_MANIFEST_DIR + repo-relative path.

fn bazel_runfiles_root() -> Option<PathBuf> {
    std::env::var("TEST_SRCDIR").ok().map(|s| PathBuf::from(s).join("_main"))
}

fn fixtures_root() -> PathBuf {
    if let Ok(p) = std::env::var("TAP_CONFORMANCE_FIXTURES") {
        return PathBuf::from(p);
    }
    if let Some(rf) = bazel_runfiles_root() {
        return rf.join("protocol/conformance/fixtures");
    }
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../protocol/conformance/fixtures")
}

fn schemas_doc_path() -> PathBuf {
    if let Ok(p) = std::env::var("TAP_CONFORMANCE_SCHEMAS") {
        return PathBuf::from(p);
    }
    if let Some(rf) = bazel_runfiles_root() {
        return rf.join("protocol/schemas/_generated/all.json");
    }
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../protocol/schemas/_generated/all.json")
}

fn suite_version() -> String {
    let path = if let Ok(p) = std::env::var("TAP_CONFORMANCE_VERSION_FILE") {
        PathBuf::from(p)
    } else if let Some(rf) = bazel_runfiles_root() {
        rf.join("protocol/conformance/VERSION")
    } else {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../protocol/conformance/VERSION")
    };
    fs::read_to_string(path)
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|_| "0.0.0".to_string())
}

fn load_fixtures(root: &Path) -> Vec<(PathBuf, Fixture)> {
    let mut out = Vec::new();
    walk(root, &mut out);
    out.sort_by(|a, b| a.0.cmp(&b.0));
    out
}

fn walk(dir: &Path, out: &mut Vec<(PathBuf, Fixture)>) {
    for entry in fs::read_dir(dir).unwrap_or_else(|e| panic!("read_dir {dir:?}: {e}")) {
        let entry = entry.expect("dir entry");
        let path = entry.path();
        if path.is_dir() {
            walk(&path, out);
        } else if path.extension().and_then(|s| s.to_str()) == Some("json") {
            // Skip fixtures explicitly authored as raw bytes if any appear later;
            // for now every fixture is a JSON object.
            let bytes = fs::read(&path).expect("read fixture");
            let fixture: Fixture = serde_json::from_slice(&bytes)
                .unwrap_or_else(|e| panic!("parse {path:?}: {e}"));
            out.push((path, fixture));
        }
    }
}

/// Load the single combined JSON Schema document. Returns None if it doesn't
/// exist yet (e.g., before the first codegen run); the suite then skips
/// validation and reports `fixtures_skipped` for every fixture.
fn load_schema_doc(path: &Path) -> Option<Value> {
    if !path.exists() {
        return None;
    }
    let bytes = fs::read(path).expect("read schema doc");
    Some(serde_json::from_slice(&bytes).unwrap_or_else(|e| panic!("parse {path:?}: {e}")))
}

/// Look up `$defs[def_name]` in the combined schema; return that sub-schema
/// with the parent `$defs` injected so nested `$ref`s resolve. The codegen
/// pipeline normalizes CUE's `#Foo` keys to plain `Foo`.
fn extract_definition(schema_doc: &Value, def_name: &str) -> Option<Value> {
    let mut sub = schema_doc.get("$defs").and_then(|d| d.get(def_name)).cloned()?;
    if let Value::Object(map) = &mut sub {
        if let Some(defs) = schema_doc.get("$defs") {
            map.insert("$defs".into(), defs.clone());
        }
    }
    Some(sub)
}

#[derive(Debug)]
struct FixtureFailure {
    fixture_path: String,
    expected: String,
    actual: String,
    message: String,
}

#[test]
fn run_conformance_suite() {
    let fixtures = load_fixtures(&fixtures_root());
    let schema_doc = load_schema_doc(&schemas_doc_path());

    let total = fixtures.len();
    let mut passed = 0usize;
    let mut failed = 0usize;
    let mut skipped = 0usize;
    let mut failures: Vec<FixtureFailure> = Vec::new();

    for (path, fx) in &fixtures {
        let (_file, def) = match fx.schema_ref.split_once('#') {
            Some(parts) => parts,
            None => {
                failures.push(FixtureFailure {
                    fixture_path: path.display().to_string(),
                    expected: format!("schema_ref = file#Definition"),
                    actual: fx.schema_ref.clone(),
                    message: "schema_ref missing '#' separator".into(),
                });
                failed += 1;
                continue;
            }
        };

        let schema_doc = match &schema_doc {
            Some(s) => s,
            None => {
                // Generated schema not yet present (e.g., before first codegen run).
                skipped += 1;
                continue;
            }
        };

        let sub = match extract_definition(schema_doc, def) {
            Some(s) => s,
            None => {
                failures.push(FixtureFailure {
                    fixture_path: path.display().to_string(),
                    expected: format!("definition {def} present in $defs"),
                    actual: "not found".into(),
                    message: format!("schema_ref {} cannot be resolved", fx.schema_ref),
                });
                failed += 1;
                continue;
            }
        };

        // Force draft-2020-12 so $ref siblings (`properties`, `required`,
        // etc., applied alongside an inherited base schema via $ref) are
        // honored. Without this, jsonschema 0.17 falls back to draft-7 and
        // silently drops the derived constraints, accepting messages that
        // should be rejected.
        let compiled = match jsonschema::JSONSchema::options()
            .with_draft(jsonschema::Draft::Draft202012)
            .compile(&sub)
        {
            Ok(c) => c,
            Err(e) => {
                failures.push(FixtureFailure {
                    fixture_path: path.display().to_string(),
                    expected: "schema compiles".into(),
                    actual: format!("compile error: {e}"),
                    message: "JSON Schema compile failed".into(),
                });
                failed += 1;
                continue;
            }
        };

        let actual_valid = compiled.is_valid(&fx.data);

        if actual_valid != fx.expected_valid {
            // Collect concrete validation errors for diagnostics; the
            // truncated form goes into the report so failures are
            // actionable.
            let err_summary = if !actual_valid {
                let errs: Vec<String> = compiled
                    .validate(&fx.data)
                    .err()
                    .map(|it| {
                        it.take(3)
                            .map(|e| format!("{}: {}", e.instance_path, e))
                            .collect()
                    })
                    .unwrap_or_default();
                if errs.is_empty() {
                    String::new()
                } else {
                    format!(" — errors: {}", errs.join("; "))
                }
            } else {
                String::new()
            };

            failures.push(FixtureFailure {
                fixture_path: path.display().to_string(),
                expected: format!("expected_valid = {}", fx.expected_valid),
                actual: format!("actual_valid = {actual_valid}"),
                message: format!(
                    "validation outcome mismatch for {}: {}{}",
                    fx.name, fx.description, err_summary
                ),
            });
            failed += 1;
            continue;
        }

        // Round-trip check on positive fixtures.
        if fx.expected_valid && fx.expected_round_trip {
            let serialized = serde_json::to_string(&fx.data).unwrap();
            let reparsed: Value = serde_json::from_str(&serialized).unwrap();
            if reparsed != fx.data {
                failures.push(FixtureFailure {
                    fixture_path: path.display().to_string(),
                    expected: "round-trip preserves value".into(),
                    actual: "value differs after re-serialize".into(),
                    message: format!("round-trip mismatch in {}", fx.name),
                });
                failed += 1;
                continue;
            }
        }

        // expected_error_code is informational at the runner layer in v0.1:
        // we surface it in the JSON report but do not force a particular
        // validator-error → JSON-RPC code mapping. Phase 2 may tighten this.
        let _ = fx.expected_error_code;

        passed += 1;
    }

    let report = json!({
        "tap_version_target": tap_protocol::envelope::TAP_VERSION,
        "suite_version": suite_version(),
        "fixtures_total": total,
        "fixtures_passed": passed,
        "fixtures_failed": failed,
        "fixtures_skipped": skipped,
        "failures": failures.iter().map(|f| json!({
            "fixture_path": f.fixture_path,
            "expected": f.expected,
            "actual": f.actual,
            "message": f.message,
        })).collect::<Vec<_>>(),
    });

    let report_str = serde_json::to_string_pretty(&report).unwrap();
    println!("{report_str}");

    if let Ok(p) = std::env::var("TAP_CONFORMANCE_REPORT") {
        fs::write(&p, &report_str).unwrap_or_else(|e| panic!("write report {p}: {e}"));
    }

    assert_eq!(
        failed, 0,
        "{failed} fixture(s) failed; see JSON report above"
    );
    assert!(
        total > 0,
        "expected at least one fixture under {:?}",
        fixtures_root()
    );
}
