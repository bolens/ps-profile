<#
scripts/git/hooks/pre-push.ps1

.SYNOPSIS
    Runs validation and CI-aligned checks before pushing to remote.

.DESCRIPTION
    Invoked by the wrapper installed into .git/hooks/pre-push (via install-githooks.ps1),
    which calls this file under scripts/git/hooks/. Runs validate-profile with the same
    cspell/markdownlint gating as pre-commit, then runs changed CI Pester shards
    (same filters as GitHub Actions) by default.

    Environment variables:
    - PS_PROFILE_SKIP_PUSH_VALIDATE=1  Skip validate-profile
    - PS_PROFILE_SKIP_PUSH_TESTS=1     Skip changed-shard Pester run
    - PS_PROFILE_PUSH_TESTS=0          Skip changed-shard tests (legacy opt-out)
    - PS_PROFILE_PUSH_TESTS=1          Force changed-shard tests (default is already on)
    - PS_PROFILE_PUSH_TESTS_SINCE      Diff base for shards (default: origin/main)

.EXAMPLE
    git push

    This hook is automatically invoked by git before pushing.

.EXAMPLE
    pwsh -NoProfile -File scripts/git/hooks/pre-push.ps1

    Run the pre-push checks manually.
#>

# This script lives at scripts/git/hooks/pre-push.ps1 → scripts/ is two levels up.
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if (-not (Test-Path -LiteralPath $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if (-not (Test-Path -LiteralPath $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$psExe = Get-PowerShellExecutable
$skipValidate = $env:PS_PROFILE_SKIP_PUSH_VALIDATE -eq '1'

if (-not $skipValidate) {
    $validate = Join-Path $repoRoot 'scripts' 'checks' 'validate-profile.ps1'
    if (-not (Test-Path -LiteralPath $validate)) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "pre-push: validate-profile not found: $validate"
    }

    Write-ScriptMessage -Message 'pre-push: running validate-profile (security, lint, cspell, markdownlint, comment help, idempotency, duplicates)'

    # Match pre-commit / CI: require cspell when local Node tooling is present.
    $localCspell = @(
        (Join-Path $repoRoot 'node_modules' '.bin' 'cspell')
        (Join-Path $repoRoot 'node_modules' '.bin' 'cspell.cmd')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($localCspell -or (Get-Command pnpm -ErrorAction SilentlyContinue) -or (Get-Command cspell -ErrorAction SilentlyContinue)) {
        $env:PS_PROFILE_REQUIRE_CSPELL = '1'
    }
    $env:PS_PROFILE_REQUIRE_MARKDOWNLINT = '1'

    & $psExe -NoProfile -File $validate
    if ($LASTEXITCODE -ne 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'pre-push: validate-profile failed'
    }
}
else {
    Write-ScriptMessage -Message 'pre-push: skipping validate-profile (PS_PROFILE_SKIP_PUSH_VALIDATE=1)'
}

# Changed CI shards — on by default (same filters as GitHub Actions Test - Pester).
# Opt out: PS_PROFILE_SKIP_PUSH_TESTS=1 or PS_PROFILE_PUSH_TESTS=0
$runPushTests = $true
if (($env:PS_PROFILE_SKIP_PUSH_TESTS -eq '1') -or ($env:PS_PROFILE_PUSH_TESTS -eq '0')) {
    $runPushTests = $false
}
if ($env:PS_PROFILE_PUSH_TESTS -eq '1') {
    $runPushTests = $true
}

if ($runPushTests) {
    $changedShards = Join-Path $repoRoot 'scripts' 'utils' 'code-quality' 'run-pester-changed-shards.ps1'
    if (Test-Path -LiteralPath $changedShards) {
        Write-ScriptMessage -Message 'pre-push: running Pester CI shards for local changes (same filters as GitHub Actions)'
        $since = if ($env:PS_PROFILE_PUSH_TESTS_SINCE) { $env:PS_PROFILE_PUSH_TESTS_SINCE } else { 'origin/main' }
        & $psExe -NoProfile -File $changedShards -ChangedSince $since -IncludeUntracked -Quiet
        if ($LASTEXITCODE -ne 0) {
            Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message 'pre-push: changed-shard Pester run failed'
        }
    }
    else {
        Write-ScriptMessage -Message "pre-push: changed-shard runner not found at $changedShards" -IsWarning
    }
}
else {
    Write-ScriptMessage -Message 'pre-push: skipping changed-shard tests (PS_PROFILE_SKIP_PUSH_TESTS=1 or PS_PROFILE_PUSH_TESTS=0)'
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'pre-push: all checks passed'
