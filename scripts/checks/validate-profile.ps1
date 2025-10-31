# Run format, security scan, lint then idempotency checks; fail if any step fails
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$utilsDir = Join-Path (Split-Path -Parent $scriptDir) 'utils'
$format = Join-Path $utilsDir 'run-format.ps1'
$security = Join-Path $utilsDir 'run-security-scan.ps1'
$lint = Join-Path $utilsDir 'run-lint.ps1'
$spellcheck = Join-Path $utilsDir 'spellcheck.ps1'
$idemp = Join-Path $scriptDir 'check-idempotency.ps1'
$fragReadme = Join-Path $scriptDir 'check-fragment-readmes.ps1'

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

Write-Output "Running fragment README check: $fragReadme"
& $psExe -NoProfile -File $fragReadme
if ($LASTEXITCODE -ne 0) { Write-Error "Fragment README check failed"; exit $LASTEXITCODE }

Write-Output "Running idempotency: $idemp"
& $psExe -NoProfile -File $idemp
if ($LASTEXITCODE -ne 0) { Write-Error "Idempotency check failed"; exit $LASTEXITCODE }

Write-Output "Validation: format + security + lint + spellcheck + fragment README + idempotency passed"
exit 0
