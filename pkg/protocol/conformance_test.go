// SPDX-License-Identifier: Apache-2.0

package protocol

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
	"testing"

	"github.com/santhosh-tekuri/jsonschema/v6"
)

// Conformance test runner — Go.
//
// Loads every fixture in protocol/conformance/fixtures/ and validates each
// fixture's `data` against the JSON Schema named by `schema_ref`. Schema docs
// live in protocol/schemas/_generated/<file>.json and are produced by
// tools/codegen/generate.sh.
//
// Implements the runner contract specified in docs/CONFORMANCE.md §4: emits
// the §4.1 JSON output (to stdout, and to $TAP_CONFORMANCE_REPORT if set) and
// fails the test (exit 1) if any fixture mismatch occurs.
//
// Fixture format documented in protocol/conformance/README.md.

type fixture struct {
	Name              string `json:"name"`
	Description       string `json:"description"`
	SchemaRef         string `json:"schema_ref"`
	Data              any    `json:"data"`
	ExpectedValid     bool   `json:"expected_valid"`
	ExpectedRoundTrip *bool  `json:"expected_round_trip,omitempty"`
	ExpectedErrorCode *int   `json:"expected_error_code,omitempty"`
}

func (f fixture) roundTrip() bool {
	if f.ExpectedRoundTrip == nil {
		return true
	}
	return *f.ExpectedRoundTrip
}

type fixtureFailure struct {
	FixturePath string `json:"fixture_path"`
	Expected    string `json:"expected"`
	Actual      string `json:"actual"`
	Message     string `json:"message"`
}

type report struct {
	TAPVersionTarget string           `json:"tap_version_target"`
	SuiteVersion     string           `json:"suite_version"`
	FixturesTotal    int              `json:"fixtures_total"`
	FixturesPassed   int              `json:"fixtures_passed"`
	FixturesFailed   int              `json:"fixtures_failed"`
	FixturesSkipped  int              `json:"fixtures_skipped"`
	Failures         []fixtureFailure `json:"failures"`
}

// Resolution order for each path:
//   1. Explicit TAP_CONFORMANCE_* env var.
//   2. Bazel runfiles (TEST_SRCDIR is set automatically for `bazel test`;
//      _main is the workspace name under bzlmod).
//   3. Repo-relative path (works for `go test` from within pkg/protocol).

func bazelRunfilesRoot() string {
	if p := os.Getenv("TEST_SRCDIR"); p != "" {
		return filepath.Join(p, "_main")
	}
	return ""
}

func fixturesRoot() string {
	if p := os.Getenv("TAP_CONFORMANCE_FIXTURES"); p != "" {
		return p
	}
	if rf := bazelRunfilesRoot(); rf != "" {
		return filepath.Join(rf, "protocol", "conformance", "fixtures")
	}
	return filepath.Join("..", "..", "protocol", "conformance", "fixtures")
}

func schemasDocPath() string {
	if p := os.Getenv("TAP_CONFORMANCE_SCHEMAS"); p != "" {
		return p
	}
	if rf := bazelRunfilesRoot(); rf != "" {
		return filepath.Join(rf, "protocol", "schemas", "_generated", "all.json")
	}
	return filepath.Join("..", "..", "protocol", "schemas", "_generated", "all.json")
}

func suiteVersion() string {
	var path string
	if p := os.Getenv("TAP_CONFORMANCE_VERSION_FILE"); p != "" {
		path = p
	} else if rf := bazelRunfilesRoot(); rf != "" {
		path = filepath.Join(rf, "protocol", "conformance", "VERSION")
	} else {
		path = filepath.Join("..", "..", "protocol", "conformance", "VERSION")
	}
	if b, err := os.ReadFile(path); err == nil {
		return strings.TrimSpace(string(b))
	}
	return "0.0.0"
}

type fixtureItem struct {
	path string
	fx   fixture
}

func loadFixturesGo(t *testing.T, root string) []fixtureItem {
	t.Helper()
	var out []fixtureItem
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || filepath.Ext(path) != ".json" {
			return nil
		}
		bytes, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		var f fixture
		if err := json.Unmarshal(bytes, &f); err != nil {
			t.Fatalf("parse %s: %v", path, err)
		}
		out = append(out, fixtureItem{path, f})
		return nil
	})
	if err != nil {
		t.Fatalf("walk %s: %v", root, err)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].path < out[j].path })
	return out
}

// loadSchemaDoc reads the single combined JSON Schema document. Returns nil
// if it doesn't exist yet (e.g., before the first codegen run).
func loadSchemaDoc(t *testing.T, path string) any {
	t.Helper()
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return nil
	}
	bytes, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	var v any
	if err := json.Unmarshal(bytes, &v); err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
	return v
}

// extractDefinition looks up `$defs[defName]` in the combined schema and
// injects the parent `$defs` so nested `$ref`s resolve. The codegen pipeline
// normalizes CUE's `#Foo` keys to plain `Foo`.
func extractDefinition(schemaDoc any, defName string) (any, bool) {
	doc, ok := schemaDoc.(map[string]any)
	if !ok {
		return nil, false
	}
	defs, ok := doc["$defs"].(map[string]any)
	if !ok {
		return nil, false
	}
	subAny, ok := defs[defName]
	if !ok {
		return nil, false
	}
	sub, ok := subAny.(map[string]any)
	if !ok {
		return nil, false
	}
	clone := map[string]any{}
	for k, v := range sub {
		clone[k] = v
	}
	clone["$defs"] = defs
	return clone, true
}

