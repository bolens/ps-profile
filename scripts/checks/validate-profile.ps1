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

# Run format, security scan, lint then idempotency checks; fail if any step fails
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$utilsDir = Join-Path (Split-Path -Parent $scriptDir) 'utils'
$format = Join-Path $utilsDir 'run-format.ps1'
$security = Join-Path $utilsDir 'run-security-scan.ps1'
$lint = Join-Path $utilsDir 'run-lint.ps1'
$spellcheck = Join-Path $utilsDir 'spellcheck.ps1'
$idemp = Join-Path $scriptDir 'check-idempotency.ps1'
$fragReadme = Join-Path $scriptDir 'check-comment-help.ps1'

# Determine which PowerShell executable to use
$psExe = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }

Write-Output "Running format: $format"
& $psExe -NoProfile -File $format
if ($LASTEXITCODE -ne 0) { Write-Error "Format failed"; exit $LASTEXITCODE }

Write-Output "Running security scan: $security"
& $psExe -NoProfile -File $security
if ($LASTEXITCODE -ne 0) { Write-Error "Security scan failed"; exit $LASTEXITCODE }

Write-Output "Running lint: $lint"
& $psExe -NoProfile -File $lint
if ($LASTEXITCODE -ne 0) { Write-Error "Lint failed"; exit $LASTEXITCODE }

Write-Output "Running spellcheck: $spellcheck"
& $psExe -NoProfile -File $spellcheck
if ($LASTEXITCODE -ne 0) { Write-Error "Spellcheck failed"; exit $LASTEXITCODE }

Write-Output "Running comment-based help check: $fragReadme"
& $psExe -NoProfile -File $fragReadme
if ($LASTEXITCODE -ne 0) { Write-Error "Comment-based help check failed"; exit $LASTEXITCODE }

Write-Output "Running idempotency: $idemp"
& $psExe -NoProfile -File $idemp
if ($LASTEXITCODE -ne 0) { Write-Error "Idempotency check failed"; exit $LASTEXITCODE }

Write-Output "Validation: format + security + lint + spellcheck + comment help + idempotency passed"
exit 0
