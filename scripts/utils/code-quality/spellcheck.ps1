<#
.SYNOPSIS
    Runs spellcheck on files using cspell.


.DESCRIPTION
    Local spellcheck helper used by validate-profile and pre-commit. Resolves cspell from
    (in order): PATH, repo node_modules/.bin, `pnpm exec cspell`, then `npx cspell`.
    When no runner is available, exits 0 by default (non-blocking) unless -RequireAvailable
    or PS_PROFILE_REQUIRE_CSPELL=1 is set (hooks should require it when deps are installed).


.PARAMETER Paths
    Array of file paths or glob patterns to check. Defaults to '**/*' (all files).

.PARAMETER RequireAvailable
    Fail with EXIT_SETUP_ERROR when cspell cannot be resolved.

.PARAMETER RepositoryRoot
    Optional repository root override for isolated spellcheck validation.


.NOTES
    Exit Codes:
    - 0 (EXIT_SUCCESS): Spellcheck passed or cspell not available (non-strict)
    - 1 (EXIT_VALIDATION_FAILURE): Spelling errors found
    - 2 (EXIT_SETUP_ERROR): Error running cspell / required but missing

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\spellcheck.ps1

    Runs spellcheck on all files in the repository.


.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\spellcheck.ps1 -Paths '**/*.md', '**/*.ps1'

    Runs spellcheck only on markdown and PowerShell files.
#>

param(
  [string[]]$Paths = @('**/*'),

  [switch]$RequireAvailable,

  [ValidateScript({
      if ($_ -and -not [string]::IsNullOrWhiteSpace($_) -and -not (Test-Path -LiteralPath $_ -PathType Container)) {
        throw "Repository root does not exist: $_"
      }
      $true
    })]
  [string]$RepositoryRoot
)

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if ($pathResolutionPath -and -not [string]::IsNullOrWhiteSpace($pathResolutionPath) -and -not (Test-Path -LiteralPath $pathResolutionPath)) {
  throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and -not (Test-Path -LiteralPath $moduleImportPath)) {
  throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Command' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

try {
  $repoRoot = if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    Get-RepoRoot -ScriptPath $PSScriptRoot
  }
  else {
    [System.IO.Path]::GetFullPath($RepositoryRoot)
  }
}
catch {
  Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

if ($env:PS_PROFILE_REQUIRE_CSPELL -eq '1') {
  $RequireAvailable = $true
}

function Get-NodeExecutablePath {
  $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
  if ($nodeCmd) {
    return $nodeCmd.Source
  }

  return $null
}

function Get-CSpellInvocation {
  param([string]$Root)

  if (Test-CommandAvailable -CommandName 'cspell') {
    return @{ Mode = 'command'; Executable = 'cspell'; PrefixArgs = @() }
  }

  # Prefer `node …/cspell/bin.mjs` so hooks still work when PATH is minimal
  # (shell shims under node_modules/.bin need `node` on PATH).
  $cspellEntry = Join-Path $Root 'node_modules' 'cspell' 'bin.mjs'
  $nodeExe = Get-NodeExecutablePath
  if ((Test-Path -LiteralPath $cspellEntry) -and $nodeExe) {
    return @{ Mode = 'command'; Executable = $nodeExe; PrefixArgs = @($cspellEntry) }
  }

  $localCandidates = @(
    (Join-Path $Root 'node_modules' '.bin' 'cspell')
    (Join-Path $Root 'node_modules' '.bin' 'cspell.cmd')
    (Join-Path $Root 'node_modules' '.bin' 'cspell.ps1')
  )
  foreach ($candidate in $localCandidates) {
    if (Test-Path -LiteralPath $candidate) {
      return @{ Mode = 'command'; Executable = $candidate; PrefixArgs = @() }
    }
  }

  # Only use package managers when this repo already has Node deps installed.
  # Bare `pnpm exec` / `npx` in an empty clone tries to install and fails loudly.
  $hasPackageJson = Test-Path -LiteralPath (Join-Path $Root 'package.json')
  $hasNodeModules = Test-Path -LiteralPath (Join-Path $Root 'node_modules')
  if ($hasPackageJson -and $hasNodeModules) {
    if (Test-CommandAvailable -CommandName 'pnpm') {
      return @{ Mode = 'command'; Executable = 'pnpm'; PrefixArgs = @('exec', 'cspell') }
    }

    if (Test-CommandAvailable -CommandName 'npx') {
      return @{ Mode = 'command'; Executable = 'npx'; PrefixArgs = @('--no-install', 'cspell') }
    }
  }

  return $null
}

$invocation = Get-CSpellInvocation -Root $repoRoot

if (-not $invocation) {
  $message = 'cspell not found on PATH, in node_modules/.bin, or via pnpm/npx. Install with: pnpm install (or npm install -g cspell).'
  if ($RequireAvailable) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $message
  }

  Write-ScriptMessage -Message $message -IsWarning
  Write-ScriptMessage -Message 'Skipping local spellcheck (CI workflow will run cspell on push/PR).'
  if ($RepositoryRoot -and $env:PS_PROFILE_TEST_MODE -eq '1') {
    return
  }

  Exit-WithCode -ExitCode $EXIT_SUCCESS
}

# Absolute paths (and ignored trees like tests/) need file:// so cspell still checks them.
$normalizedPaths = @(foreach ($pathItem in $Paths) {
    if ([string]::IsNullOrWhiteSpace($pathItem)) { continue }
    if ($pathItem.StartsWith('file://', [System.StringComparison]::OrdinalIgnoreCase)) {
      $pathItem
      continue
    }
    if ([System.IO.Path]::IsPathRooted($pathItem) -and (Test-Path -LiteralPath $pathItem)) {
      $fullPath = (Resolve-Path -LiteralPath $pathItem).Path
      if ($IsWindows) {
        'file:///' + ($fullPath -replace '\\', '/')
      }
      else {
        'file://' + $fullPath
      }
      continue
    }
    $pathItem
  })

Write-ScriptMessage -Message "Running cspell on: $($normalizedPaths -join ', ')"
$cspellExit = 0
try {
  Push-Location $repoRoot
  try {
    # cspell v8+ uses the `lint` subcommand (matches CI `pnpm exec cspell …`).
    $cspellArgs = @($invocation.PrefixArgs) + @('lint') + @($normalizedPaths) + @(
      '--no-progress'
      '--no-summary'
      '--no-must-find-files'
    )
    & $invocation.Executable @cspellArgs
    if ($null -ne $LASTEXITCODE) {
      $cspellExit = [int]$LASTEXITCODE
    }
  }
  finally {
    Pop-Location
  }
}
catch {
  Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

if ($cspellExit -ne 0) {
  Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'cspell found spelling errors'
}

$successMessage = 'cspell passed'
if ($RepositoryRoot -and $env:PS_PROFILE_TEST_MODE -eq '1') {
  Write-ScriptMessage -Message $successMessage
}
else {
  Exit-WithCode -ExitCode $EXIT_SUCCESS -Message $successMessage
}