func TestConformanceSuite(t *testing.T) {
	fixtures := loadFixturesGo(t, fixturesRoot())
	schemaDoc := loadSchemaDoc(t, schemasDocPath())

	rep := report{
		TAPVersionTarget: TAPVersion,
		SuiteVersion:     suiteVersion(),
		FixturesTotal:    len(fixtures),
		Failures:         []fixtureFailure{},
	}

	for _, item := range fixtures {
		path := item.path
		fx := item.fx

		hashIdx := strings.Index(fx.SchemaRef, "#")
		if hashIdx < 1 {
			rep.Failures = append(rep.Failures, fixtureFailure{
				FixturePath: path,
				Expected:    "schema_ref = file#Definition",
				Actual:      fx.SchemaRef,
				Message:     "schema_ref missing '#' separator",
			})
			rep.FixturesFailed++
			continue
		}
		file := fx.SchemaRef[:hashIdx]
		def := fx.SchemaRef[hashIdx+1:]

		if schemaDoc == nil {
			// Generated schema not present yet; skip rather than fail the suite.
			rep.FixturesSkipped++
			continue
		}

		sub, ok := extractDefinition(schemaDoc, def)
		if !ok {
			rep.Failures = append(rep.Failures, fixtureFailure{
				FixturePath: path,
				Expected:    fmt.Sprintf("definition %s present in $defs", def),
				Actual:      "not found",
				Message:     fmt.Sprintf("schema_ref %s cannot be resolved", fx.SchemaRef),
			})
			rep.FixturesFailed++
			continue
		}
		_ = file

		c := jsonschema.NewCompiler()
		uri := fmt.Sprintf("inline:///%s/%s", file, def)
		if err := c.AddResource(uri, sub); err != nil {
			rep.Failures = append(rep.Failures, fixtureFailure{
				FixturePath: path,
				Expected:    "schema adds to compiler",
				Actual:      err.Error(),
				Message:     "JSON Schema add-resource failed",
			})
			rep.FixturesFailed++
			continue
		}
		sch, err := c.Compile(uri)
		if err != nil {
			rep.Failures = append(rep.Failures, fixtureFailure{
				FixturePath: path,
				Expected:    "schema compiles",
				Actual:      err.Error(),
				Message:     "JSON Schema compile failed",
			})
			rep.FixturesFailed++
			continue
		}

		validateErr := sch.Validate(fx.Data)
		actualValid := validateErr == nil

		if actualValid != fx.ExpectedValid {
			rep.Failures = append(rep.Failures, fixtureFailure{
				FixturePath: path,
				Expected:    fmt.Sprintf("expected_valid = %v", fx.ExpectedValid),
				Actual:      fmt.Sprintf("actual_valid = %v", actualValid),
				Message:     fmt.Sprintf("validation outcome mismatch for %s: %s", fx.Name, fx.Description),
			})
			rep.FixturesFailed++
			continue
		}

		// Round-trip check on positive fixtures.
		if fx.ExpectedValid && fx.roundTrip() {
			serialized, err := json.Marshal(fx.Data)
			if err != nil {
				rep.Failures = append(rep.Failures, fixtureFailure{
					FixturePath: path,
					Expected:    "round-trip serialize",
					Actual:      err.Error(),
					Message:     "serialize failed",
				})
				rep.FixturesFailed++
				continue
			}
			var reparsed any
			if err := json.Unmarshal(serialized, &reparsed); err != nil {
				rep.Failures = append(rep.Failures, fixtureFailure{
					FixturePath: path,
					Expected:    "round-trip reparse",
					Actual:      err.Error(),
					Message:     "reparse failed",
				})
				rep.FixturesFailed++
				continue
			}
			if !reflect.DeepEqual(reparsed, fx.Data) {
				rep.Failures = append(rep.Failures, fixtureFailure{
					FixturePath: path,
					Expected:    "round-trip preserves value",
					Actual:      "value differs after re-serialize",
					Message:     fmt.Sprintf("round-trip mismatch in %s", fx.Name),
				})
				rep.FixturesFailed++
				continue
			}
		}

		// expected_error_code is informational at the runner layer in v0.1.
		_ = fx.ExpectedErrorCode

		rep.FixturesPassed++
	}

	out, err := json.MarshalIndent(rep, "", "  ")
	if err != nil {
		t.Fatalf("marshal report: %v", err)
	}
	fmt.Println(string(out))

	if p := os.Getenv("TAP_CONFORMANCE_REPORT"); p != "" {
		if err := os.WriteFile(p, out, 0o644); err != nil {
			t.Fatalf("write report %s: %v", p, err)
		}
	}

	if rep.FixturesFailed > 0 {
		t.Fatalf("%d fixture(s) failed; see JSON report above", rep.FixturesFailed)
	}
	if rep.FixturesTotal == 0 {
		t.Fatalf("expected at least one fixture under %s", fixturesRoot())
	}
}
