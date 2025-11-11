# Script Usage Examples

This directory contains examples demonstrating how to use various utility and validation scripts in the PowerShell profile project.

## Running Scripts

All scripts should be run from the repository root using PowerShell:

```powershell
# Run a utility script
pwsh -NoProfile -File scripts/utils/script-name.ps1 -Parameter "value"

# Run a validation script
pwsh -NoProfile -File scripts/checks/check-name.ps1

# Run with verbose output
pwsh -NoProfile -File scripts/utils/script-name.ps1 -Verbose
```

## Common Patterns

### Importing Common.psm1

All scripts import the shared Common.psm1 module. The import pattern depends on the script's location:

**For scripts in scripts/utils/ subdirectories (e.g., code-quality/, metrics/):**

```powershell
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
```

**For scripts in scripts/checks/:**

```powershell
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
```

**For scripts in scripts/git/:**

```powershell
$scriptsDir = Split-Path -Parent $PSScriptRoot
$commonModulePath = Join-Path $scriptsDir 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
```

### Getting Repository Root

```powershell
$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
```

### Getting Profile Directory

```powershell
$profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
```

### Standardized Exit Codes

Scripts use standardized exit codes defined in Common.psm1:

- `$EXIT_SUCCESS` (0) - Success
- `$EXIT_VALIDATION_FAILURE` (1) - Validation/check failure (expected)
- `$EXIT_SETUP_ERROR` (2) - Setup/configuration error (unexpected)
- `$EXIT_OTHER_ERROR` (3) - Other errors

```powershell
Exit-WithCode -ExitCode $EXIT_SUCCESS
```

### Logging

Use Write-ScriptMessage for consistent output:

```powershell
Write-ScriptMessage -Message "Operation started" -LogLevel Info
Write-ScriptMessage -Message "Warning condition" -LogLevel Warning
Write-ScriptMessage -Message "Error occurred" -LogLevel Error
```

## Example Scripts

### Validation Scripts

**Run all validation checks:**

```powershell
pwsh -NoProfile -File scripts/checks/validate-profile.ps1
```

**Check script standards:**

```powershell
pwsh -NoProfile -File scripts/checks/check-script-standards.ps1
```

**Check commit messages:**

```powershell
pwsh -NoProfile -File scripts/checks/check-commit-messages.ps1 -Base "origin/main"
```

### Utility Scripts

**Run linting:**

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1
```

**Run formatting:**

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1
```

**Check for module updates:**

```powershell
pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1
```

**Generate documentation:**

```powershell
pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1 -OutputPath "docs"
```

**Run security scan:**

```powershell
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1 -Path "profile.d"
```

**Benchmark startup performance:**

```powershell
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 30
```

**Collect code metrics:**

```powershell
pwsh -NoProfile -File scripts/utils/metrics/collect-code-metrics.ps1
```

**Export metrics:**

```powershell
pwsh -NoProfile -File scripts/utils/metrics/export-metrics.ps1 -OutputPath "metrics.json"
```

## Git Hooks

**Install git hooks:**

```powershell
pwsh -NoProfile -File scripts/git/install-githooks.ps1
```

**Install pre-commit hook:**

```powershell
pwsh -NoProfile -File scripts/git/install-pre-commit-hook.ps1
```

## Development Setup

**Set up development environment:**

```powershell
pwsh -NoProfile -File scripts/dev/setup.ps1
```

