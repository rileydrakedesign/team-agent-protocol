// SPDX-License-Identifier: Apache-2.0

//! Hand-written envelope helpers. The wire shape itself is generated; this
//! module adds construction conveniences, version negotiation, and trace_id
//! handling.

/// Current TAP protocol version this binding implements.
pub const TAP_VERSION: &str = "0.1.0";

/// Returns the highest TAP version supported by both peers, or `None` if
/// the major versions are incompatible.
pub fn negotiate_version(theirs: &str, ours: &str) -> Option<String> {
    let (tm, _, _) = parse_semver(theirs)?;
    let (om, _, _) = parse_semver(ours)?;
    if tm != om {
        return None;
    }
    if version_lt(theirs, ours) {
        Some(theirs.to_owned())
    } else {
        Some(ours.to_owned())
    }
}

fn parse_semver(v: &str) -> Option<(u32, u32, u32)> {
    let core = v.split('-').next()?;
    let mut parts = core.split('.');
    let major = parts.next()?.parse().ok()?;
    let minor = parts.next()?.parse().ok()?;
    let patch = parts.next()?.parse().ok()?;
    Some((major, minor, patch))
}

fn version_lt(a: &str, b: &str) -> bool {
    parse_semver(a) < parse_semver(b)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn picks_lower_when_majors_match() {
        assert_eq!(
            negotiate_version("0.1.0", "0.2.0"),
            Some("0.1.0".to_owned())
        );
    }

    #[test]
    fn rejects_when_majors_differ() {
        assert_eq!(negotiate_version("0.1.0", "1.0.0"), None);
    }
}
