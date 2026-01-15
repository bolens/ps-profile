<#
scripts/checks/check-comment-help.ps1

.SYNOPSIS
    Checks that all functions in profile.d fragments have comment-based help.

.DESCRIPTION
    Checks that all functions in profile.d/*.ps1 fragments have comment-based help.
    This ensures the automated documentation generator can create complete docs.
    Scans all PowerShell files in the profile.d directory and reports any functions
    that are missing comment-based help blocks.

.PARAMETER Verbose
    If specified, outputs detailed information about each function checked.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-comment-help.ps1

    Checks all functions in profile.d for comment-based help.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-comment-help.ps1 -Verbose

    Checks all functions with verbose output.
#>

param(
    [switch]$Verbose
)

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent $PSScriptRoot
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if ($pathResolutionPath -and -not [string]::IsNullOrWhiteSpace($pathResolutionPath) -and -not (Test-Path -LiteralPath $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and -not (Test-Path -LiteralPath $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'AstParsing' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'CommentHelp' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileContent' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $fragDir = Join-Path $repoRoot 'profile.d'
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

$psFiles = Get-ChildItem -Path $fragDir -Filter '*.ps1' -File | Sort-Object Name

$issueCount = 0

<#
.SYNOPSIS
    Gets a list of functions in a PowerShell file that are missing comment-based help.

.DESCRIPTION
    Analyzes a PowerShell file using the AST parser to find all function definitions
    and checks if they have comment-based help blocks (containing .SYNOPSIS or .DESCRIPTION).
    Checks both before the function definition and at the beginning of the function body.

.PARAMETER Path
    Path to the PowerShell file to analyze.

.OUTPUTS
    System.String[]. Array of function names that are missing comment-based help.

.EXAMPLE
    $undocumented = Get-FunctionsWithoutCommentHelp -Path "profile.d/env.ps1"
    if ($undocumented.Count -gt 0) {
        Write-Warning "Functions without help: $($undocumented -join ', ')"
    }
#>
function Get-FunctionsWithoutCommentHelp {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    # Use FileContent module for consistent file reading
    $content = Read-FileContent -Path $Path
    if (-not $content) { return @() }

    $undocumented = @()

    # Use AST parsing module to find all function definitions
    try {
        $ast = Get-PowerShellAst -Path $Path
        $functionAsts = Get-FunctionsFromAst -Ast $ast

        foreach ($funcAst in $functionAsts) {
            # Check if function has comment-based help using CommentHelp module
            $hasHelp = Test-FunctionHasHelp -FuncAst $funcAst -Content $content -CheckBody

            if (-not $hasHelp) {
                $undocumented += $funcAst.Name
            }
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to parse $($Path): $($_.Exception.Message)" -IsWarning
    }

    return $undocumented
}

Write-ScriptMessage -Message "Checking that all functions have comment-based help in $fragDir"

foreach ($ps in $psFiles) {
    $undocumentedFuncs = Get-FunctionsWithoutCommentHelp -Path $ps.FullName

    if ($undocumentedFuncs.Count -gt 0) {
        $issueCount++
        Write-ScriptMessage -Message "MISSING HELP: $($ps.Name)"
        Write-ScriptMessage -Message "  Functions without comment-based help: $([string]::Join(', ', $undocumentedFuncs))"
    }
    elseif ($Verbose) {
        Write-ScriptMessage -Message "OK: $($ps.Name)"
    }
}

if ($issueCount -gt 0) {
    Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Found $issueCount fragments with functions missing comment-based help."
}
else {
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "All functions have comment-based help."
}

