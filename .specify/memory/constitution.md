# PowerShell Profile Constitution

## Core Principles

### I. Modular, Lazy, Idempotent Startup
The main profile remains small. Fragments MUST be safe to load repeatedly, preserve dependency order, and defer expensive or optional tooling until use.

### II. Shared Library First
Scripts MUST reuse `scripts/lib` through the canonical module loader for paths, logging, processes, exits, configuration, and other shared behavior. Parallel local implementations require clear justification.

### III. Cross-Platform and Strict Behavior
Supported Windows, Linux, and macOS behavior MUST remain aligned unless explicitly platform-specific. Strict mode, shared exit semantics, error handling, and secret protections MUST not be weakened.

### IV. Safe User Environment
Tests and development MUST not mutate the live profile, install modules, expose credentials, or depend on ambient user state. Use isolated fixtures and `-NoProfile` execution where applicable.

### V. Tested and Generated Surfaces
Behavior changes require focused Pester coverage. Generated API docs and wrappers come from repository generators. Cross-cutting changes use the full quality gate and report unavailable platform checks.

## Governance

`CONTRIBUTING.md` and affected module docs carry detailed contracts. Exceptions require tests and explicit rationale. Amendments use semantic versioning.

**Version**: 1.0.0 | **Ratified**: 2026-08-15 | **Last Amended**: 2026-08-15
