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

.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): Spellcheck passed or cspell not available
    - 1 (EXIT_VALIDATION_FAILURE): Spelling errors found
    - 2 (EXIT_SETUP_ERROR): Error running cspell

    This script is non-blocking - if cspell is not installed, it exits successfully
    to avoid breaking workflows in environments without Node.js.
#>

param(
  [string[]]$Paths = @('**/*')
)

# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Command' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Check if cspell is available
$hasCSpell = Test-CommandAvailable -CommandName 'cspell'

if ($hasCSpell) {
  Write-ScriptMessage -Message "Running cspell on: $($Paths -join ', ')"
  try {
    & cspell @Paths --no-progress --no-summary
    if ($LASTEXITCODE -ne 0) {
      Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "cspell found spelling errors"
    }
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "cspell passed"
  }
  catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
  }
}
else {
  Write-ScriptMessage -Message "cspell not found on PATH. Install with: npm install -g cspell@9" -IsWarning
  Write-ScriptMessage -Message "Skipping local spellcheck (CI workflow will run cspell on push/PR)."
  Exit-WithCode -ExitCode $EXIT_SUCCESS
}

