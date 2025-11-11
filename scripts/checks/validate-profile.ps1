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

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

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
$idemp = Join-Path $scriptDir 'check-idempotency.ps1'
$fragReadme = Join-Path $scriptDir 'check-comment-help.ps1'

# Determine which PowerShell executable to use
$psExe = Get-PowerShellExecutable

# Run validation checks in sequence
$checks = @(
    @{ Name = 'format'; Path = $format }
    @{ Name = 'security scan'; Path = $security }
    @{ Name = 'lint'; Path = $lint }
    @{ Name = 'spellcheck'; Path = $spellcheck }
    @{ Name = 'comment-based help check'; Path = $fragReadme }
    @{ Name = 'idempotency'; Path = $idemp }
)

foreach ($check in $checks) {
    Write-ScriptMessage -Message "Running $($check.Name): $($check.Path)"
    & $psExe -NoProfile -File $check.Path
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "$($check.Name) failed with exit code $LASTEXITCODE"
    }
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Validation: format + security + lint + spellcheck + comment help + idempotency passed"
