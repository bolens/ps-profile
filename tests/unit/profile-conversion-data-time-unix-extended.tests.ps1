<#
tests/unit/profile-conversion-data-time-unix-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/time/unix.ps1'
}
Describe 'profile.d/conversion-modules/data/time/unix.ps1 extended scenarios' {
    It 'Documents Unix Timestamp conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Unix Timestamp conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreTimeUnix with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreTimeUnix'
        $c | Should -Match '_ConvertFrom-UnixTimestampToDateTime'
    }
    It 'Registers unix-to-datetime and datetime-to-unix entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'unix-to-datetime'
        $c | Should -Match 'datetime-to-unix'
    }
}
