<#
scripts/checks/validate-profile.ps1

.SYNOPSIS
    Runs comprehensive validation checks on the PowerShell profile.

.DESCRIPTION
    Runs security scan, lint, spellcheck (cspell via PATH/node_modules/pnpm/npx),
    optional markdownlint when Node tooling is present, comment-based help,
    idempotency, and duplicate-function checks. Fails if any step fails. Used by
    CI/CD pipelines and git hooks (pre-commit runs format first, then this script).

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
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Build paths to validation scripts
$utilsDir = Join-Path $repoRoot 'scripts' 'utils'
$scriptDir = $PSScriptRoot
$format = Join-Path $utilsDir 'code-quality' 'run-format.ps1'
$security = Join-Path $utilsDir 'security' 'run-security-scan.ps1'
$lint = Join-Path $utilsDir 'code-quality' 'run-lint.ps1'
$spellcheck = Join-Path $utilsDir 'code-quality' 'spellcheck.ps1'
$markdownlint = Join-Path $utilsDir 'code-quality' 'run-markdownlint.ps1'
$idemp = Join-Path $scriptDir 'check-idempotency.ps1'
$fragReadme = Join-Path $scriptDir 'check-comment-help.ps1'

# Determine which PowerShell executable to use
$psExe = Get-PowerShellExecutable

# Build path to duplicate function check
$duplicateCheck = Join-Path $utilsDir 'metrics' 'find-duplicate-functions.ps1'

# Run validation checks in sequence
# Note: format is run separately in pre-commit hook before validation.
# spellcheck resolves cspell from PATH, node_modules/.bin, pnpm exec, then npx.
# markdownlint runs when local Node tooling is present (hooks / developer machines).
$checks = @(
    @{ Name = 'security scan'; Path = $security }
    @{ Name = 'lint'; Path = $lint }
    @{ Name = 'spellcheck'; Path = $spellcheck }
)

$hasNodeTooling = (
    (Test-Path -LiteralPath (Join-Path $repoRoot 'node_modules' '.bin' 'markdownlint')) -or
    (Test-Path -LiteralPath (Join-Path $repoRoot 'node_modules' '.bin' 'markdownlint.cmd')) -or
    [bool](Get-Command pnpm -ErrorAction SilentlyContinue) -or
    [bool](Get-Command markdownlint -ErrorAction SilentlyContinue) -or
    $env:PS_PROFILE_REQUIRE_MARKDOWNLINT -eq '1'
)
if ($hasNodeTooling) {
    $checks += @{ Name = 'markdownlint'; Path = $markdownlint }
}

$checks += @(
    @{ Name = 'comment-based help check'; Path = $fragReadme }
    @{ Name = 'idempotency'; Path = $idemp }
    @{ Name = 'duplicate functions'; Path = $duplicateCheck }
)

foreach ($check in $checks) {
    Write-ScriptMessage -Message "Running $($check.Name): $($check.Path)"
    & $psExe -NoProfile -File $check.Path
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "$($check.Name) failed with exit code $LASTEXITCODE"
    }
}

$successMessage = if ($hasNodeTooling) {
    'Validation: security + lint + spellcheck + markdownlint + comment help + idempotency + duplicate functions passed'
}
else {
    'Validation: security + lint + spellcheck + comment help + idempotency + duplicate functions passed'
}
Exit-WithCode -ExitCode $EXIT_SUCCESS -Message $successMessage

