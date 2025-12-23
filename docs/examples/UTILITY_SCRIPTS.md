# Writing Utility Scripts

This guide demonstrates how to write utility scripts in `scripts/utils/` following the project's standardized patterns, including module imports, error handling, and path resolution.

## Overview

Utility scripts in `scripts/utils/` follow a standardized structure:

- **Module Import Pattern** - Import `ModuleImport.psm1` first, then use `Import-LibModule`
- **Path Resolution** - Use `Get-RepoRoot` for repository root resolution
- **Error Handling** - Use `Exit-WithCode` (never use direct `exit`)
- **Logging** - Use `Write-ScriptMessage` for consistent logging
- **Non-Interactive** - Scripts should run without user prompts

## Basic Structure

### Minimal Utility Script

```powershell
# ===============================================
# my-utility.ps1
# Brief description of what the script does
# ===============================================

<#
.SYNOPSIS
    Brief description.

.DESCRIPTION
    Detailed description of the script's functionality.

.PARAMETER Path
    Description of the parameter.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/my-utility.ps1 -Path "profile.d"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = "profile.d"
)

$ErrorActionPreference = 'Stop'

# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import required modules
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot

    # Main script logic here

    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

## Path Resolution

### Getting Repository Root

```powershell
# Standard pattern for getting repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Use $repoRoot for paths
$profileDDir = Join-Path $repoRoot 'profile.d'
$scriptsDir = Join-Path $repoRoot 'scripts'
```

### Path Resolution for Different Script Locations

```powershell
# Scripts in scripts/utils/*/
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'

# Scripts in scripts/checks/
$moduleImportPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'

# Scripts in scripts/git/
$moduleImportPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
```

## Module Imports

### Standard Module Import Pattern

```powershell
# 1. Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# 2. Import required modules using Import-LibModule
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking
```

### Available Library Modules

Common modules used in utility scripts:

- **`ExitCodes`** - Exit code constants (`$EXIT_SUCCESS`, `$EXIT_VALIDATION_FAILURE`, etc.)
- **`PathResolution`** - Path utilities (`Get-RepoRoot`, etc.)
- **`Logging`** - Logging utilities (`Write-ScriptMessage`, etc.)
- **`Module`** - Module management (`Ensure-ModuleAvailable`, etc.)
- **`FileSystem`** - File system operations
- **`Command`** - Command utilities
- **`Collections`** - Collection utilities
- **`JsonUtilities`** - JSON parsing and manipulation

## Error Handling

### Using Exit-WithCode

```powershell
# ❌ NEVER use direct exit
exit 1

# ✅ ALWAYS use Exit-WithCode
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"
```

### Standard Exit Codes

```powershell
# Success
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Operation completed"

# Validation failure (expected)
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Input validation failed"

# Setup/configuration error
Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to initialize"

