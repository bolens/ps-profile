<#
tests/unit/utility-sync-profile-fragments.tests.ps1

.SYNOPSIS
    Behavioral unit tests for sync-profile-fragments.ps1 DryRun execution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SyncFragmentsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'fragment' 'sync-profile-fragments.ps1'
    $ConfirmPreference = 'None'
}

Describe 'sync-profile-fragments.ps1 execution' {
    It 'DryRun previews fragment config sync without modifying .profile-fragments.json' {
        $configPath = Join-Path $script:TestRepoRoot '.profile-fragments.json'
        $before = if (Test-Path -LiteralPath $configPath) {
            Get-Content -LiteralPath $configPath -Raw
        }
        else {
            $null
        }

        $result = Invoke-TestScriptFile -ScriptPath $script:SyncFragmentsScript -ArgumentList @(
            '-DryRun',
            '-ProfileDir', $script:TestRepoRoot
        )

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN|DryRun|Would|fragment'

        if ($null -ne $before) {
            (Get-Content -LiteralPath $configPath -Raw) | Should -Be $before
        }
    }
}
