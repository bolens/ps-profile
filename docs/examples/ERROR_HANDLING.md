# Error Handling Patterns

This guide demonstrates standardized error handling patterns used throughout the PowerShell profile, including fragment loading errors, utility script errors, and missing tool warnings.

## Overview

The profile uses several standardized error handling functions:

- **`Write-ProfileError`** - Fragment loading errors with context
- **`Exit-WithCode`** - Utility script exit codes (never use direct `exit`)
- **`Write-MissingToolWarning`** - Missing tool warnings (de-duplicated per session)

## Fragment Error Handling

### Using Write-ProfileError

```powershell
# Standard error handling pattern for fragments
try {
    # Risky operation (e.g., loading modules, registering functions)
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('modules', 'example.ps1') `
        -Context "Fragment: example"
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: example" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load example fragment: $($_.Exception.Message)"
        }
    }
}
```

### Error Handling with Context

```powershell
# Provide meaningful context for debugging
try {
    $modulePath = Join-Path $PSScriptRoot 'modules' 'example.ps1'
    if (Test-Path $modulePath) {
        . $modulePath
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError `
                -ErrorRecord $_ `
                -Context "Fragment: example (loading example.ps1)" `
                -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load example module: $($_.Exception.Message)"
        }
    }
}
```

### Conditional Error Reporting

```powershell
# Only report errors in debug mode (non-blocking)
try {
    # Optional feature that may fail
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('optional-modules', 'feature.ps1') `
        -Context "Fragment: optional-feature"
}
catch {
    # Only log if debug mode is enabled
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: optional-feature" -Category 'Fragment'
        }
    }
    # Don't throw - allow profile to continue loading
}
```

## Utility Script Error Handling

### Using Exit-WithCode

```powershell
# ❌ NEVER use direct exit calls
exit 1  # WRONG

# ✅ ALWAYS use Exit-WithCode
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"
```

### Standard Exit Codes

```powershell
# Import ExitCodes module first
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking

# Success
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Operation completed successfully"

# Validation failure (expected)
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Input validation failed"

# Setup/configuration error
Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to initialize script environment"

# Runtime error
Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message "Runtime error occurred"
```

### Error Handling in Utility Scripts

```powershell
# Standard pattern for utility scripts
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'

    # Main script logic
    # ...

    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

### Error Handling with Custom Messages

```powershell
# Provide detailed error messages
try {
    $filePath = Join-Path $repoRoot 'config.json'
    if (-not (Test-Path $filePath)) {
        Exit-WithCode `
            -ExitCode $EXIT_VALIDATION_FAILURE `
            -Message "Configuration file not found: $filePath"
    }
}
catch {
    Exit-WithCode `
        -ExitCode $EXIT_RUNTIME_ERROR `
        -ErrorRecord $_ `
        -Message "Failed to process configuration file"
}
```

## Missing Tool Warnings

### Using Write-MissingToolWarning

```powershell
# Standard pattern for missing tool warnings
if (Test-CachedCommand 'docker') {
    docker ps
}
else {
    Write-MissingToolWarning -Tool 'docker' -InstallHint 'Install with: scoop install docker'
}
```

### Custom Warning Messages

```powershell
# Use custom message for clarity
if (Test-CachedCommand 'http') {
    http GET https://api.example.com
}
else {
    Write-MissingToolWarning `
        -Tool 'http' `
        -Message 'httpie (http) command not found' `
        -InstallHint 'Install with: scoop install httpie'
}
```

### Warning Suppression

```powershell
# Warnings are automatically suppressed if:
# 1. $env:PS_PROFILE_SUPPRESS_TOOL_WARNINGS is set to true
# 2. Warning has already been shown in this session (de-duplication)

# Force warning even if already shown
Write-MissingToolWarning -Tool 'docker' -InstallHint '...' -Force
```

## Real-World Examples

### Example 1: Fragment with Module Loading

```powershell
# ===============================================
# containers.ps1
# Container engine helpers
# ===============================================

# Load container modules with error handling
if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
    try {
        $modules = @(
            @{
                ModulePath = @('container-modules', 'container-helpers.ps1')
                Context = 'Fragment: containers (container-helpers.ps1)'
            }
        )

        $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules

        if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
            Write-Verbose "Loaded $($result.SuccessCount) container modules (failed: $($result.FailureCount))"
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: containers" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load containers fragment: $($_.Exception.Message)"
            }
        }
    }
}
```

### Example 2: Utility Script with Validation

```powershell
# ===============================================
# validate-fragments.ps1
# Validates profile fragments
# ===============================================

# Import required modules
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $profileDDir = Join-Path $repoRoot 'profile.d'

    if (-not (Test-Path $profileDDir)) {
        Exit-WithCode `
            -ExitCode $EXIT_VALIDATION_FAILURE `
            -Message "Profile directory not found: $profileDDir"
    }

    # Validation logic
    $fragments = Get-ChildItem -Path $profileDDir -Filter '*.ps1' -File
    $errors = @()

    foreach ($fragment in $fragments) {
        # Validate fragment
        # ...
    }

    if ($errors.Count -gt 0) {
        Exit-WithCode `
            -ExitCode $EXIT_VALIDATION_FAILURE `
            -Message "Found $($errors.Count) validation error(s)"
    }

    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "All fragments validated successfully"
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

### Example 3: Tool Wrapper with Error Handling

```powershell
# Tool wrapper with comprehensive error handling
function Invoke-GitLeaks {
    <#
    .SYNOPSIS
        Scans a repository for secrets using gitleaks.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository
    )

    # Validate input
    if (-not (Test-Path $Repository)) {
        Write-Error "Repository path does not exist: $Repository"
        return
    }

    # Check for tool availability
    if (Test-CachedCommand 'gitleaks') {
        try {
            gitleaks detect --source $Repository
        }
        catch {
            Write-Error "Failed to run gitleaks: $_"
        }
    }
    else {
        Write-MissingToolWarning `
            -Tool 'gitleaks' `
            -InstallHint 'Install with: scoop install gitleaks'
    }
}

