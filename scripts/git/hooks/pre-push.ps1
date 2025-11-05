<#
scripts/git/hooks/pre-push.ps1

.SYNOPSIS
    Runs full validation checks before pushing to remote.

.DESCRIPTION
    Run full validation before push: runs validate-profile (format + security + lint +
    spellcheck + comment help + idempotency). This script is intended to be called
    by the wrapper in .git/hooks/pre-push. Exits with error code if any validation fails.

.EXAMPLE
    git push
    
    This hook is automatically invoked by git before pushing.
#>

Push-Location -LiteralPath (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
Pop-Location

$validate = Join-Path $repoRoot 'scripts\checks\validate-profile.ps1'

Write-Output "pre-push: running validate-profile (format + security + lint + spellcheck + comment help + idempotency)"
& pwsh -NoProfile -File $validate
if ($LASTEXITCODE -ne 0) { Write-Error "pre-push: validate-profile failed"; exit $LASTEXITCODE }

Write-Output "pre-push: all checks passed"
exit 0
