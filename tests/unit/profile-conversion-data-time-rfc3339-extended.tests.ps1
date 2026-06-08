<#
tests/unit/profile-conversion-data-time-rfc3339-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/time/rfc3339.ps1'
}
Describe 'profile.d/conversion-modules/data/time/rfc3339.ps1 extended scenarios' {
    It 'Documents RFC 3339 date/time conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'RFC 3339 date/time conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreTimeRfc3339 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreTimeRfc3339'
        $c | Should -Match '_ConvertFrom-Rfc3339ToDateTime'
    }
    It 'Registers rfc3339-to-datetime and datetime-to-rfc3339 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'rfc3339-to-datetime'
        $c | Should -Match 'datetime-to-rfc3339'
    }
}
