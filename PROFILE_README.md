PowerShell profile (workspace)
===============================

## Purpose

This workspace contains a modular PowerShell profile for interactive shells. The
main entrypoint is `Microsoft.PowerShell_profile.ps1`. Functionality is split into
small fragments under `profile.d/` for maintainability.

## Quick index

- `Microsoft.PowerShell_profile.ps1` — main profile loader (keeps itself small). Includes robust error handling that reports which fragment failed to load.
- `profile.d/` — modular fragments. Files are loaded in lexical order.
  - `00-bootstrap.ps1` — helper functions for safe registration.
  - `02-env.ps1` — environment variable defaults.
  - `06-oh-my-posh.ps1` — oh-my-posh prompt initialization.
  - `10-git.ps1` — consolidated git helpers.
  - `20-containers.ps1` — Docker/Podman helpers (dcu, dcd, dcl, dprune, etc.).
  - `20-starship.ps1` — Starship prompt initialization.
  - `21-container-utils.ps1` — Test-ContainerEngine and Set-ContainerEnginePreference.
- `scripts/utils/run-lint.ps1` — installs and runs PSScriptAnalyzer on `profile.d/`.
- `scripts/checks/check-idempotency.ps1` — dot-sources every fragment twice in order.
- `scripts/checks/validate-profile.ps1` — runs lint then idempotency checks.
- `.vscode/tasks.json` — VS Code tasks to run lint and validation.

## How to reload the profile

In an interactive shell:

```powershell
. $PROFILE
```

## Prompt configuration

The profile supports multiple prompt frameworks:

- **oh-my-posh** (`06-oh-my-posh.ps1`): Initializes oh-my-posh with lazy loading to keep startup fast.
- **Starship** (`20-starship.ps1`): Initializes Starship prompt with lazy loading.

If neither is installed, PowerShell uses its default prompt. The profile does not override existing prompt configurations.

## Container engine preference

The container helpers in `20-containers.ps1` auto-detect Docker or Podman. You can
force a preference for the current session with:

```powershell
Set-ContainerEnginePreference docker
# or
Set-ContainerEnginePreference podman
```

To see which engine and compose backend will be used:

```powershell
Test-ContainerEngine
```

This prints an object with `Engine`, `Compose` (subcommand or legacy), and
`Preferred` values.

## Validation & linting

Run checks locally before committing changes:

- Lint with PSScriptAnalyzer (script will install it to CurrentUser if missing):

```powershell
pwsh -NoProfile -File 'scripts/utils/run-lint.ps1'
```

- Idempotency smoke test (dot-sources each fragment twice):

```powershell
powershell -NoProfile -File 'scripts/checks/check-idempotency.ps1'
```

- Full validation (lint + idempotency):

```powershell
pwsh -NoProfile -File 'scripts/checks/validate-profile.ps1'
```

There is also a VS Code task: Command Palette → Run Task → "Validate profile (lint + idempotency)".

## Performance optimizations & benchmarking

The profile has been refactored to keep interactive startup fast using a
conservative, measurement-first approach:

- Fragments avoid expensive command/module discovery at dot-source. Prefer
  provider-first checks (for example `Test-Path Function:...` or `Alias:...`) to
  avoid triggering module autoload or disk I/O.
- Heavy or IO-bound initialization is deferred behind small Enable-* helpers
  (for example `Enable-PSReadLine`, `Enable-Aliases`, `Enable-ScoopCompletion`).
  The helpers register functions/aliases or Import-Module only when invoked.
- A simple benchmark harness is included at `scripts/utils/benchmark-startup.ps1`.
  Use it to run N iterations and capture per-fragment dot-source timings and
  full startup times.

Quick benchmark example:

```powershell
pwsh -NoProfile -File scripts\benchmark-startup.ps1 -Iterations 30
```

This writes `scripts/data/startup-benchmark.csv` with per-fragment means/medians
and a human-readable table to stdout. For micro-profiling, some fragments
include optional instrumentation that appends timings to `scripts/data/*.csv` when
enabled (see `PROFILE_DEBUG.md`).

## Adding new fragments

- Create a new file under `profile.d/` named with a prefix to control load order
  (for example `30-dev.ps1`).
- Keep fragments idempotent. Use `Set-AgentModeFunction` / `Set-AgentModeAlias`
  (provided by `00-bootstrap.ps1`) or guard definitions with `Get-Command -ErrorAction SilentlyContinue`.
- Prefer `Get-Command` checks before invoking external tools to avoid noisy
  errors when tools are not installed.

## Examples: requesting returned objects

If you need the ScriptBlock or alias definition for programmatic use, both
helpers support an explicit switch to request the return value:

```powershell
# Return the created ScriptBlock
$sb = Set-AgentModeFunction -Name 'myfn' -Body { 'hi' } -ReturnScriptBlock

# Return the textual alias wrapper definition
$def = Set-AgentModeAlias -Name 'gs' -Target 'git status' -ReturnDefinition
```

## Contributing & automation ideas

Suggestions you can add next:

- A small README per fragment documenting dependencies and examples.
- A Git pre-commit hook or CI (GitHub Actions) workflow that runs `scripts/checks/validate-profile.ps1`.
- PSScriptAnalyzer rule customization for the style you prefer.

See `CONTRIBUTING.md` for guidance on running the local validation scripts and
installing the optional pre-commit hook that runs validation automatically.

## PSScriptAnalyzer settings

This repo includes `PSScriptAnalyzerSettings.psd1` which disables a couple of
rules that are noisy for interactive profile code (aliases and Write-Host).
Edit that file to customize linting behavior.

## Add a CI badge

After this repo is pushed to GitHub and the workflow runs, add a status badge to
this README:

```markdown
[![Validate PowerShell Profile](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml)

[![Commit message check](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml)
```

If you'd like, I can scaffold any of those automation steps (pre-commit hook or CI workflow) next.
