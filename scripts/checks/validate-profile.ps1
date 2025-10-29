# Run format, security scan, lint then idempotency checks; fail if any step fails
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$format = Join-Path (Split-Path -Parent $scriptDir) 'utils' 'run-format.ps1'
$security = Join-Path (Split-Path -Parent $scriptDir) 'utils' 'run-security-scan.ps1'
$lint = Join-Path (Split-Path -Parent $scriptDir) 'utils' 'run-lint.ps1'
$spellcheck = Join-Path (Split-Path -Parent $scriptDir) 'utils' 'spellcheck.ps1'
$idemp = Join-Path $scriptDir 'check-idempotency.ps1'

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

Write-Output "Running idempotency: $idemp"
& $psExe -NoProfile -File $idemp
if ($LASTEXITCODE -ne 0) { Write-Error "Idempotency check failed"; exit $LASTEXITCODE }

Write-Output "Validation: format + security + lint + spellcheck + idempotency passed"
exit 0
