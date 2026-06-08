<#
tests/unit/utility-module-update-scheduler-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/dependencies/modules/ModuleUpdateScheduler.psm1'
}
Describe 'scripts/utils/dependencies/modules/ModuleUpdateScheduler.psm1 structure extended scenarios' {
    It 'Documents module update scheduling utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module update scheduling utilities'
        $c | Should -Match 'ModuleUpdateScheduler.psm1'
    }
    It 'Defines schedule registration and removal helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-UpdateSchedule'
        $c | Should -Match 'Remove-UpdateSchedule'
        $c | Should -Match 'ScheduledTaskName'
    }
    It 'Imports CommonEnums and ExitCodes for scheduling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'UpdateFrequency'
        $c | Should -Match 'CommonEnums.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
