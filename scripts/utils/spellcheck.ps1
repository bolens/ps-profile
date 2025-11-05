<#
scripts/utils/spellcheck.ps1

.SYNOPSIS
    Runs spellcheck on files using cspell.

.DESCRIPTION
    Simple local spellcheck helper. If `cspell` (npm) is available on PATH, delegates
    to it for the provided paths. Otherwise prints a short notice and exits 0 (non-blocking).
    This avoids breaking environments without Node installed while providing an opt-in CI check.

.PARAMETER Paths
    Array of file paths or glob patterns to check. Defaults to '**/*' (all files).

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\spellcheck.ps1

    Runs spellcheck on all files in the repository.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\spellcheck.ps1 -Paths '**/*.md', '**/*.ps1'

    Runs spellcheck only on markdown and PowerShell files.
#>

param(
  [string[]]$Paths = @('**/*')
)

# Use Test-HasCommand for efficient command check (if available from profile, otherwise fallback)
if ((Test-Path Function:Test-HasCommand) -or (Get-Command Test-HasCommand -ErrorAction SilentlyContinue)) {
  $hasCSpell = Test-HasCommand cspell
}
else {
  $hasCSpell = $null -ne (Get-Command cspell -ErrorAction SilentlyContinue)
}

if ($hasCSpell) {
  Write-Output "Running cspell on: $($Paths -join ', ')"
  & cspell @Paths --no-progress --no-summary
  exit $LASTEXITCODE
}
else {
  Write-Warning "cspell not found on PATH. Install with: npm install -g cspell@9"
  Write-Output "Skipping local spellcheck (CI workflow will run cspell on push/PR)."
  exit 0
}
