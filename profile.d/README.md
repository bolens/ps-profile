# profile.d/ — PowerShell modular profile fragments

This directory contains small, focused PowerShell scripts that are dot-sourced
from `Microsoft.PowerShell_profile.ps1` during interactive session startup.

Guidelines:

- Keep fragments idempotent: avoid re-defining existing functions/aliases unless
  necessary. Use `Get-Command -ErrorAction SilentlyContinue` to guard.
- Prefer `Set-Item -Path "Function:<name>" -Value <scriptblock> -Option AllScope`
  for programmatic function registration when you need to avoid collisions.
- Keep each file focused (e.g., `git` helpers, `wsl` helpers, `system-info`).
- Keep external tool dependencies behind `Get-Command` checks to avoid noisy
  errors when a tool is not installed.
- If adding long-running or heavy work, guard it with `if ($Host.UI.RawUI)` or
  make it opt-in via a small variable

Loading order:
Files are loaded in lexical order (sorted by filename). To control load order,
prefix names with numeric or alphabetic prefixes (e.g., `00-init.ps1`, `10-git.ps1`).

Examples/Helpers:

- Use `reload` to reload your profile: `reload` (already provided in `utilities.ps1`).
- Use `backup-profile` to create a timestamped backup of the main profile.

Keep this README updated whenever you add new fragments.

## Common quick examples

- Convert JSON to YAML (03-files provides helpers):
  - Get-Content data.json | ConvertFrom-Json | ConvertTo-Yaml
- Base64 encode a file:
  - Get-Content file.bin -AsByteStream | [System.Convert]::ToBase64String($_)
- Use `ssh-add-if` to load your private key only when not already loaded:
  - ssh-add-if $env:USERPROFILE\\.ssh\\id_rsa
- Copy output to clipboard:
  - Get-Process | Out-String | cb

## Where to add fragments

Add short, focused files in this directory and prefix them with numbers to
control load order. Keep each fragment idempotent and guard calls to external
tools with `Get-Command` checks to avoid noisy errors.

## Spellcheck

- This repository includes a GitHub Actions workflow that runs `cspell` on
  pushes and PRs (`.github/workflows/spellcheck.yml`). Locally you can run
  `scripts\spellcheck.ps1`. To opt into a local pre-commit hook, create the
  file `.hooks/enable` — a tracked shim lives at `.hooks/pre-commit` which will
  invoke the script (non-blocking by default).

## Performance & lazy helpers

To keep interactive startup time low, many fragments avoid doing expensive
discovery or imports at dot-source. Instead, heavy work is deferred behind
small Enable-* helpers. Examples:

- `Enable-PSReadLine` — imports/configures PSReadLine on-demand.
- `Enable-Aliases` — registers aliases and small helper functions when first
  requested.
- `Enable-ScoopCompletion` — loads scoop completion only when needed.

Use the included benchmark harness `scripts/utils/benchmark-startup.ps1` to measure
full startup and per-fragment dot-source timings. The harness writes
`scripts/data/startup-benchmark.csv` and prints a table to stdout. This helps
prioritize micro-optimizations without changing user-visible behavior.
