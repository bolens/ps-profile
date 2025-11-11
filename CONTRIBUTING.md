# Contributing

Thank you for contributing to this PowerShell profile project.

## Prerequisites

All validation scripts automatically install required modules (PSScriptAnalyzer, PowerShell-Beautifier, Pester) to `CurrentUser` scope if missing.

## Utility Script Standards

### Shared Utilities

Utility scripts should use the shared `scripts/lib/Common.psm1` module for common functionality.

**Import Pattern by Script Location:**

```powershell
# Scripts in scripts/utils/ subdirectories (e.g., code-quality/, metrics/)
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Scripts in scripts/checks/ - Common.psm1 is in scripts/lib/
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Scripts in scripts/git/ - Common.psm1 is in scripts/lib/
$scriptsDir = Split-Path -Parent $PSScriptRoot
$commonModulePath = Join-Path $scriptsDir 'lib' 'Common.psm1'
if (-not (Test-Path $commonModulePath)) {
    throw "Common module not found at: $commonModulePath"
}
Import-Module (Resolve-Path $commonModulePath).Path -ErrorAction Stop

# Scripts in scripts/lib/ - Common.psm1 is in the same directory
$commonModulePath = Join-Path $PSScriptRoot 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

# Use shared functions
$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
```

The Common module provides:

- `Get-RepoRoot` - Consistent repository root path resolution
- `Ensure-ModuleAvailable` - Module installation and import
- `Test-CommandAvailable` - Check if a command is available on the system
- `Ensure-DirectoryExists` - Create directory if it doesn't exist
- `Get-PowerShellExecutable` - Get PowerShell executable name (pwsh/powershell)
- `Test-PathExists` - Path validation with descriptive errors
- `Test-RequiredParameters` - Validate required parameters are not null or empty
- `Write-ScriptMessage` - Consistent output formatting (supports warnings and errors)
- `Exit-WithCode` - Standardized exit code handling

### Exit Code Standards

All utility scripts must use standardized exit codes for consistency:

- **0** (`EXIT_SUCCESS`) - Script completed successfully
- **1** (`EXIT_VALIDATION_FAILURE`) - Validation or check failure (expected, e.g., lint errors found)
- **2** (`EXIT_SETUP_ERROR`) - Setup or configuration error (unexpected, e.g., module installation failed)
- **3+** (`EXIT_OTHER_ERROR`) - Reserved for specific error types

**Usage:**

```powershell
# Success
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "All checks passed"

# Validation failure (expected)
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Lint errors found"

# Setup error (unexpected)
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

### Path Resolution

Use `$PSScriptRoot` (PowerShell 3.0+) for path resolution, or use `Get-RepoRoot` from the Common module:

```powershell
# Preferred: Use Common module
$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot

