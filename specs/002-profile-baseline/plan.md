# Plan: Modular PowerShell profile and shared library contracts

The [specification](spec.md) preserves existing behavior. Use the project guide
and constitution for implementation constraints. Keep upstream-managed templates,
helpers, and integration manifests unchanged.

## Source ownership

- `Microsoft.PowerShell_profile.ps1`
- `profile.d`
- `scripts/lib`
- `scripts/utils/code-quality`
- `tests/integration/fragments`
- `tests/unit/library/fragment`

## Constitution check

Keep the repository constitution, authoritative source files, existing interfaces, and native validation. The
baseline does not authorize live host mutation, publication of private data, or changes to managed Spec Kit
files.

## Validation

```sh
make validate
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/unit/library/fragment/library-fragment-loading.tests.ps1 -OutputFormat Minimal
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/integration/fragments/fragment-loading-failures.tests.ps1 -OutputFormat Minimal
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/integration/fragments/fragment-error-recovery.tests.ps1 -OutputFormat Minimal
```

Run checks in an isolated checkout. Commands are instructions, not evidence of
a pass. Record results in `coverage.md`, keep incomplete work in `tasks.md`, and
follow `RELEASING.md` for reviewed delivery. No live operation is required solely
to create this retrospective baseline.