# Register the function
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Invoke-GitLeaks' -Body ${function:Invoke-GitLeaks}
}
```

## Best Practices

### 1. Never Use Direct Exit Calls

```powershell
# ❌ WRONG: Direct exit
exit 1

# ✅ CORRECT: Use Exit-WithCode
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"
```

### 2. Provide Meaningful Context

```powershell
# ✅ GOOD: Detailed context
Write-ProfileError `
    -ErrorRecord $_ `
    -Context "Fragment: containers (loading container-helpers.ps1)" `
    -Category 'Fragment'

# ❌ AVOID: Generic context
Write-ProfileError -ErrorRecord $_ -Context "Error" -Category 'Fragment'
```

### 3. Use Appropriate Exit Codes

```powershell
# ✅ GOOD: Correct exit code for the situation
if (-not (Test-Path $configFile)) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Config file missing"
}

# ❌ AVOID: Wrong exit code
if (-not (Test-Path $configFile)) {
    Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message "Config file missing"  # Should be VALIDATION_FAILURE
}
```

### 4. Handle Errors Gracefully in Fragments

```powershell
# ✅ GOOD: Non-blocking error handling
try {
    # Optional feature
    Import-FragmentModule ...
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: optional" -Category 'Fragment'
    }
    # Don't throw - allow profile to continue
}

# ❌ AVOID: Blocking errors for optional features
try {
    Import-FragmentModule ...
}
catch {
    throw  # This will stop profile loading!
}
```

### 5. De-duplicate Warnings

```powershell
# ✅ GOOD: Write-MissingToolWarning automatically de-duplicates
Write-MissingToolWarning -Tool 'docker' -InstallHint '...'
Write-MissingToolWarning -Tool 'docker' -InstallHint '...'  # Only shows once

# ❌ AVOID: Manual warning (not de-duplicated)
Write-Warning "docker not found"  # Shows every time
```

## Error Handling Checklist

When writing fragments or utility scripts:

- [ ] Use `Write-ProfileError` for fragment loading errors (not `Write-Error`)
- [ ] Use `Exit-WithCode` for utility script exits (never use direct `exit`)
- [ ] Use `Write-MissingToolWarning` for missing tool warnings (not `Write-Warning`)
- [ ] Provide meaningful context in error messages
- [ ] Use appropriate exit codes for the situation
- [ ] Handle errors gracefully (don't block profile loading for optional features)
- [ ] Check for function availability before using (backward compatibility)
- [ ] Only report errors in debug mode for non-critical failures

## Notes

- `Write-ProfileError` is only available after bootstrap loads - always check availability
- `Exit-WithCode` requires importing the `ExitCodes` module first
- `Write-MissingToolWarning` automatically de-duplicates warnings per session
- Fragment errors should not block profile loading (use try-catch, don't throw)
- Utility script errors should exit with appropriate codes (use Exit-WithCode)
- All error handling functions are idempotent and safe to call multiple times
