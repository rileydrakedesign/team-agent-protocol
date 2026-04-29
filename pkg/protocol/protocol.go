// SPDX-License-Identifier: Apache-2.0

// Package protocol implements TAP — Team Agent Protocol — Go bindings.
//
// Generated wire types live in the generated/ subpackage and are produced
// from CUE schemas under protocol/schemas/ by tools/codegen/generate.sh.
// Do not hand-edit anything under generated/.
package protocol

// TAPVersion is the protocol version this binding implements. Negotiated
// at handshake; relay supports current and previous major version.
const TAPVersion = "0.1.0"

// NegotiateVersion returns the highest TAP version supported by both peers,
// or the empty string if the major versions are incompatible.
func NegotiateVersion(theirs, ours string) string {
	tm, _, _, ok1 := parseSemver(theirs)
	om, _, _, ok2 := parseSemver(ours)
	if !ok1 || !ok2 || tm != om {
		return ""
	}
	if versionLess(theirs, ours) {
		return theirs
	}
	return ours
}

func parseSemver(v string) (major, minor, patch int, ok bool) {
	core := v
	for i := 0; i < len(v); i++ {
		if v[i] == '-' || v[i] == '+' {
			core = v[:i]
			break
		}
	}
	parts := splitN(core, '.', 3)
	if len(parts) != 3 {
		return 0, 0, 0, false
	}
	a, ok1 := atoi(parts[0])
	b, ok2 := atoi(parts[1])
	c, ok3 := atoi(parts[2])
	return a, b, c, ok1 && ok2 && ok3
}

func versionLess(a, b string) bool {
	am, an, ap, _ := parseSemver(a)
	bm, bn, bp, _ := parseSemver(b)
	if am != bm {
		return am < bm
	}
	if an != bn {
		return an < bn
	}
	return ap < bp
}

func splitN(s string, sep byte, n int) []string {
	out := make([]string, 0, n)
	start := 0
	for i := 0; i < len(s) && len(out) < n-1; i++ {
		if s[i] == sep {
			out = append(out, s[start:i])
			start = i + 1
		}
	}
	out = append(out, s[start:])
	return out
}

func atoi(s string) (int, bool) {
	if s == "" {
		return 0, false
	}
	n := 0
	for i := 0; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return 0, false
		}
		n = n*10 + int(s[i]-'0')
	}
	return n, true
}
