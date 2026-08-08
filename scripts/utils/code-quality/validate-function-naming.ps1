<#
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

.PARAMETER IncludeTests
    Includes functions located under test directories. Test functions are excluded
    by default.

.PARAMETER RepositoryRoot
    Optional repository root used to resolve default paths. Defaults to the
    repository containing this script.


.OUTPUTS
    PSCustomObject with validation results including:
    - Total functions found
    - Functions with approved verbs
    - Functions with unapproved verbs
    - Functions not using Set-AgentModeFunction in profile.d
    - Exceptions documented

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\validate-function-naming.ps1

    Validates all functions in the codebase.


.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\validate-function-naming.ps1 -Path profile.d

    Validates functions in profile.d directory only.
#>

[CmdletBinding()]
param(
    [string]$Path = $null,

    [string]$OutputPath = $null,

    [string]$ExceptionsFile = $null,

    [switch]$IncludeTests,

    [string]$RepositoryRoot
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and (Test-Path -LiteralPath $moduleImportPath)) {
    Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global -Required:$false
}

# Import validation modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $modulesPath 'FunctionNamingValidator.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'FunctionDiscovery.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'ExceptionHandler.psm1') -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'ValidationReporter.psm1') -ErrorAction Stop

# Get repository root
$repoRoot = if ($RepositoryRoot) {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
}
else {
    try {
        Get-RepoRoot -ScriptPath $PSScriptRoot
    }
    catch {
        # Fallback if Get-RepoRoot not available
        Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    }
}

# Set default paths
if (-not $Path) {
    $Path = $repoRoot
}

if (-not $ExceptionsFile) {
    $ExceptionsFile = Join-Path $repoRoot 'docs' 'guides' 'FUNCTION_NAMING_EXCEPTIONS.md'
}

# Discover functions
$functions = @(Get-FunctionsFromPath -Path $Path -RepoRoot $repoRoot)

# Load exceptions
$exceptionData = Get-NamingExceptions -ExceptionsFile $ExceptionsFile
$exceptions = $exceptionData.Exceptions
$exceptionVerbs = $exceptionData.ExceptionVerbs

# Analyze results
$results = Get-ValidationResults `
    -Functions $functions `
    -Exceptions $exceptions `
    -ExceptionVerbs $exceptionVerbs `
    -IncludeTests:$IncludeTests

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
        $successMessage = 'Function naming validation passed with no issues.'
        if ($Path -and $env:PS_PROFILE_TEST_MODE -eq '1') {
            Write-Output $successMessage
            return
        }
        Exit-WithCode -ExitCode $EXIT_SUCCESS -Message $successMessage
    }
    else {
        return
    }
}
