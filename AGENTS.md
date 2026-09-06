# Agent guidance

[Documentation](docs/README.md) maps architecture, deployment, state, and document ownership.

Read [.specify/memory/constitution.md](.specify/memory/constitution.md), [CONTRIBUTING.md](CONTRIBUTING.md), and documentation for
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

## Planning and evidence

Use the [project guide](.specify/memory/project-guide.md) and
[constitution](.specify/memory/constitution.md) for substantial changes. The guide
owns Spec Kit scope, retained history, retrospective requirements, and acceptance
evidence. Prose maintenance uses the normal repository workflow.

## Context and handoffs

- Search before reading. Use bounded source excerpts for exploratory reads over
  350 lines, and inspect required guidance and actual source before editing.
- When delegation is permitted, assign a bounded question or output, paths, and
  check. Return source locations, changes, and verification gaps for final review.
- Keep durable corrections in the [project guide](.specify/memory/project-guide.md)
  or owning contract. Replace superseded advice and read it before reuse.
  Temporary progress belongs in task notes. Preserve existing authority rules.
