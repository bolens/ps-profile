<#
tests/unit/profile-conversion-data-time-iso8601-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/time/iso8601.ps1'
}
Describe 'profile.d/conversion-modules/data/time/iso8601.ps1 extended scenarios' {
    It 'Documents ISO 8601 date/time conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ISO 8601 date/time conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-CoreTimeIso8601 with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreTimeIso8601'
        $c | Should -Match '_ConvertFrom-Iso8601ToDateTime'
    }
    It 'Registers iso8601-to-datetime and datetime-to-iso8601 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'iso8601-to-datetime'
        $c | Should -Match 'datetime-to-iso8601'
    }
}
