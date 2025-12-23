# Contributing

Thank you for contributing to this PowerShell profile project.

## Prerequisites

All validation scripts automatically install required modules (PSScriptAnalyzer, PowerShell-Beautifier, Pester) to `CurrentUser` scope if missing.

## Utility Script Standards

### Shared Utilities

Utility scripts should use the modular library modules from `scripts/lib/` for common functionality.

**Import Pattern (Works for All Script Locations):**

**Recommended Pattern (New - Simplified):**

```powershell
# Import ModuleImport first (bootstrap) - works from any scripts/ subdirectory
$moduleImportPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Initialize script environment (recommended for new scripts)
$env = Initialize-ScriptEnvironment `
    -ScriptPath $PSScriptRoot `
    -ImportModules @('ExitCodes', 'PathResolution', 'Logging', 'Module') `
    -GetRepoRoot `
    -DisableNameChecking `
    -ExitOnError

$repoRoot = $env.RepoRoot
Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
```

**Alternative Pattern (Batch Import):**

```powershell
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import multiple modules at once
Import-LibModules -ModuleNames @('ExitCodes', 'PathResolution', 'Logging', 'Module') -ScriptPath $PSScriptRoot -DisableNameChecking

# Get repository root with error handling
$repoRoot = Get-RepoRootSafe -ScriptPath $PSScriptRoot -ExitOnError
Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
```

**Legacy Pattern (Still Supported):**

```powershell
# Import ModuleImport first (bootstrap) - works from any scripts/ subdirectory
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import specific modules using Import-LibModule (handles path resolution automatically)
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking

# Use shared functions
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
```

**Note:** See `docs/USAGE_EXAMPLES.md` for comprehensive examples and migration guide.

**Available Library Modules:**

- `ModuleImport.psm1` - Module import helper (`Import-LibModule`, `Import-LibModules`, `Initialize-ScriptEnvironment`, `Get-LibPath`) - **import this first**
- `ExitCodes.psm1` - Exit code constants (`Exit-WithCode`, `$EXIT_SUCCESS`, etc.)
- `PathResolution.psm1` - Path resolution (`Get-RepoRoot`, `Get-RepoRootSafe`, `Get-ProfileDirectory`)
- `Logging.psm1` - Logging utilities (`Write-ScriptMessage`)
- `Module.psm1` - Module management (`Ensure-ModuleAvailable`)
- `Command.psm1` - Command utilities (`Test-CommandAvailable`)
- `FileSystem.psm1` - File system operations (`Ensure-DirectoryExists`, `Test-PathExists`)
- `PathUtilities.psm1` - Path manipulation utilities
- `Platform.psm1` - Platform detection (`Get-PowerShellExecutable`)
- And many more specialized modules (39 total modules, see `scripts/lib/` directory)

**New Helper Functions:**

- `Initialize-ScriptEnvironment` - One-stop script initialization (recommended for new scripts)
- `Import-LibModules` - Batch import multiple modules at once
- `Get-RepoRootSafe` - Safe repository root getter with error handling
- `ScriptPath` parameter is now optional in `Import-LibModule` and `Import-LibModules` (auto-detection available)

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

Use `$PSScriptRoot` (PowerShell 3.0+) for path resolution, or use `Get-RepoRoot` from the `PathResolution.psm1` module:

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

Use helper functions from the library modules for common operations:

**Command Availability (from Command.psm1):**

```powershell
if (Test-CommandAvailable -CommandName 'git') {
    & git --version
}
```

**Directory Creation (from FileSystem.psm1):**

```powershell
Ensure-DirectoryExists -Path (Join-Path $repoRoot 'output')
```

**PowerShell Executable (from Platform.psm1):**

```powershell
$psExe = Get-PowerShellExecutable
& $psExe -NoProfile -File $scriptPath
```

**Warning/Error Messages (from Logging.psm1):**

```powershell
Write-ScriptMessage -Message "Warning: deprecated feature" -IsWarning
Write-ScriptMessage -Message "Error: validation failed" -IsError
```

**Required Parameter Validation (from FileSystem.psm1):**

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

This project supports multiple task runners. Choose the one that fits your workflow:

- **Task** (recommended): `task <task-name>`
- **Just**: `just <recipe-name>`
- **Make**: `make <target>`
- **npm/pnpm**: `npm run <script>` or `pnpm run <script>`
- **VS Code**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → select a task
- **Sublime Text**: Tools → Build System → "Task: <name>"

All task runners have full parity - the same 48+ tasks are available in each format.

```powershell
# Full quality check (recommended before PR)
task quality-check    # or: just quality-check, make quality-check, npm run quality-check

# Or individual tasks (all work with task, just, make, npm run)
task validate                 # Full validation (format + security + lint + spellcheck + help + idempotency)
task format                   # Format code
task lint                     # Lint code
task test                     # Run tests
task test-coverage            # Run tests with coverage
task spellcheck               # Spellcheck
task markdownlint             # Markdownlint
task validate-function-naming # Validate function naming conventions
task pre-commit-checks        # Run pre-commit checks manually
```

### Direct Script Execution

```powershell
# Full validation (format + security + lint + idempotency)
pwsh -NoProfile -File scripts/checks/validate-profile.ps1

