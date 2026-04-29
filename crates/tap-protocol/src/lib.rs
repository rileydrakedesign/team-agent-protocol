// SPDX-License-Identifier: Apache-2.0

//! TAP — Team Agent Protocol — Rust bindings.
//!
//! This crate exposes the TAP wire format as Rust types. Generated bindings
//! live in [`generated`] and are produced from CUE schemas under
//! `protocol/schemas/` by `tools/codegen/generate.sh`. Do not hand-edit
//! anything under [`generated`].
//!
//! Hand-written helpers (envelope construction, error types, version
//! negotiation) live in this module and re-export the generated types.

pub mod error;
pub mod envelope;

#[allow(clippy::all)]
#[allow(unused_imports)]
#[allow(non_snake_case)]
pub mod generated;

pub use error::Error;
