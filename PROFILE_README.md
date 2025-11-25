# PowerShell Profile Technical Documentation

This document provides detailed technical information about the profile architecture, internals, and advanced usage. For quick start and general information, see [README.md](README.md).

## Architecture Overview

### Profile Loader

`Microsoft.PowerShell_profile.ps1` is the main entrypoint that:

- Loads fragments from `profile.d/` with dependency-aware ordering
- Includes robust error handling that reports which fragment failed to load
- Supports batch-optimized loading for better performance
- Keeps itself minimal—all functionality lives in fragments

### Fragment Loading Order

Fragments use numeric prefixes to control load order, but can also declare explicit dependencies:

**Numeric Prefixes:**

- **00-09**: Core bootstrap, environment, and registration helpers
- **10-19**: Terminal configuration (PSReadLine, prompts, Git)
- **20-29**: Container engines and cloud tools
- **30-39**: Development tools and aliases
- **40-69**: Language-specific tools (Go, PHP, Node.js, Python, Rust)
- **70-79**: Advanced features (performance insights, enhanced history, system monitoring)

**Dependency Declarations:**
Fragments can declare dependencies in their header:

```powershell
#Requires -Fragment '00-bootstrap'
#Requires -Fragment '01-env'
# Or: # Dependencies: 00-bootstrap, 01-env
```

The loader automatically resolves dependencies and loads fragments in the correct order.

## Fragment Configuration

### Basic Configuration

Fragments can be enabled/disabled via `.profile-fragments.json`:

```json
{
  "disabled": ["11-git"]
}
```

Or using commands:

```powershell
Disable-ProfileFragment -FragmentName '11-git'
Enable-ProfileFragment -FragmentName '11-git'
Get-ProfileFragment  # List all fragments
```

### Enhanced Configuration

The `.profile-fragments.json` file supports advanced options:

```json
{
  "disabled": ["11-git"],
  "loadOrder": ["00-bootstrap", "01-env", "05-utilities"],
  "environments": {
    "minimal": ["00-bootstrap", "01-env"],
    "development": ["00-bootstrap", "01-env", "11-git", "30-dev-tools"]
  },
  "featureFlags": {
    "enableAdvancedFeatures": true
  },
  "performance": {
    "batchLoad": true,
    "maxFragmentTime": 500
  }
}
```

**Environment-Specific Loading:**

```powershell
$env:PS_PROFILE_ENVIRONMENT = 'minimal'
. $PROFILE
```

**Batch-Optimized Loading:**

```powershell
$env:PS_PROFILE_BATCH_LOAD = '1'
. $PROFILE
```

Or configure in `.profile-fragments.json`:

```json
{
  "performance": {
    "batchLoad": true
  }
}
```

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
# Or use task: task benchmark
```

Update performance baseline after optimizations:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -UpdateBaseline
# Or use task: task update-baseline
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

Returns object with `Engine`, `Compose` (subcommand), and `Preferred` values.

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

### Modular Fragment Structure

Many fragments use a modular subdirectory structure where the main fragment loads related modules:

**Module Organization:**

- Main fragments (e.g., `02-files.ps1`, `05-utilities.ps1`) act as orchestrators
- Related functionality is organized in subdirectories (e.g., `conversion-modules/`, `utilities-modules/`)
- Modules are dot-sourced by the parent fragment during load

**Example Module Loading:**

```powershell
# In 05-utilities.ps1
$utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
if (Test-Path $utilitiesModulesDir) {
    $systemDir = Join-Path $utilitiesModulesDir 'system'
    . (Join-Path $systemDir 'utilities-profile.ps1')
    . (Join-Path $systemDir 'utilities-security.ps1')
    # ... more modules
}
```

**When to Use Modules:**

- Large fragments that can be split into logical groups
- Functionality that's shared across multiple fragments
- Related utilities that belong together (e.g., all conversion functions)
- Code that benefits from better organization

**Module Guidelines:**

- Modules should be idempotent (safe to dot-source multiple times)
- Use `Set-AgentModeFunction` for function registration
- Include error handling for module loading failures
- Document all exported functions with comment-based help

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
- [docs/guides/DEVELOPMENT.md](docs/guides/DEVELOPMENT.md) — Developer guide and advanced testing
- [WARP.md](WARP.md) — WARP development guide
- [AGENTS.md](AGENTS.md) — AI coding assistant guidance