# Individual checks
pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1                  # Format code
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1               # Security scan
pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1                    # Lint (PSScriptAnalyzer)
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1                       # Idempotency test
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1                  # Run tests
pwsh -NoProfile -File scripts/utils/code-quality/spellcheck.ps1                  # Spellcheck
pwsh -NoProfile -File scripts/utils/code-quality/run-markdownlint.ps1            # Markdownlint
pwsh -NoProfile -File scripts/utils/code-quality/validate-function-naming.ps1    # Validate function naming

# Run specific tests by name (supports wildcards and "or" syntax)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestName "*Edit-Profile*"
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration -TestName "*Backup-Profile* or *Convert-*"
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

```powershell
if (Test-CommandAvailable -CommandName 'git') {
    & git --version
}
```

## Adding New Modules

When adding functionality that belongs in a module subdirectory:

1. **Identify the appropriate subdirectory**:

   - `conversion-modules/` - Data/document/media format conversions
   - `dev-tools-modules/` - Development tool integrations
   - `diagnostics-modules/` - Diagnostic and monitoring utilities
   - `files-modules/` - File operation utilities
   - `git-modules/` - Git integration utilities
   - `utilities-modules/` - General utility functions
   - Or create a new subdirectory if needed

2. **Create module file** in the appropriate subdirectory:

   ```powershell
   # Example: profile.d/conversion-modules/data/core-basic.ps1
   # Use Set-AgentModeFunction for collision-safe registration
   Set-AgentModeFunction -Name 'Convert-DataFormat' -Body {
       # Implementation
   }
   ```

3. **Update parent fragment** to load the module:

   ```powershell
   # In the parent fragment (e.g., 02-files.ps1)
   $conversionModulesDir = Join-Path $PSScriptRoot 'conversion-modules'
   if (Test-Path $conversionModulesDir) {
       $dataDir = Join-Path $conversionModulesDir 'data'
       try {
           . (Join-Path $dataDir 'core-basic.ps1')
       }
       catch {
           Write-SubModuleError -ErrorRecord $_ -ModuleName 'core-basic.ps1'
       }
   }
   ```

4. **Follow module conventions**:

   - Use `Set-AgentModeFunction` for function registration
   - Guard external tool calls with `Test-CachedCommand`
   - Include error handling for module loading
   - Document functions with comment-based help
   - Ensure modules are idempotent (safe to dot-source multiple times)

5. **Test module loading**:
   - Verify module loads correctly
   - Test idempotency (reload profile multiple times)
   - Run validation: `task validate`

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

This project supports multiple task runners. Choose the one that fits your workflow:

- **Task** (recommended): `task <task-name>`
- **Just**: `just <recipe-name>`
- **Make**: `make <target>`
- **npm/pnpm**: `npm run <script>` or `pnpm run <script>`
- **VS Code**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → select a task
- **Sublime Text**: Tools → Build System → "Task: <name>"

All task runners have full parity - the same 48+ tasks are available in each format.

```powershell
# Full quality check (recommended before PR)
task quality-check    # or: just quality-check, make quality-check, npm run quality-check

# Or individual tasks (all work with task, just, make, npm run)
task validate                 # Full validation (format + security + lint + spellcheck + help + idempotency)
task format                   # Format code
task lint                     # Lint code
task test                     # Run tests
task test-coverage            # Run tests with coverage
task spellcheck               # Spellcheck
task markdownlint             # Markdownlint
task validate-function-naming # Validate function naming conventions
task pre-commit-checks        # Run pre-commit checks manually
```

### Direct Script Execution

```powershell
# Full validation (format + security + lint + idempotency)
pwsh -NoProfile -File scripts/checks/validate-profile.ps1

# Individual checks
pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1                  # Format code
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1               # Security scan
pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1                    # Lint (PSScriptAnalyzer)
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1                       # Idempotency test
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1                  # Run tests
pwsh -NoProfile -File scripts/utils/code-quality/spellcheck.ps1                  # Spellcheck
pwsh -NoProfile -File scripts/utils/code-quality/run-markdownlint.ps1            # Markdownlint
pwsh -NoProfile -File scripts/utils/code-quality/validate-function-naming.ps1    # Validate function naming

# Run specific tests by name (supports wildcards and "or" syntax)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestName "*Edit-Profile*"
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration -TestName "*Backup-Profile* or *Convert-*"
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
- See [PROFILE_README.md](PROFILE_README.md) — Detailed technical information
- [docs/guides/DEVELOPMENT.md](docs/guides/DEVELOPMENT.md) — Developer guide and advanced testing

## Questions

Open an issue or draft PR if you need guidance. Tag maintainers for review.
