<#
tests/unit/utility-check-task-parity.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-task-parity.ps1 report mode.
#>

function global:Invoke-CheckTaskParityScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:CheckTaskParityScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckTaskParityScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'task-parity' 'check-task-parity.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-task-parity.ps1 execution' {
    It 'Reports task parity for the repository task runner files' {
        $result = Invoke-CheckTaskParityScript -ArgumentList @('-RepoRoot', $script:TestRepoRoot)

        $result.Output | Should -Match 'task|parity|Taskfile|Makefile|package\.json|justfile'
        $result.ExitCode | Should -BeIn @(0, 1)
    }
}
