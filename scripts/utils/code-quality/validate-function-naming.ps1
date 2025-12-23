<#
scripts/utils/code-quality/validate-function-naming.ps1

.SYNOPSIS
    Validates PowerShell function naming conventions across the codebase.

.DESCRIPTION
    Audits all functions in the codebase to ensure they follow PowerShell naming conventions:
    - Functions follow Verb-Noun pattern
    - Verbs are from approved PowerShell verbs (Get-Verb)
    - Profile functions use Set-AgentModeFunction for collision-safe registration
    - Documents exceptions to naming conventions

.PARAMETER Path
    Path to analyze. Defaults to repository root.

.PARAMETER OutputPath
    Optional path to save validation report JSON file.

.PARAMETER ExceptionsFile
    Optional path to exceptions documentation file. Defaults to docs/guides/FUNCTION_NAMING_EXCEPTIONS.md

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\validate-function-naming.ps1

    Validates all functions in the codebase.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\validate-function-naming.ps1 -Path profile.d

    Validates functions in profile.d directory only.

.OUTPUTS
    PSCustomObject with validation results including:
    - Total functions found
    - Functions with approved verbs
    - Functions with unapproved verbs
    - Functions not using Set-AgentModeFunction in profile.d
    - Exceptions documented
#>

[CmdletBinding()]
param(
    [string]$Path = $null,

    [string]$OutputPath = $null,

    [string]$ExceptionsFile = $null
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and (Test-Path -LiteralPath $moduleImportPath)) {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Required:$false
}

# Import validation modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $modulesPath 'FunctionNamingValidator.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'FunctionDiscovery.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'ExceptionHandler.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'ValidationReporter.psm1') -ErrorAction Stop

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    # Fallback if Get-RepoRoot not available
    $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

# Set default paths
if (-not $Path) {
    $Path = $repoRoot
}

if (-not $ExceptionsFile) {
    $ExceptionsFile = Join-Path $repoRoot 'docs' 'guides' 'FUNCTION_NAMING_EXCEPTIONS.md'
}

# Discover functions
$functions = Get-FunctionsFromPath -Path $Path -RepoRoot $repoRoot

# Load exceptions
$exceptionData = Get-NamingExceptions -ExceptionsFile $ExceptionsFile
$exceptions = $exceptionData.Exceptions
$exceptionVerbs = $exceptionData.ExceptionVerbs

# Analyze results
$results = Get-ValidationResults -Functions $functions -Exceptions $exceptions -ExceptionVerbs $exceptionVerbs

# Display results
Write-ValidationReport -Results $results

# Save report if requested
if ($OutputPath) {
    Save-ValidationReport -Results $results -OutputPath $OutputPath
}

# Return exit code based on issues
if ($results.Issues.Count -gt 0) {
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Function naming validation failed with $($results.Issues.Count) issue(s)."
    }
    else {
        Write-Error "Function naming validation failed with $($results.Issues.Count) issue(s)." -ErrorAction Stop
    }
}
else {
    if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
        Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Function naming validation passed with no issues."
    }
    else {
        return
    }
}
