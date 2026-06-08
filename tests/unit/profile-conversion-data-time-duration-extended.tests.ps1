<#
tests/unit/profile-conversion-data-time-duration-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/time/duration.ps1'
}
Describe 'profile.d/conversion-modules/data/time/duration.ps1 extended scenarios' {
    It 'Documents Duration/TimeSpan conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Duration/TimeSpan conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreTimeDuration with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreTimeDuration'
        $c | Should -Match '_ConvertFrom-DurationToTimeSpan'
    }
    It 'Registers duration-to-timespan and timespan-to-duration entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'duration-to-timespan'
        $c | Should -Match 'timespan-to-duration'
    }
}
