<#
tests/unit/profile-conversion-data-time-human-readable-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/time/human-readable.ps1'
}
Describe 'profile.d/conversion-modules/data/time/human-readable.ps1 extended scenarios' {
    It 'Documents Human-readable date/time conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Human-readable date/time conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreTimeHumanReadable with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreTimeHumanReadable'
        $c | Should -Match '_ConvertFrom-HumanReadableToDateTime'
    }
    It 'Registers human-to-datetime and datetime-to-human entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'human-to-datetime'
        $c | Should -Match 'datetime-to-human'
    }
}
