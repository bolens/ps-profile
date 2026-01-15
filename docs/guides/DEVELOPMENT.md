# Development Guide

This guide provides information for developers working on the PowerShell profile codebase.

## Prerequisites

Before starting development, ensure you have:

- PowerShell 7.0 or higher
- Git
- Access to PowerShell Gallery (for module installation)

## Initial Setup

### 1. Clone the Repository

```powershell
git clone https://github.com/bolens/ps-profile.git $HOME\Documents\PowerShell
```

### 2. Install Development Dependencies

Run the setup script to install required modules:

```powershell
pwsh -NoProfile -File scripts\dev\setup.ps1
```

Or manually install:

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
Install-Module -Name Pester -Scope CurrentUser -Force
```

### 3. Validate Dependencies

Check that all required dependencies are installed:

```powershell
pwsh -NoProfile -File scripts\utils\validate-dependencies.ps1
```

To automatically install missing modules:

```powershell
pwsh -NoProfile -File scripts\utils\validate-dependencies.ps1 -InstallMissing
```

## Development Workflow

### Running Tests

Run all tests:

```powershell
pwsh -NoProfile -File scripts\utils\run-pester.ps1
```

Run only the unit suite:

```powershell
pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Suite Unit
```

Run only the integration suite:

```powershell
pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Suite Integration
```

Run only the performance suite:

```powershell
pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Suite Performance
```

Run a specific test file:

```powershell
pwsh -NoProfile -File scripts\utils\run-pester.ps1 -TestFile tests\unit\library-common.tests.ps1
```

Run tests with code coverage:

```powershell
pwsh -NoProfile -File scripts\utils\run-pester.ps1 -Coverage
```

Or use task runner shortcuts (works with task, just, make, npm run):

```powershell
task test-unit         # Unit suite only (or: just test-unit, make test-unit, npm run test-unit)
task test-integration  # Integration suite only
task test-performance  # Performance suite only
```

### Advanced Testing Features

The test runner (`scripts/utils/code-quality/run-pester.ps1`) includes advanced features for robust testing:

#### Retry Logic

Handle flaky tests by automatically retrying failures:

```powershell
# Retry failed tests up to 3 times
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -RetryOnFailure

# Use exponential backoff for retries
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -ExponentialBackoff
```

#### Performance Monitoring

Track execution time, memory, and CPU usage:

```powershell
# Track performance metrics
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TrackPerformance

# Include memory and CPU tracking
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TrackPerformance -TrackMemory -TrackCPU
```

#### Performance Baselining

Detect performance regressions by comparing against a baseline:

```powershell
# Generate a baseline
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -GenerateBaseline -BaselinePath "baseline.json"

# Compare against baseline (fail if >10% slower)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CompareBaseline -BaselineThreshold 10
```

#### Environment Health Checks

Validate the test environment before running:

```powershell
# Run health checks
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -HealthCheck

# Fail if health checks don't pass
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -HealthCheck -StrictMode
```

#### Analysis and Reporting

Generate detailed reports and analysis:

```powershell
# Generate HTML report with analysis
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults -ReportFormat HTML -ReportPath "test-report.html"
```

### Code Quality Checks

Run linting:

```powershell
pwsh -NoProfile -File scripts\utils\run-lint.ps1
```

Run formatting:

```powershell
pwsh -NoProfile -File scripts\utils\run-format.ps1
```

Run security scan:

```powershell
pwsh -NoProfile -File scripts\utils\run-security-scan.ps1
```

Run all quality checks (works with task, just, make, npm run):

```powershell
task quality-check    # or: just quality-check, make quality-check, npm run quality-check
```

### Code Standards

#### Importing Library Modules

Use the modular import pattern that works from any script location:

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

This pattern works for scripts in any subdirectory (`scripts/utils/`, `scripts/checks/`, `scripts/git/`, etc.).

#### Exit Codes

Always use `Exit-WithCode` instead of direct `exit` calls:

```powershell
# Good
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Operation completed"

