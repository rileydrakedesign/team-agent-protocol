// SPDX-License-Identifier: Apache-2.0

//! Errors returned by TAP envelope construction and validation. Wire-level
//! error codes are defined in `protocol/SPEC.md` §13.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum Error {
    #[error("malformed JSON: {0}")]
    Json(#[from] serde_json::Error),

    #[error("envelope failed schema validation: {0}")]
    InvalidEnvelope(String),

    #[error("unsupported TAP version: {0}")]
    VersionUnsupported(String),

    #[error("unknown method: {0}")]
    MethodNotFound(String),
}
