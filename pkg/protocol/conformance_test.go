// SPDX-License-Identifier: Apache-2.0

package protocol

import (
	"encoding/json"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

// Conformance test runner — Go.
//
// Loads every fixture in protocol/conformance/fixtures/ and asserts the
// documented behavior. Runs as a normal `go test` and as a Bazel target.
//
// Fixture format documented in protocol/conformance/README.md.

type fixture struct {
	Name              string          `json:"name"`
	SchemaRef         string          `json:"schema_ref"`
	Data              json.RawMessage `json:"data"`
	ExpectedValid     bool            `json:"expected_valid"`
	ExpectedRoundTrip *bool           `json:"expected_round_trip,omitempty"`
	ExpectedErrorCode *int            `json:"expected_error_code,omitempty"`
}

func (f fixture) roundTrip() bool {
	if f.ExpectedRoundTrip == nil {
		return true
	}
	return *f.ExpectedRoundTrip
}

func fixturesRoot(t *testing.T) string {
	t.Helper()
	if p := os.Getenv("TAP_CONFORMANCE_FIXTURES"); p != "" {
		return p
	}
	// pkg/protocol → ../../protocol/conformance/fixtures
	return filepath.Join("..", "..", "protocol", "conformance", "fixtures")
}

func loadFixtures(t *testing.T, root string) []fixture {
	t.Helper()
	var out []fixture
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
		out = append(out, f)
		return nil
	})
	if err != nil {
		t.Fatalf("walk %s: %v", root, err)
	}
	return out
}

func TestFixtureCorpusLoads(t *testing.T) {
	root := fixturesRoot(t)
	fixtures := loadFixtures(t, root)
	if len(fixtures) == 0 {
		t.Fatalf("expected at least one fixture under %s", root)
	}
}

func TestEveryFixtureRoundTripsWhenExpected(t *testing.T) {
	for _, f := range loadFixtures(t, fixturesRoot(t)) {
		if !f.ExpectedValid || !f.roundTrip() {
			continue
		}
		var v any
		if err := json.Unmarshal(f.Data, &v); err != nil {
			t.Errorf("%s: parse failed: %v", f.Name, err)
			continue
		}
		serialized, err := json.Marshal(v)
		if err != nil {
			t.Errorf("%s: serialize failed: %v", f.Name, err)
			continue
		}
		var reparsed any
		if err := json.Unmarshal(serialized, &reparsed); err != nil {
			t.Errorf("%s: reparse failed: %v", f.Name, err)
			continue
		}
		var original any
		_ = json.Unmarshal(f.Data, &original)
		if !reflect.DeepEqual(original, reparsed) {
			t.Errorf("%s: round-trip mismatch", f.Name)
		}
	}
}

// TODO(phase-1): once codegen runs and pkg/protocol/generated/ has typed
// schemas, add per-schema strict-typing assertions.
