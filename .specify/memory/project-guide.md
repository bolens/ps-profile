# ps-profile Spec Kit project guide

A modular PowerShell profile and shared script library with lazy startup and cross-
platform behavior.

Read this guide with `AGENTS.md` and `.specify/memory/constitution.md` before
specifying, planning, or implementing a substantial change. It is project-owned
guidance, not an upstream-managed template.

## Source and ownership map

- `Microsoft.PowerShell_profile.ps1`
- `profile.d/`
- `scripts/lib/`
- `ARCHITECTURE.md`
- `tests/`
- `Makefile`

## Specification and plan decisions

Identify the fragment, load-order dependency, shared library, and public function or
wrapper affected. Preserve lazy/idempotent startup and canonical ModuleImport/Import-
LibModule loading. Keep exit, logging, path, and process behavior in the shared
libraries.

## Acceptance evidence

Cover repeated loading, missing optional modules, strict-mode failures, unusual paths,
startup cost, and Windows/Linux/macOS differences. Run PowerShell without the live
profile and use isolated fixtures; keep generated help and wrappers synchronized.

## Validation and operational limits

```sh
make lint
make test-changed-shards
make validate
```

Select focused Pester coverage via scripts/utils/code-quality/analyze-coverage.ps1
before broad gates. Report unavailable platforms and toolchains. Do not install modules,
change the live profile, or update performance baselines just to make tests pass.

## Working through Spec Kit

Use Spec Kit for new capabilities, architectural or security-sensitive changes,
migrations, and coordinated changes that need a written contract. Keep narrow fixes,
dependency updates, and prose maintenance in the normal PR workflow.

For a new feature, record observable acceptance criteria in `spec.md`, source ownership
and constitution checks in `plan.md`, and evidence-bearing work in `tasks.md` under the
feature directory created by Spec Kit. Resolve material unknowns before implementation.
Mark tasks complete only after their stated verification, and distinguish completed,
skipped, blocked, and manual checks. Retain completed feature documents as decision
history; do not backfill feature specifications for already finished code.

Keep `.specify/templates/`, `.specify/scripts/`, and generated Codex skills under their
integration manifests. Use this guide and the constitution for local customization.
Regenerate managed files through Spec Kit and verify that project-owned memory survives
updates. Follow `RELEASING.md` for push, merge, release or delivery, and recovery.
