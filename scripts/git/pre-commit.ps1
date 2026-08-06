<#
scripts/git/pre-commit.ps1

cspell:ignore ACMR

.SYNOPSIS
    Cross-platform pre-commit hook that runs formatting and validation.

.DESCRIPTION
    Cross-platform helper invoked by .git/hooks/pre-commit. It runs code formatting
    first, re-stages only files that were already staged, then runs validate-profile
    (security, lint, cspell, markdownlint, comment help, idempotency, duplicates).
    Partially staged files are rejected before formatting so unstaged hunks cannot
    be absorbed into the commit. cspell is required when node tooling is available
    (same gate as CI).

.EXAMPLE
    pwsh -NoProfile -File scripts\git\pre-commit.ps1

    Runs formatting and validation checks as part of the git pre-commit hook.
#>

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent $PSScriptRoot
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
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Capture the index before formatting. Re-staging every modified file can silently
# add unrelated work, while re-staging a partially staged file absorbs its
# unstaged hunks. Refuse the latter and preserve the former.
$stagedFiles = @(& git -C $repoRoot diff --cached --name-only --diff-filter=ACMR)
if ($LASTEXITCODE -ne 0) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message 'Unable to inspect staged files.'
}

$unstagedFiles = @(& git -C $repoRoot diff --name-only --diff-filter=ACMR)
if ($LASTEXITCODE -ne 0) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message 'Unable to inspect unstaged files.'
}

$unstagedSet = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]$unstagedFiles,
    [System.StringComparer]::Ordinal
)
$partiallyStagedFiles = @($stagedFiles | Where-Object { $unstagedSet.Contains($_) })
if ($partiallyStagedFiles.Count -gt 0) {
    $fileList = $partiallyStagedFiles -join ', '
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Partially staged files cannot be auto-formatted safely: $fileList"
}

# Run formatting first
$formatScript = Join-Path $repoRoot 'scripts' 'utils' 'code-quality' 'run-format.ps1'
if ($formatScript -and -not [string]::IsNullOrWhiteSpace($formatScript) -and (Test-Path -LiteralPath $formatScript)) {
    Write-ScriptMessage -Message "Running code formatting..."
    $psExe = Get-PowerShellExecutable
    & $psExe -NoProfile -File $formatScript
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Code formatting failed"
    }

    # Re-stage only paths that were already in the index before formatting.
    if ($stagedFiles.Count -gt 0) {
        Write-ScriptMessage -Message "Re-staging formatted files already in the commit..."
        foreach ($stagedFile in $stagedFiles) {
            if (Test-Path -LiteralPath (Join-Path $repoRoot $stagedFile)) {
                & git -C $repoRoot add -- $stagedFile
                if ($LASTEXITCODE -ne 0) {
                    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Unable to re-stage formatted file: $stagedFile"
                }
            }
        }
    }
}
else {
    Write-ScriptMessage -Message "Format script not found: $formatScript" -IsWarning
}

# Run validation
$validateScript = Join-Path $repoRoot 'scripts' 'checks' 'validate-profile.ps1'
if ($validateScript -and -not [string]::IsNullOrWhiteSpace($validateScript) -and -not (Test-Path -LiteralPath $validateScript)) {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Validation script not found: $validateScript"
}

Write-ScriptMessage -Message "Running validation (security, lint, cspell, markdownlint, comment help, idempotency, duplicates)..."
# Match CI: require cspell / enable markdownlint when local Node tooling is present.
$localCspell = @(
    (Join-Path $repoRoot 'node_modules' '.bin' 'cspell')
    (Join-Path $repoRoot 'node_modules' '.bin' 'cspell.cmd')
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($localCspell -or (Get-Command pnpm -ErrorAction SilentlyContinue) -or (Get-Command cspell -ErrorAction SilentlyContinue)) {
    $env:PS_PROFILE_REQUIRE_CSPELL = '1'
}
$env:PS_PROFILE_REQUIRE_MARKDOWNLINT = '1'
$psExe = Get-PowerShellExecutable
& $psExe -NoProfile -File $validateScript -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation checks failed"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Pre-commit checks passed"
