# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Using Tasks (Recommended)

**VS Code**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → select a task

**Taskfile**: Run `task <task-name>` (e.g., `task lint`, `task validate`)

**Common Tasks**:

- `quality-check` - Full quality check (format + security + lint + spellcheck + markdownlint + help + tests)
- `validate` - Validation (format + security + lint + spellcheck + help + idempotency)
- `format-and-lint` - Format and lint code (common pre-commit workflow)
- `all-docs` - Generate all documentation (API docs + fragment READMEs)
- `test` - Run Pester tests
- `test-coverage` - Run tests with coverage
- `benchmark` - Performance benchmark
- `update-baseline` - Update performance baseline
- `check-idempotency` - Check fragment idempotency
- `format` - Format code
- `lint` - Lint code
- `spellcheck` - Run spellcheck
- `markdownlint` - Run markdownlint
- `pre-commit-checks` - Run pre-commit checks manually
- `check-module-updates` - Check for module updates
- `install-module-updates` - Install module updates
- `generate-docs` - Generate API documentation
- `generate-changelog` - Generate changelog
- `find-duplicates` - Find duplicate functions

### Direct Script Execution

```powershell
# Full validation (format + security + lint + idempotency)
pwsh -NoProfile -File scripts/checks/validate-profile.ps1

# Individual checks
pwsh -NoProfile -File scripts/utils/run-format.ps1          # PowerShell-Beautifier
pwsh -NoProfile -File scripts/utils/run-lint.ps1            # PSScriptAnalyzer
pwsh -NoProfile -File scripts/utils/run-security-scan.ps1   # Security analysis
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1  # Idempotency test
pwsh -NoProfile -File scripts/utils/spellcheck.ps1          # Spellcheck
pwsh -NoProfile -File scripts/utils/run-markdownlint.ps1    # Markdownlint

# Run tests
pwsh -NoProfile -File scripts/utils/run_pester.ps1
pwsh -NoProfile -File scripts/utils/run_pester.ps1 -Coverage

# Check for module updates
pwsh -NoProfile -File scripts/utils/check-module-updates.ps1
```

### Git Hooks

```powershell
# Install pre-commit, pre-push, and commit-msg hooks
pwsh -NoProfile -File scripts/git/install-githooks.ps1

# On Unix-like systems, make hooks executable after installation:
chmod +x .git/hooks/*
```

### Performance Benchmarking

```powershell
# Measure startup performance (30 iterations recommended)
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 30
# Outputs: scripts/data/startup-benchmark.csv

# Update performance baseline after optimizations
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -UpdateBaseline
# Or use task: task update-baseline
```

### Documentation Generation

```powershell
# Generate API documentation from comment-based help
pwsh -NoProfile -File scripts/utils/generate-docs.ps1
# Outputs: docs/*.md
```

### Testing Profile Changes

```powershell
# Reload profile in current session
. $PROFILE
```

## Code Architecture

### Core Structure

- **Microsoft.PowerShell_profile.ps1**: Main profile entrypoint. Loads fragments from `profile.d/` in sorted order with error handling. Keep this file minimal.
- **profile.d/**: Modular fragments loaded in lexical order (00-99). Each fragment is idempotent and safe to dot-source multiple times.
- **scripts/**: Validation, testing, and utility scripts. These run with `-NoProfile` to ensure consistent environment.

### Profile Fragment Loading Order

Fragments use numeric prefixes to control load order:

- **00-09**: Core bootstrap, environment, and helpers
- **10-19**: Terminal configuration (PSReadLine, prompts, Git)
- **20-29**: Container engines, cloud tools
- **30-39**: Development tools and aliases
- **40-69**: Language-specific tools (Go, PHP, Node.js, Python, Rust)
- **60-69**: Modern CLI tools (eza, navi, gum, pixi, uv, pnpm)

### Key Patterns

#### Bootstrap Helpers (00-bootstrap.ps1)

Three collision-safe registration helpers are available to all fragments:

1. **Set-AgentModeFunction**: Creates functions without overwriting existing commands

   ```powershell
   Set-AgentModeFunction -Name 'MyFunc' -Body { Write-Output "Hello" }
   ```

2. **Set-AgentModeAlias**: Creates aliases or function wrappers without overwriting

   ```powershell
   Set-AgentModeAlias -Name 'gs' -Target 'git status'
   ```

3. **Test-CachedCommand**: Fast command existence check with caching

   ```powershell
   if (Test-CachedCommand 'docker') { # configure docker helpers }
   ```

#### Fragment Idempotency

All fragments MUST be idempotent (safe to source multiple times). Use:

- `Set-AgentModeFunction` / `Set-AgentModeAlias` for registration
- `Test-Path Function:\Name` or `Test-Path Alias:\Name` for fast provider checks
- `Get-Command -ErrorAction SilentlyContinue` guards for external tools

#### Performance Optimizations

- **Lazy Loading**: Expensive initialization deferred behind Enable-\* functions
- **Provider-First Checks**: Use `Test-Path Function:\Name` to avoid module autoload
- **Cached Commands**: Use `Test-CachedCommand` to avoid repeated Get-Command calls
- **No Side Effects at Load**: Keep fragment dot-sourcing fast; defer work to functions

Example lazy loading pattern:

```powershell
# In fragment: register enabler function only
Set-AgentModeFunction -Name 'Enable-MyTool' -Body {
    # Expensive work happens here when user calls Enable-MyTool
    Import-Module MyExpensiveModule
    Set-AgentModeAlias -Name 'mt' -Target 'mytool'
}
```

### Container Engine Support

Fragments in `profile.d/22-containers.ps1` and `profile.d/24-container-utils.ps1` provide:

- Auto-detection of Docker or Podman with compose support
- Unified aliases (dcu, dcd, dcl, dps, dprune, etc.) that work with either engine
- `Set-ContainerEnginePreference docker|podman` to force preference
- `Test-ContainerEngine` to inspect current engine/compose configuration

### Prompt Frameworks

Two prompt systems are supported with lazy initialization:

- **oh-my-posh** (06-oh-my-posh.ps1): Use `Initialize-OhMyPosh` to activate
- **Starship** (23-starship.ps1): Use `Initialize-Starship` to activate

### PSScriptAnalyzer Configuration

`PSScriptAnalyzerSettings.psd1` disables noisy rules for interactive profile code:

- Allows cmdlet aliases
- Allows Write-Host for user feedback
- Per-file suppressions for known acceptable patterns

### Debug & Instrumentation

- **PS_PROFILE_DEBUG=1**: Enable verbose output from bootstrap helpers
  - Local: Uses `Write-Verbose` (requires `$VerbosePreference = 'Continue'`)
  - CI: Writes to stdout for GitHub Actions logs
- **PS_PROFILE_DEBUG_TIMINGS=1**: Enable micro-instrumentation CSV output

## Commit Messages

Use Conventional Commits format:

```text
feat(cli): add new command
fix: correct edge-case handling
docs: update README
```

Merge and revert commits are allowed.

## CI/CD

- GitHub Actions workflows validate on Windows (PowerShell 5.1 & pwsh) and Linux (pwsh)
- Workflows install PSScriptAnalyzer and PowerShell-Beautifier
- Validation runs: format check, security scan, lint, idempotency test, fragment README check
- Documentation artifacts are uploaded for review

## Important File Locations

- **PSScriptAnalyzerSettings.psd1**: Linter configuration
- **CONTRIBUTING.md**: Detailed contribution guidelines
- **PROFILE_README.md**: Comprehensive profile documentation
- **PROFILE_DEBUG.md**: Debug and instrumentation guide
- **.github/workflows/**: CI workflows
