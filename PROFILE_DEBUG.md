# PS_PROFILE_DEBUG — profile debug guide

## Purpose

This repository exposes a small runtime debug toggle for development and CI.

How it works

- Set `PS_PROFILE_DEBUG=1` to enable more verbose output from profile helpers.
- When running locally, helpers use `Write-Verbose` so you can see output with `-Verbose` or by setting `$VerbosePreference = 'Continue'`.
- In GitHub Actions the workflow sets `PS_PROFILE_DEBUG=1` and the helpers print debug lines to stdout (so they appear in action logs) to aid debugging.

Usage

Locally:

```powershell
# Temporarily enable debug for a shell session
$env:PS_PROFILE_DEBUG = '1'
# To see Write-Verbose output in scripts:
$VerbosePreference = 'Continue'
# Then run a repro or reload your profile
. $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

In CI

Workflows in `.github/workflows` set `PS_PROFILE_DEBUG=1` for repro/test steps so debug messages are visible in the action logs.

Notes

- This debug mode is opt-in.
- Messages within CI are printed to stdout so they appear in logs; locally, `Write-Verbose` is used to avoid polluting normal output unless the developer opts-in.

### Suppressing expected fragment warnings

During automated testing you can silence warnings from intentionally broken test fragments by setting `PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS`. The value accepts comma-separated fragment names or wildcard patterns. For example:

```powershell
$env:PS_PROFILE_SUPPRESS_FRAGMENT_WARNINGS = '99-test-*'
. $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
```

Set the variable to `1`, `true`, or `*` to hide all fragment warnings for the current session. The test harness automatically enables suppression for fragments named `99-test-*` so integration tests stay quiet while still logging details to the debug file when needed.

Timings / micro-instrumentation
--------------------------------

Some fragments include lightweight instrumentation that appends CSV rows to
`scripts/*.csv` when enabled. To enable per-step timing for development:

```powershell
$env:PS_PROFILE_DEBUG_TIMINGS = '1'
. $HOME\Documents\PowerShell\profile.d\30-aliases.ps1  # example
```

After running, check the generated CSV (for example `scripts/alias-instrument.csv`).
Remove the file when finished to keep the workspace clean; it is safe to
recreate by re-running the instrumented fragment.