# Alternative: Direct calculation (if not using Common module)
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
```

### Parameter Validation

Add parameter validation for paths and other inputs:

```powershell
param(
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null
)
```

For more complex validation, use the `Test-PathExists` helper:

```powershell
try {
    Test-PathExists -Path $configFile -PathType 'File'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

### Common Helper Functions

Use helper functions from the Common module for common operations:

**Command Availability:**

```powershell
if (Test-CommandAvailable -CommandName 'git') {
    & git --version
}
```

**Directory Creation:**

```powershell
Ensure-DirectoryExists -Path (Join-Path $repoRoot 'output')
```

**PowerShell Executable:**

```powershell
$psExe = Get-PowerShellExecutable
& $psExe -NoProfile -File $scriptPath
```

**Warning/Error Messages:**

```powershell
Write-ScriptMessage -Message "Warning: deprecated feature" -IsWarning
Write-ScriptMessage -Message "Error: validation failed" -IsError
```

**Required Parameter Validation:**

```powershell
try {
    Test-RequiredParameters -Parameters @{ Path = $Path; Name = $Name }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

**Path Parameter Validation:**

For path parameters, use ValidateScript with Test-Path:

```powershell
param(
    [ValidateScript({
            if ($_ -and -not (Test-Path $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null
)
```

Or validate after import using Test-PathExists:

```powershell
try {
    Test-PathExists -Path $configFile -PathType 'File'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

### Error Handling Standards

**Always use try-catch for risky operations:**

```powershell
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

**Never use direct `exit` calls - always use `Exit-WithCode`:**

```powershell
# ❌ Bad
if ($error) { exit 1 }

# ✅ Good
if ($error) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"
}
```

**Exception:** Git hook templates that generate shell scripts may use `exit 0` or `exit 1` in here-strings, as these are part of the generated script, not the PowerShell script itself.

## Local Validation

Run these checks before opening a PR:

### Using Tasks (Recommended)

**VS Code**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → select a task  
**Taskfile**: Run `task <task-name>`

```powershell
# Full quality check (recommended before PR)
task quality-check

# Or individual tasks
task validate                # Full validation (format + security + lint + spellcheck + help + idempotency)
task format                  # Format code
task lint                    # Lint code
task test                    # Run tests
task test-coverage           # Run tests with coverage
task spellcheck              # Spellcheck
task markdownlint            # Markdownlint
task validate-function-naming # Validate function naming conventions
task pre-commit-checks       # Run pre-commit checks manually
```

### Direct Script Execution

```powershell
# Full validation (format + security + lint + idempotency)
pwsh -NoProfile -File scripts/checks/validate-profile.ps1

# Individual checks
pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1          # Format code
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1        # Security scan
pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1                    # Lint (PSScriptAnalyzer)
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1                       # Idempotency test
pwsh -NoProfile -File scripts/utils/code-quality/run_pester.ps1                  # Run tests
pwsh -NoProfile -File scripts/utils/code-quality/spellcheck.ps1                  # Spellcheck
pwsh -NoProfile -File scripts/utils/code-quality/run-markdownlint.ps1            # Markdownlint
pwsh -NoProfile -File scripts/utils/code-quality/validate-function-naming.ps1   # Validate function naming
```

## Git Hooks

Install pre-commit, pre-push, and commit-msg hooks:

```powershell
pwsh -NoProfile -File scripts/git/install-githooks.ps1

# On Unix-like systems, make hooks executable:
chmod +x .git/hooks/*
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```text
feat(cli): add new command
fix: correct edge-case handling
docs: update README
refactor: simplify bootstrap logic
```

Merge and revert commits are allowed (messages starting with "Merge " or "Revert ").

## Code Style

### Fragment Guidelines

- **Idempotency**: Fragments must be safe to dot-source multiple times
  - Use `Set-AgentModeFunction` / `Set-AgentModeAlias` from `00-bootstrap.ps1`
  - Guard with `Get-Command -ErrorAction SilentlyContinue` or `Test-Path Function:\Name`
- **No Side Effects**: Avoid expensive operations during dot-sourcing
  - Defer heavy work behind `Enable-*` functions (lazy loading pattern)
  - Keep early fragments (00-09) lightweight
- **External Tools**: Always check availability before invoking

  ```powershell
  if (Test-CachedCommand 'docker') { # configure docker helpers }
  ```

### Fragment Naming

Use numeric prefixes to control load order:

- `00-09`: Core bootstrap and helpers
- `10-19`: Terminal and Git configuration
- `20-29`: Container engines and cloud tools
- `30-69`: Development tools and language-specific utilities

## Adding New Fragments

1. Create a new `.ps1` file in `profile.d/` with appropriate numeric prefix
2. Keep it focused on a single concern (e.g., `45-nextjs.ps1` for Next.js helpers)
3. Add a `README.md` in `profile.d/` documenting the fragment (optional but recommended)
4. Ensure idempotency and guard external tool calls
5. Run validation before committing

## Documentation

- Function/alias documentation is auto-generated from comment-based help
- Run `task generate-docs` or `pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1` to regenerate
- See [PROFILE_README.md](PROFILE_README.md) for detailed technical information

## Questions

Open an issue or draft PR if you need guidance. Tag maintainers for review.

