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

# Import shared utilities
# Note: Git hooks may be called from .git/hooks/, so we need to resolve the path carefully
$hookScriptPath = $MyInvocation.MyCommand.Definition
$hookDir = Split-Path -Parent $hookScriptPath
# From .git/hooks/, go up two levels to get repo root
$repoRoot = Split-Path -Parent (Split-Path -Parent $hookDir)
$commonModulePath = Join-Path $repoRoot 'scripts' 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

$validate = Join-Path $repoRoot 'scripts' 'checks' 'validate-profile.ps1'

Write-ScriptMessage -Message "pre-push: running validate-profile (format + security + lint + spellcheck + comment help + idempotency)"
$psExe = Get-PowerShellExecutable
& $psExe -NoProfile -File $validate
if ($LASTEXITCODE -ne 0) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "pre-push: validate-profile failed"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "pre-push: all checks passed"