# Runtime error
Exit-WithCode -ExitCode $EXIT_RUNTIME_ERROR -Message "Runtime error occurred"
```

### Error Handling Pattern

```powershell
try {
    # Main script logic
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot

    # Validate inputs
    if (-not (Test-Path $Path)) {
        Exit-WithCode `
            -ExitCode $EXIT_VALIDATION_FAILURE `
            -Message "Path not found: $Path"
    }

    # Process files
    # ...

    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

## Logging

### Using Write-ScriptMessage

```powershell
# Import Logging module first
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking

# Info messages
Write-ScriptMessage -Message "Starting script execution..." -LogLevel Info

# Warning messages
Write-ScriptMessage -Message "Warning: Some files were skipped" -IsWarning

# Error messages
Write-ScriptMessage -Message "Error: Failed to process file" -IsError
```

## Non-Interactive Execution

### Suppressing Prompts

```powershell
# Suppress all confirmation prompts for non-interactive execution
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'

# Set default parameter values to suppress prompts
if (-not $PSDefaultParameterValues) {
    $PSDefaultParameterValues = @{}
}
$PSDefaultParameterValues['Remove-Item:Confirm'] = $false
$PSDefaultParameterValues['Remove-Item:Force'] = $true
$PSDefaultParameterValues['Remove-Item:Recurse'] = $true
```

## Real-World Examples

### Example 1: Fragment Validation Script

```powershell
# ===============================================
# validate-fragments.ps1
# Validates profile fragments
# ===============================================

<#
.SYNOPSIS
    Validates profile fragments for syntax and structure.

.DESCRIPTION
    Scans profile.d directory and validates all fragment files for:
    - PowerShell syntax errors
    - Missing dependencies
    - Invalid fragment declarations

.PARAMETER Path
    Path to profile.d directory. Defaults to profile.d in repo root.

.EXAMPLE
    pwsh -NoProfile -File scripts/utils/validate-fragments.ps1
#>

[CmdletBinding()]
param(
    [string]$Path
)

$ErrorActionPreference = 'Stop'
$ConfirmPreference = 'None'

# Import modules
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot

    # Resolve path
    if (-not $Path) {
        $Path = Join-Path $repoRoot 'profile.d'
    }

    if (-not (Test-Path $Path)) {
        Exit-WithCode `
            -ExitCode $EXIT_VALIDATION_FAILURE `
            -Message "Path not found: $Path"
    }

    Write-ScriptMessage -Message "Validating fragments in: $Path" -LogLevel Info

    $fragments = Get-ChildItem -Path $Path -Filter '*.ps1' -File
    $errors = @()

    foreach ($fragment in $fragments) {
        # Validate fragment
        # ...
    }

    if ($errors.Count -gt 0) {
        foreach ($error in $errors) {
            Write-ScriptMessage -Message $error -IsError
        }
        Exit-WithCode `
            -ExitCode $EXIT_VALIDATION_FAILURE `
            -Message "Found $($errors.Count) validation error(s)"
    }

    Write-ScriptMessage -Message "All fragments validated successfully" -LogLevel Info
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Write-ScriptMessage -Message "Validation failed: $_" -IsError
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

### Example 2: Migration Script

```powershell
# ===============================================
# migrate-command-detection.ps1
# Migration script to replace Test-HasCommand with Test-CachedCommand
# ===============================================

<#
.SYNOPSIS
    Migrates Test-HasCommand calls to Test-CachedCommand.

.PARAMETER Path
    Specific file or directory to migrate. Defaults to profile.d.

.PARAMETER WhatIf
    Shows what would be changed without making changes (dry run).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# Import modules
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking

try {
    # Resolve default path if not provided
    if (-not $Path) {
        $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
        $Path = Join-Path $repoRoot 'profile.d'
    }

    # Validate path
    if (-not (Test-Path -Path $Path)) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Path not found: $Path"
    }

    # Find all PowerShell files
    $files = Get-ChildItem -Path $Path -Filter '*.ps1' -Recurse -File

    if ($files.Count -eq 0) {
        Write-ScriptMessage -Message "No PowerShell files found in: $Path" -IsWarning
        Exit-WithCode -ExitCode $EXIT_SUCCESS
    }

    Write-ScriptMessage -Message "Scanning $($files.Count) PowerShell file(s)..." -LogLevel Info

    $migratedCount = 0
    $totalReplacements = 0

    foreach ($file in $files) {
        # Migration logic
        # ...
    }

    if ($WhatIf) {
        Write-ScriptMessage -Message "DRY RUN: Would migrate $migratedCount file(s) with $totalReplacements replacement(s)" -LogLevel Info
    }
    else {
        Write-ScriptMessage -Message "Migrated $migratedCount file(s) with $totalReplacements replacement(s)" -LogLevel Info
    }

    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

## Best Practices

### 1. Always Import ModuleImport First

```powershell
# ✅ CORRECT: Import ModuleImport first
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# ❌ WRONG: Import modules directly
Import-Module scripts/lib/ExitCodes.psm1  # Wrong path resolution
```

### 2. Use Get-RepoRoot for Path Resolution

```powershell
# ✅ CORRECT: Use Get-RepoRoot
$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
$profileDDir = Join-Path $repoRoot 'profile.d'

# ❌ WRONG: Hardcode paths
$profileDDir = "C:\Users\...\profile.d"  # Not portable
```

### 3. Always Use Exit-WithCode

```powershell
# ✅ CORRECT: Use Exit-WithCode
Exit-WithCode -ExitCode $EXIT_SUCCESS

# ❌ WRONG: Direct exit
exit 0
```

### 4. Handle Errors Properly

```powershell
# ✅ CORRECT: Comprehensive error handling
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    # Main logic
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# ❌ WRONG: No error handling
$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot  # May throw
```

### 5. Make Scripts Non-Interactive

```powershell
# ✅ CORRECT: Suppress prompts
$ConfirmPreference = 'None'
$PSDefaultParameterValues['Remove-Item:Confirm'] = $false

# ❌ WRONG: Scripts that require user input
Remove-Item $path  # May prompt for confirmation
```

## Checklist

When creating a new utility script:

- [ ] Import `ModuleImport.psm1` first
- [ ] Import required modules using `Import-LibModule`
- [ ] Use `Get-RepoRoot` for path resolution
- [ ] Use `Exit-WithCode` for all exits (never use direct `exit`)
- [ ] Use `Write-ScriptMessage` for logging
- [ ] Suppress prompts for non-interactive execution
- [ ] Handle errors with try-catch
- [ ] Provide comprehensive comment-based help
- [ ] Include examples in help documentation
- [ ] Test script with various inputs and error conditions

## Notes

- Utility scripts should be runnable from any directory
- Scripts should never require user interaction (use `-WhatIf` for dry runs)
- Always use relative path resolution (never hardcode absolute paths)
- Import modules in dependency order (ModuleImport first, then others)
- Use appropriate exit codes for different failure scenarios
- Scripts in `scripts/utils/` are typically run with `pwsh -NoProfile -File`
