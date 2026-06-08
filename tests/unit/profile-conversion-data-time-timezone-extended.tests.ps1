<#
tests/unit/profile-conversion-data-time-timezone-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/time/timezone.ps1'
}
Describe 'profile.d/conversion-modules/data/time/timezone.ps1 extended scenarios' {
    It 'Documents Timezone conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Timezone conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreTimeTimezone with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreTimeTimezone'
        $c | Should -Match '_Convert-TimeZone'
    }
    It 'Registers tz-convert and list-timezones entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'tz-convert'
        $c | Should -Match 'list-timezones'
    }
}
