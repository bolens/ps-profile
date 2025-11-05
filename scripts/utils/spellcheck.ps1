<#
Simple local spellcheck helper.

Behavior:
- If `cspell` (npm) is available on PATH, delegate to it for the provided paths.
- Otherwise print a short notice and exit 0 (non-blocking). This avoids breaking
  environments without Node installed while providing an opt-in CI check.

Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\spellcheck.ps1
#>

param(
  [string[]]$Paths = @('**/*.md', 'profile.d/**/*.md')
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
  & cspell @Paths --no-progress
  exit $LASTEXITCODE
}
else {
  Write-Warning "cspell not found on PATH. Install with: npm install -g cspell@6"
  Write-Output "Skipping local spellcheck (CI workflow will run cspell on push/PR)."
  exit 0
}
