# profile.d/ — Modular Profile Fragments

This directory contains small, focused PowerShell scripts that are dot-sourced from `Microsoft.PowerShell_profile.ps1` during interactive session startup.

> **Note:** This profile is under active development and may be unstable. See [README.md](../README.md#powershell-profile) for the full warning.

## Loading Order

Fragments use **dependency-aware loading**, not filename sorting alone. Each fragment can declare dependencies and a tier in its header; the loader resolves load order with topological sorting (see [ARCHITECTURE.md](../ARCHITECTURE.md) and [PROFILE_README.md](../PROFILE_README.md)).

```powershell
# Dependencies: bootstrap, env
# Tier: standard
```

**Typical tiers** (for batch loading and environment presets):

- **Core (Tier 0)**: Bootstrap and registration (`bootstrap.ps1`)
- **Essential (Tier 1)**: Environment, files, utilities (`env.ps1`, `files.ps1`, `utilities.ps1`)
- **Standard (Tier 2)**: Common dev tools (`git.ps1`, `containers.ps1`, `aws.ps1`, …)
- **Optional (Tier 3)**: Advanced features (`performance-insights.ps1`, `system-monitor.ps1`, …)

Fragments are named by concern (e.g. `git.ps1`, `lang-python-env.ps1`), not numeric prefix. Disable fragments or choose environment presets via `.profile-fragments.json` or `$env:PS_PROFILE_ENVIRONMENT`.

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
- **`kubernetes-modules/`** - Kubernetes helper modules (loaded by `kubernetes-enhanced.ps1`)
  - `kube-context.ps1` - Context and namespace switching
  - `kube-logs.ps1` - Log tailing helpers
  - `kube-workloads.ps1` - Resource operations (get, exec, apply)
  - `kube-console.ps1` - Minikube and k9s launchers
- **`cloud-modules/`** - Cloud deployment modules (loaded by `cloud-enhanced.ps1`)
  - `cloud-azure.ps1` - Azure subscription switching
  - `cloud-gcp.ps1` - GCP project switching
  - `cloud-deploy.ps1` - Doppler, Heroku, Vercel, Netlify deploy helpers
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
- **`git-modules/`** - Git integration modules (loaded by `git.ps1`, `git-enhanced.ps1`)
  - `core/` - Core Git operations (basic, advanced, helpers)
  - `enhanced/` - Enhanced Git tools (changelog, GUI launchers, workflow helpers)
  - `integrations/` - Git service integrations (GitHub)
- **`utilities-modules/`** - Utility function modules (loaded by `utilities.ps1`, `network-utils.ps1`, `history-enhanced.ps1`)
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
