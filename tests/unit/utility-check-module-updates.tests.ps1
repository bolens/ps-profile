<#
tests/unit/utility-check-module-updates.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-module-updates.ps1 parameter validation and smoke execution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckModuleUpdatesScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'dependencies' 'check-module-updates.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-module-updates.ps1 execution' {
    It 'Parses and runs with a module filter without requiring interactive input' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckModuleUpdatesScript -ArgumentList @(
            '-ModuleFilter', 'Pester',
            '-DryRun'
        )

        $result.ExitCode | Should -BeIn @(0, 2)
        $result.Output | Should -Match 'Pester|module|update|Module'
    }
}
