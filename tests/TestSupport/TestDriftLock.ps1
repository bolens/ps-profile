# ===============================================
# TestDriftLock.ps1
# Helpers for unit tests that temporarily modify drift.lock
# ===============================================

<#
.SYNOPSIS
    Runs a script block while preserving drift.lock contents.

.DESCRIPTION
    Saves the repository drift.lock file, executes the script block with the lock
    path as an argument, then restores the original contents in a finally block.

.PARAMETER ScriptBlock
    Script to run. Receives the drift.lock path as $args[0].

.EXAMPLE
    Invoke-WithTestDriftLockBackup {
        param($DriftLockPath)
        Add-Content -LiteralPath $DriftLockPath -Value 'tests/example.tests.ps1 -> profile.d/bootstrap.ps1 sig:abc'
        (Get-Content -LiteralPath $DriftLockPath -Raw).Contains('tests/example.tests.ps1') | Should -BeTrue
    }
#>
function Invoke-WithTestDriftLockBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $driftLockPath = Join-Path $repoRoot 'drift.lock'
    if (-not (Test-Path -LiteralPath $driftLockPath)) {
        throw "drift.lock not found at $driftLockPath"
    }

    $originalLock = Get-Content -LiteralPath $driftLockPath -Raw
    try {
        & $ScriptBlock $driftLockPath
    }
    finally {
        Set-Content -LiteralPath $driftLockPath -Value $originalLock -Encoding UTF8 -NoNewline
    }
}

<#
.SYNOPSIS
    Tests whether drift.lock content contains a binding fragment.

.DESCRIPTION
    Uses string Contains instead of Pester Should -Match with [regex]::Escape,
    which Pester can misparsed when passed inline to Should -Match.

.PARAMETER DriftLockContent
    Full drift.lock file contents.

.PARAMETER Text
    Substring expected to appear in the lock file.

.OUTPUTS
    System.Boolean
#>
function Test-DriftLockContains {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$DriftLockContent,

        [Parameter(Mandatory)]
        [string]$Text
    )

    return $DriftLockContent.Contains($Text)
}
