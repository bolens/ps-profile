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
pwsh -NoProfile -File scripts\utils\run_pester.ps1
```

Run a specific test file:

```powershell
pwsh -NoProfile -File scripts\utils\run_pester.ps1 -TestFile tests\Common.tests.ps1
```

Run tests with code coverage:

```powershell
pwsh -NoProfile -File scripts\utils\run_pester.ps1 -Coverage
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

Run all quality checks:

```powershell
task quality-check
```

### Code Standards

#### Importing Common.psm1

Use the appropriate import pattern based on script location:

**Scripts in `scripts/utils/`:**

```powershell
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop
```

**Scripts in `scripts/checks/` or `scripts/git/`:**

```powershell
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'utils' 'Common.psm1'
Import-Module (Resolve-Path $commonModulePath).Path -ErrorAction Stop
```

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

# Import shared utilities
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

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

Before committing, run:

```powershell
task format-and-lint
```

Or manually:

```powershell
pwsh -NoProfile -File scripts\utils\run-format.ps1
pwsh -NoProfile -File scripts\utils\run-lint.ps1
```

### Full Validation

Run all validation checks:

```powershell
task validate
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
- [CODEBASE_IMPROVEMENTS.md](../CODEBASE_IMPROVEMENTS.md) - Planned improvements
- [requirements.psd1](../requirements.psd1) - Dependency requirements
