# PowerShell Profile Technical Documentation

This document provides detailed technical information about the profile architecture, internals, and advanced usage. For quick start and general information, see [README.md](README.md).

## Architecture Overview

### Profile Loader

`Microsoft.PowerShell_profile.ps1` is the main entrypoint that:

- Loads fragments from `profile.d/` in lexical order (sorted by filename)
- Includes robust error handling that reports which fragment failed to load
- Keeps itself minimal—all functionality lives in fragments

### Fragment Loading Order

Fragments use numeric prefixes to control load order:

- **00-09**: Core bootstrap, environment, and registration helpers
- **10-19**: Terminal configuration (PSReadLine, prompts, Git)
- **20-29**: Container engines and cloud tools
- **30-39**: Development tools and aliases
- **40-69**: Language-specific tools (Go, PHP, Node.js, Python, Rust)
- **70-79**: Advanced features (performance insights, enhanced history, system monitoring)

## Bootstrap Helpers

`00-bootstrap.ps1` provides three collision-safe registration helpers:

### Set-AgentModeFunction

Creates functions without overwriting existing commands:

```powershell
Set-AgentModeFunction -Name 'MyFunc' -Body { Write-Output "Hello" }

# Return the ScriptBlock for programmatic use
$sb = Set-AgentModeFunction -Name 'myfn' -Body { 'hi' } -ReturnScriptBlock
```

### Set-AgentModeAlias

Creates aliases or function wrappers without overwriting:

```powershell
Set-AgentModeAlias -Name 'gs' -Target 'git status'

# Return the textual alias wrapper definition
$def = Set-AgentModeAlias -Name 'gs' -Target 'git status' -ReturnDefinition
```

### Test-CachedCommand

Fast command existence check with caching:

```powershell
if (Test-CachedCommand 'docker') { # configure docker helpers }
```

## Performance Optimizations

### Lazy Loading Pattern

Heavy initialization is deferred behind `Enable-*` functions:

```powershell
# In fragment: register enabler function only
Set-AgentModeFunction -Name 'Enable-MyTool' -Body {
    # Expensive work happens here when user calls Enable-MyTool
    Import-Module MyExpensiveModule
    Set-AgentModeAlias -Name 'mt' -Target 'mytool'
}
```

### Provider-First Checks

Use `Test-Path` on providers to avoid module autoload and disk I/O:

```powershell
# Fast: checks provider without loading modules
if (Test-Path Function:\MyFunction) { return }

# Slow: may trigger module autoload
if (Get-Command MyFunction -ErrorAction SilentlyContinue) { return }
```

### Benchmarking

Measure startup performance:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 30
```

Outputs `scripts/data/startup-benchmark.csv` with per-fragment timings. See [PROFILE_DEBUG.md](PROFILE_DEBUG.md) for micro-instrumentation.

## Container Engine Support

### Auto-Detection

`22-containers.ps1` and `24-container-utils.ps1` provide:

- Auto-detection of Docker or Podman with compose support
- Unified aliases (`dcu`, `dcd`, `dcl`, `dprune`, etc.) that work with either engine
- Session-level preference setting

### Setting Preference

```powershell
Set-ContainerEnginePreference docker  # or 'podman'
Test-ContainerEngine  # Inspect current configuration
```

Returns object with `Engine`, `Compose` (subcommand or legacy), and `Preferred` values.

## Prompt Frameworks

Two prompt systems are supported with lazy initialization:

- **oh-my-posh** (`06-oh-my-posh.ps1`): Use `Initialize-OhMyPosh` to activate
- **Starship** (`23-starship.ps1`): Use `Initialize-Starship` to activate

If neither is installed, PowerShell uses its default prompt. The profile does not override existing prompt configurations.

## Fragment Idempotency

All fragments MUST be idempotent (safe to source multiple times). Patterns:

```powershell
# Use bootstrap helpers (recommended)
Set-AgentModeFunction -Name 'MyFunc' -Body { ... }

# Or guard with provider checks
if (-not (Test-Path Function:\MyFunc)) {
    function MyFunc { ... }
}

# Guard external tool calls
if (Test-CachedCommand 'docker') {
    # configure docker helpers
}
```

## PSScriptAnalyzer Configuration

`PSScriptAnalyzerSettings.psd1` disables noisy rules for interactive profile code:

- Allows cmdlet aliases
- Allows `Write-Host` for user feedback
- Per-file suppressions for known acceptable patterns

Edit this file to customize linting behavior.

## Debug & Instrumentation

### PS_PROFILE_DEBUG

Enable verbose output from bootstrap helpers:

```powershell
$env:PS_PROFILE_DEBUG = '1'
$VerbosePreference = 'Continue'
. $PROFILE
```

In CI, helpers write to stdout for GitHub Actions logs.

### PS_PROFILE_DEBUG_TIMINGS

Enable micro-instrumentation CSV output:

```powershell
$env:PS_PROFILE_DEBUG_TIMINGS = '1'
. $PROFILE
```

Check generated CSV files in `scripts/data/` (e.g., `alias-instrument.csv`).

See [PROFILE_DEBUG.md](PROFILE_DEBUG.md) for complete debugging guide.

## Fragment Development

### Creating New Fragments

1. Create file in `profile.d/` with numeric prefix (e.g., `30-dev.ps1`)
2. Keep it focused on a single concern
3. Ensure idempotency using bootstrap helpers or guards
4. Guard external tool calls with `Test-CachedCommand` or `Get-Command`
5. Avoid side effects during dot-sourcing (defer to `Enable-*` functions)

### Best Practices

- **No expensive operations**: Defer module imports, file I/O, network calls
- **Provider-first checks**: Use `Test-Path Function:\Name` over `Get-Command`
- **Cached commands**: Use `Test-CachedCommand` to avoid repeated lookups
- **Clear documentation**: Add comment-based help to functions

## API Documentation

Function and alias documentation is auto-generated from comment-based help:

```powershell
pwsh -NoProfile -File scripts/utils/generate-docs.ps1
```

Outputs to `docs/*.md`. See [docs/README.md](docs/README.md) for the generated index.

## Related Documentation

- [README.md](README.md) — Quick start and overview
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development guidelines
- [PROFILE_DEBUG.md](PROFILE_DEBUG.md) — Debugging and instrumentation
- [powershell.config.README.md](powershell.config.README.md) — Configuration details
- [WARP.md](WARP.md) — WARP development guide
