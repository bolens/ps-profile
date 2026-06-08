<#
tests/unit/utility-check-profile-log.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-profile-log.ps1 log inspection output.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:CheckProfileLogScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'check-profile-log.ps1'
    $ConfirmPreference = 'None'
}

Describe 'check-profile-log.ps1 execution' {
    It 'Reports profile loading log status without interactive prompts' {
        $result = Invoke-TestScriptFile -ScriptPath $script:CheckProfileLogScript

        $result.Output | Should -Match 'Profile Loading Log|Log file'
    }
}
