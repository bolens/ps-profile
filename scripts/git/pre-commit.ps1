<#
scripts/git/pre-commit.ps1

.SYNOPSIS
    Cross-platform pre-commit hook that runs formatting and validation.

.DESCRIPTION
    Cross-platform helper invoked by .git/hooks/pre-commit. It runs code formatting
    first, adds any formatted files to the commit, then runs validation checks.
    Ensures code quality before commits are finalized.

.EXAMPLE
    pwsh -NoProfile -File scripts\git\pre-commit.ps1

    Runs formatting and validation checks as part of the git pre-commit hook.
#>

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent $PSScriptRoot
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'PathResolution.psm1'
if (-not (Test-Path $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if (-not (Test-Path $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Run formatting first
$formatScript = Join-Path $repoRoot 'scripts' 'utils' 'code-quality' 'run-format.ps1'
if (Test-Path $formatScript) {
    Write-ScriptMessage -Message "Running code formatting..."
    $psExe = Get-PowerShellExecutable
    & $psExe -NoProfile -File $formatScript
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Code formatting failed"
    }

    # Add any files that were formatted
    $formattedFiles = & git diff --name-only
    if ($formattedFiles) {
        Write-ScriptMessage -Message "Adding formatted files to commit..."
        $formattedFiles | ForEach-Object { & git add $_ }
    }
}
else {
    Write-ScriptMessage -Message "Format script not found: $formatScript" -IsWarning
}

# Run validation
$validateScript = Join-Path $repoRoot 'scripts' 'checks' 'validate-profile.ps1'
if (-not (Test-Path $validateScript)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Validation script not found: $validateScript"
}

Write-ScriptMessage -Message "Running validation..."
$psExe = Get-PowerShellExecutable
& $psExe -NoProfile -File $validateScript -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation checks failed"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Pre-commit checks passed"
