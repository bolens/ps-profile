# Agent guidance

Before Spec Kit planning or implementation, read
`.specify/memory/project-guide.md` with the project constitution. It maps
requirements to this repository's source, acceptance evidence, and validation.

Read `.specify/memory/constitution.md`, `CONTRIBUTING.md`, and documentation for
the affected fragment or script. Keep the main profile loader minimal.

- Reuse modules under `scripts/lib/`. Import `ModuleImport.psm1` first and load
  other libraries with `Import-LibModule`; do not duplicate shared path,
  logging, process, or exit-code logic.
- Use `Exit-WithCode` and the shared exit constants rather than direct `exit`.
- Fragments must be idempotent and expensive tool setup must remain lazy. Use
  the bootstrap registration helpers and preserve declared load ordering.
- Maintain Windows, Linux, and macOS behavior unless a surface is explicitly
  platform-specific. Do not weaken strict mode, security checks, or secret
  handling.
- Match repository formatting and comment-based help conventions. Update
  generated API documentation through its generator, never by hand.
- Run focused Pester coverage with
  `scripts/utils/code-quality/analyze-coverage.ps1` for changed code, then the
  relevant lint/quality target. Use the repository's full validation target
  for cross-cutting changes; report unavailable platform/tool checks.
- Do not install modules, alter the live user profile, publish packages, stage,
  or commit unless explicitly requested. Test with isolated fixtures and
  `-NoProfile` where applicable.

## Spec-driven changes

Use Spec Kit for new capabilities, architecture, security-sensitive behavior,
migrations, and coordinated multi-file changes. Keep narrow fixes, dependency
updates, prose edits, and release housekeeping in the normal repository
workflow unless their risk warrants a written specification. Keep completed
feature directories under `specs/` as decision history; do not backfill them for
finished work.
