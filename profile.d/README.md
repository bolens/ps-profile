# profile.d/ — Modular Profile Fragments

This directory contains small, focused PowerShell scripts that are dot-sourced from `Microsoft.PowerShell_profile.ps1` during interactive session startup.

## Loading Order

Files are loaded in **lexical order** (sorted by filename). Use numeric prefixes to control load order:

- **00-09**: Core bootstrap, environment, and registration helpers
- **10-19**: Terminal configuration (PSReadLine, prompts, Git)
- **20-29**: Container engines and cloud tools
- **30-39**: Development tools and aliases
- **40-69**: Language-specific tools (Go, PHP, Node.js, Python, Rust)
- **70-79**: Advanced features (performance insights, enhanced history, system monitoring)

## Fragment Guidelines

### Idempotency

Fragments must be safe to dot-source multiple times:

```powershell
# Use bootstrap helpers (recommended)
Set-AgentModeFunction -Name 'MyFunc' -Body { ... }
Set-AgentModeAlias -Name 'gs' -Target 'git status'

# Or guard with provider checks
if (-not (Test-Path Function:\MyFunc)) {
    function MyFunc { ... }
}
```

### External Tool Dependencies

Always check availability before invoking:

```powershell
if (Test-CachedCommand 'docker') {
    # configure docker helpers
}
```

### Performance

- **Defer expensive work**: Use `Enable-*` functions for lazy loading
- **Provider-first checks**: Use `Test-Path Function:\Name` over `Get-Command`
- **No side effects**: Avoid module imports, file I/O, network calls during dot-sourcing

### Focus

Keep each fragment focused on a single concern (e.g., `11-git.ps1` for Git helpers, `22-containers.ps1` for container utilities).

## Bootstrap Helpers

Available from `00-bootstrap.ps1`:

- `Set-AgentModeFunction` — Creates collision-safe functions
- `Set-AgentModeAlias` — Creates collision-safe aliases
- `Test-CachedCommand` — Fast command existence check with caching
- `Get-FragmentDependencies` — Parses dependencies from fragment headers
- `Test-FragmentDependencies` — Validates dependency satisfaction
- `Get-FragmentLoadOrder` — Calculates optimal load order
- `Get-FragmentConfig` — Gets enhanced fragment configuration
- `Enable-ProfileFragment` / `Disable-ProfileFragment` — Manage fragment state
- `Get-ProfileFragment` — List fragments and their status

See [PROFILE_README.md](../PROFILE_README.md) for detailed usage examples.

## Quick Examples

```powershell
# Reload profile
reload

# Convert JSON to YAML
Get-Content data.json | ConvertFrom-Json | ConvertTo-Yaml

# Base64 encode a file
Get-Content file.bin -AsByteStream | [System.Convert]::ToBase64String($_)

# Load SSH key if not already loaded
ssh-add-if $env:USERPROFILE\.ssh\id_rsa

# Copy output to clipboard
Get-Process | Out-String | cb
```

## Performance Benchmarking

Measure startup and per-fragment timings:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 30
# Or use task: task benchmark
```

Update performance baseline after optimizations:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -UpdateBaseline
# Or use task: task update-baseline
```

Outputs `scripts/data/startup-benchmark.csv` with detailed metrics.

## Documentation

- Fragment-level README files are optional but recommended
- Function/alias documentation is auto-generated from comment-based help
- See [PROFILE_README.md](../PROFILE_README.md) for detailed technical information
- See [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines
