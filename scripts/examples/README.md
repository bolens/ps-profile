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

### Importing Library Modules

All scripts import required modules from `scripts/lib/` using the modular import pattern. This pattern works from any script location:

```powershell
# Import ModuleImport first (bootstrap) - works from any scripts/ subdirectory
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import specific modules using Import-LibModule (handles path resolution automatically)
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking
```

**Available Library Modules:**
- `ModuleImport.psm1` - Module import helper (import this first)
- `ExitCodes.psm1` - Exit code constants
- `PathResolution.psm1` - Path resolution utilities
- `Logging.psm1` - Logging utilities
- `Module.psm1` - Module management
- `Command.psm1` - Command utilities
- `FileSystem.psm1` - File system operations
- And many more (see `scripts/lib/` directory)

### Getting Repository Root

```powershell
$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
```

### Getting Profile Directory

```powershell
$profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
```

### Standardized Exit Codes

Scripts use standardized exit codes defined in `ExitCodes.psm1`:

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

