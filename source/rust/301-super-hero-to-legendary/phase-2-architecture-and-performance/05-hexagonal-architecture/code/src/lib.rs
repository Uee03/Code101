pub mod adapters;
pub mod domain;
pub mod ports;
pub mod service;

#[cfg(test)]
mod architecture_tests {
    // A fitness function: it fails the build when the domain starts importing other layers.
    #[test]
    fn domain_does_not_import_other_layers() {
        let source = include_str!("domain.rs");
        for layer in ["ports", "adapters", "service"] {
            assert!(
                !source.contains(&format!("crate::{layer}")),
                "domain.rs must not use crate::{layer}"
            );
        }
    }
}
