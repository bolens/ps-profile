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

Keep each fragment focused on a single concern (e.g., `git.ps1` for Git helpers, `containers.ps1` for container utilities).

## Bootstrap Helpers

Available from `bootstrap.ps1`:

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

## Modular Subdirectory Structure

Many fragments have been refactored to use organized subdirectories for better code organization. Main fragments load modules from these subdirectories:

### Module Subdirectories

- **`cli-modules/`** - Modern CLI tool integrations (loaded by `modern-cli.ps1`)
- **`container-modules/`** - Container helper modules (loaded by `containers.ps1`)
  - `container-compose.ps1` - Docker Compose helpers
  - `container-compose-podman.ps1` - Podman Compose helpers
  - `container-helpers.ps1` - General container utilities
- **`conversion-modules/`** - Format conversion utilities (loaded by `files.ps1`)
  - `data/` - Data format conversions (binary, columnar, structured, scientific)
  - `document/` - Document format conversions (Markdown, LaTeX, RST)
  - `helpers/` - Conversion helper utilities (XML, TOML)
  - `media/` - Media format conversions (audio, images, PDF, video)
- **`dev-tools-modules/`** - Development tool integrations (loaded by `files.ps1`, `testing.ps1`, `build-tools.ps1`)
  - `build/` - Build tools and testing frameworks
  - `crypto/` - Cryptographic utilities (hash, JWT)
  - `data/` - Data manipulation tools (lorem, units, UUID, timestamps)
  - `encoding/` - Encoding utilities
  - `format/` - Formatting tools (diff, regex, QR codes)
- **`diagnostics-modules/`** - Diagnostic and monitoring modules (loaded by `diagnostics.ps1`, `error-handling.ps1`, `performance-insights.ps1`, `system-monitor.ps1`)
  - `core/` - Core diagnostics (error handling, profile diagnostics)
  - `monitoring/` - System monitoring (performance, system monitor)
- **`files-modules/`** - File operation modules (loaded by `files.ps1`)
  - `inspection/` - File inspection utilities (hash, head/tail, hexdump, size)
  - `navigation/` - File navigation helpers (listing, navigation)
- **`git-modules/`** - Git integration modules (loaded by `git.ps1`)
  - `core/` - Core Git operations (basic, advanced, helpers)
  - `integrations/` - Git service integrations (GitHub)
- **`utilities-modules/`** - Utility function modules (loaded by `utilities.ps1`, `network-utils.ps1`, `enhanced-history.ps1`)
  - `data/` - Data utilities (datetime, encoding)
  - `filesystem/` - Filesystem utilities
  - `history/` - Command history utilities (basic, enhanced)
  - `network/` - Network utilities (basic, advanced)
  - `system/` - System utilities (env, profile, security)

### Module Loading Pattern

Modules are loaded by their parent fragments using dot-sourcing:

```powershell
# Example from utilities.ps1
$utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
if (Test-Path $utilitiesModulesDir) {
    $systemDir = Join-Path $utilitiesModulesDir 'system'
    . (Join-Path $systemDir 'utilities-profile.ps1')
    . (Join-Path $systemDir 'utilities-security.ps1')
    # ... more modules
}
```

### Adding New Modules

1. Identify the appropriate subdirectory (or create new one if needed)
2. Create module file following existing patterns
3. Update parent fragment to load the module
4. Use `Set-AgentModeFunction` for function registration
5. Include error handling for module loading
6. Document functions with comment-based help

## Local Overrides

The `local-overrides.ps1` fragment is **disabled by default** due to performance issues (100+ second delays on some filesystems when the file doesn't exist). To enable it:

1. Set the environment variable: `PS_PROFILE_ENABLE_LOCAL_OVERRIDES=1` in your `.env` file
2. Create `profile.d/local-overrides.ps1` with your machine-specific customizations

**Note**: Only enable this if you actually have a `local-overrides.ps1` file to load. The fragment is intended for machine-specific tweaks and should be added to `.gitignore` if you plan to keep secrets or local-only settings there.

## Documentation

- Fragment-level README files are optional but recommended
- Function/alias documentation is auto-generated from comment-based help
- See [PROFILE_README.md](../PROFILE_README.md) for detailed technical information
- See [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines
