// SPDX-License-Identifier: Apache-2.0

package protocol

import "testing"

func TestNegotiateVersionPicksLowerWhenMajorsMatch(t *testing.T) {
	got := NegotiateVersion("0.1.0", "0.2.0")
	if got != "0.1.0" {
		t.Fatalf("NegotiateVersion(0.1.0, 0.2.0) = %q, want 0.1.0", got)
	}
}

func TestNegotiateVersionRejectsWhenMajorsDiffer(t *testing.T) {
	got := NegotiateVersion("0.1.0", "1.0.0")
	if got != "" {
		t.Fatalf("NegotiateVersion(0.1.0, 1.0.0) = %q, want empty string", got)
	}
}
