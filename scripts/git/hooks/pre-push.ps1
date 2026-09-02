<#
scripts/git/hooks/pre-push.ps1

.SYNOPSIS
    Lightweight gate before push; heavy checks are opt-in.

.DESCRIPTION
    Invoked by the wrapper in .git/hooks/pre-push (via install-githooks.ps1).

    Default behavior is intentionally fast so `git push` does not hang:
    - Does NOT re-run validate-profile (pre-commit already covers format + validate).
    - Does NOT run changed-shard Pester (use CI / opt-in env).

    Opt-in heavier gates (expected to take minutes):
    - PS_PROFILE_PUSH_VALIDATE=1  Run validate-profile (cspell, lint, markdownlint, …)
    - PS_PROFILE_PUSH_TESTS=1     Run changed CI Pester shards (same filters as GHA)
    - PS_PROFILE_PUSH_TESTS_SINCE Diff base for shards (default: origin/main)

    Explicit skip (overrides opt-in):
    - PS_PROFILE_SKIP_PUSH_VALIDATE=1
    - PS_PROFILE_SKIP_PUSH_TESTS=1 or PS_PROFILE_PUSH_TESTS=0

.EXAMPLE
    git push

    Fast push (no validate / no local shard run).

.EXAMPLE
    PS_PROFILE_PUSH_TESTS=1 git push

    Also run changed-shard Pester before push.
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

# Heavy validate is opt-in. Pre-commit already ran it on commits; repeating here
# routinely stuck pushes for several minutes.
$wantValidate = ($env:PS_PROFILE_PUSH_VALIDATE -eq '1') -and ($env:PS_PROFILE_SKIP_PUSH_VALIDATE -ne '1')
if ($wantValidate) {
    $validate = Join-Path $repoRoot 'scripts' 'checks' 'validate-profile.ps1'
    if (-not (Test-Path -LiteralPath $validate)) {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "pre-push: validate-profile not found: $validate"
    }

    Write-ScriptMessage -Message 'pre-push: running validate-profile (PS_PROFILE_PUSH_VALIDATE=1)'

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
    Write-ScriptMessage -Message 'pre-push: skipping validate-profile (set PS_PROFILE_PUSH_VALIDATE=1 to enable; pre-commit already validated commits)'
}

# Changed CI shards are opt-in because even a focused run can take several minutes.
$wantTests =
($env:PS_PROFILE_PUSH_TESTS -eq '1') -and
($env:PS_PROFILE_SKIP_PUSH_TESTS -ne '1')

if ($wantTests) {
    $changedShards = Join-Path $repoRoot 'scripts' 'utils' 'code-quality' 'run-pester-changed-shards.ps1'
    if (Test-Path -LiteralPath $changedShards) {
        Write-ScriptMessage -Message 'pre-push: running Pester CI shards for local changes'
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
    Write-ScriptMessage -Message 'pre-push: skipping changed-shard tests (set PS_PROFILE_PUSH_TESTS=1 to enable)'
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message 'pre-push: all checks passed'