# Bad
exit 0
```

Available exit codes:

- `$EXIT_SUCCESS` (0) - Operation succeeded
- `$EXIT_VALIDATION_FAILURE` (1) - Validation failed
- `$EXIT_SETUP_ERROR` (2) - Setup/configuration error
- `$EXIT_RUNTIME_ERROR` (3) - Runtime error

#### Error Handling

Wrap risky operations in try-catch blocks:

```powershell
try {
    $result = Get-Content -Path $file -ErrorAction Stop
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

#### Function Output Types

Always specify `[OutputType()]` attributes:

```powershell
function Get-Example {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Input
    )
    # Function body
}
```

#### Logging

Use `Write-ScriptMessage` for consistent logging:

```powershell
Write-ScriptMessage -Message "Processing files..." -LogLevel Info
Write-ScriptMessage -Message "Warning: deprecated feature" -IsWarning
Write-ScriptMessage -Message "Error: validation failed" -IsError
```

For file logging:

```powershell
Write-ScriptMessage -Message "Log entry" -LogFile "script.log" -AppendLog -MaxLogFileSizeMB 10
```

## Creating New Scripts

### Using VS Code Snippets

1. Type `psprofile` and press Tab to insert a PowerShell profile script template
2. Type `psfunc` and press Tab to insert a function template
3. Type `pstry` and press Tab to insert a try-catch block
4. Type `pstest` and press Tab to insert a Pester test template

### Script Template

```powershell
<#
scripts/utils/code-quality/your-script.ps1

.SYNOPSIS
    Brief description of what the script does.

.DESCRIPTION
    Detailed description of the script's functionality.

.PARAMETER ParameterName
    Description of the parameter.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\your-script.ps1

    Example usage.

.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): Operation succeeded
    - 1 (EXIT_VALIDATION_FAILURE): Validation failed
    - 2 (EXIT_SETUP_ERROR): Setup error
#>

param(
    [Parameter(Mandatory)]
    [string]$ParameterName
)

# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import required modules
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Script logic here

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Script completed successfully"
```

## Creating New Profile Fragments

Use the `new-fragment.ps1` script:

```powershell
pwsh -NoProfile -File scripts\utils\new-fragment.ps1 -Name 'my-feature' -Number 50
```

This creates:

- `profile.d/50-my-feature.ps1` - The fragment file
- `profile.d/50-my-feature.ps1.README.md` - Documentation template

## Code Metrics

Collect code metrics:

```powershell
pwsh -NoProfile -File scripts\utils\collect-code-metrics.ps1
```

This generates `scripts/data/code-metrics.json` with:

- Total files, lines, functions
- Complexity metrics
- Duplicate function detection
- Per-file metrics

## Performance Benchmarking

Benchmark profile startup performance:

```powershell
pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1 -Iterations 5
```

Update performance baseline:

```powershell
pwsh -NoProfile -File scripts\utils\benchmark-startup.ps1 -Iterations 5 -UpdateBaseline
```

Performance regression tests respect optional thresholds:

- `PS_PROFILE_MAX_LOAD_MS` (default 6000)
- `PS_PROFILE_MAX_FRAGMENT_MS` (default 500)

## Documentation Generation

Generate API documentation:

```powershell
pwsh -NoProfile -File scripts\utils\generate-docs.ps1
```

Generate fragment READMEs:

```powershell
pwsh -NoProfile -File scripts\utils\generate-fragment-readmes.ps1
```

## Common Tasks

### Pre-commit Checks

Before committing, run (works with task, just, make, npm run):

```powershell
task format-and-lint    # or: just format-and-lint, make format-and-lint, npm run format-and-lint
```

Or manually:

```powershell
pwsh -NoProfile -File scripts\utils\run-format.ps1
pwsh -NoProfile -File scripts\utils\run-lint.ps1
```

### Full Validation

Run all validation checks (works with task, just, make, npm run):

```powershell
task validate    # or: just validate, make validate, npm run validate
```

### Update Dependencies

Check for module updates:

```powershell
pwsh -NoProfile -File scripts\utils\check-module-updates.ps1 -DryRun
```

Update modules:

```powershell
pwsh -NoProfile -File scripts\utils\check-module-updates.ps1 -Update
```

## Troubleshooting

### Module Installation Issues

If modules fail to install:

1. Check PowerShell Gallery access:

   ```powershell
   Get-PSRepository -Name PSGallery
   ```

2. Register PSGallery if needed:
   ```powershell
   Register-PSRepository -Default
   Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
   ```

### Test Failures

If tests fail:

1. Check Pester version:

   ```powershell
   Get-Module -ListAvailable Pester
   ```

2. Update Pester if needed:
   ```powershell
   Update-Module -Name Pester -Force
   ```

### Path Resolution Issues

If `Get-RepoRoot` fails:

- Ensure you're running scripts from the repository root or a subdirectory
- Check that `.git` directory exists in the repository root
- Verify script path resolution using `$PSScriptRoot`

## Additional Resources

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [requirements/](../requirements/) - Modular dependency requirements structure
