<#
scripts/checks/validate-profile.ps1

.SYNOPSIS
    Runs comprehensive validation checks on the PowerShell profile.

.DESCRIPTION
    Runs format, security scan, lint, spellcheck, comment-based help check, and
    idempotency checks. Fails if any step fails. This is the main validation script
    used in CI/CD pipelines and git hooks.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\validate-profile.ps1

    Runs all validation checks on the PowerShell profile.
#>

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
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Build paths to validation scripts
$utilsDir = Join-Path $repoRoot 'scripts' 'utils'
$scriptDir = $PSScriptRoot
$format = Join-Path $utilsDir 'code-quality' 'run-format.ps1'
$security = Join-Path $utilsDir 'security' 'run-security-scan.ps1'
$lint = Join-Path $utilsDir 'code-quality' 'run-lint.ps1'
$spellcheck = Join-Path $utilsDir 'code-quality' 'spellcheck.ps1'
$idemp = Join-Path $scriptDir 'check-idempotency.ps1'
$fragReadme = Join-Path $scriptDir 'check-comment-help.ps1'

# Determine which PowerShell executable to use
$psExe = Get-PowerShellExecutable

# Build path to duplicate function check
$duplicateCheck = Join-Path $utilsDir 'metrics' 'find-duplicate-functions.ps1'

# Run validation checks in sequence
# Note: format is run separately in pre-commit hook before validation
$checks = @(
    @{ Name = 'security scan'; Path = $security }
    @{ Name = 'lint'; Path = $lint }
    @{ Name = 'spellcheck'; Path = $spellcheck }
    @{ Name = 'comment-based help check'; Path = $fragReadme }
    @{ Name = 'idempotency'; Path = $idemp }
    @{ Name = 'duplicate functions'; Path = $duplicateCheck }
)

foreach ($check in $checks) {
    Write-ScriptMessage -Message "Running $($check.Name): $($check.Path)"
    & $psExe -NoProfile -File $check.Path
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "$($check.Name) failed with exit code $LASTEXITCODE"
    }
}

Exit-WithCode -ExitCode [ExitCode]::Success -Message "Validation: security + lint + spellcheck + comment help + idempotency + duplicate functions passed"

