# Changelog

All notable changes are documented here. The format follows Keep a Changelog and the project uses Semantic Versioning.

## [1.4.0] - 2026-11-23
### Added
- `/readyz` answers 503 while a dependency is unavailable.
- `/version` reports the packaged version.
### Changed
- The container runs as a non-root user with a read-only root file system.

## [1.3.0] - 2026-10-01
### Added
- `/healthz` liveness endpoint.
