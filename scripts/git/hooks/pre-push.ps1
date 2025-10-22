<#
scripts/hooks/pre-push.ps1

Run full validation before push: lint + idempotency + fragment README checks.
This script is intended to be called by the wrapper in .git/hooks/pre-push.
#>

Push-Location -LiteralPath (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
Pop-Location

$validate = Join-Path $repoRoot 'scripts\validate-profile.ps1'
$checkReadmes = Join-Path $repoRoot 'scripts\check-fragment-readmes.ps1'

Write-Output "pre-push: running validate-profile (lint + idempotency)"
& pwsh -NoProfile -File $validate
if ($LASTEXITCODE -ne 0) { Write-Error "pre-push: validate-profile failed"; exit $LASTEXITCODE }

Write-Output "pre-push: running check-fragment-readmes"
& pwsh -NoProfile -File $checkReadmes
if ($LASTEXITCODE -ne 0) { Write-Error "pre-push: check-fragment-readmes failed"; exit $LASTEXITCODE }

Write-Output "pre-push: all checks passed"
exit 0
