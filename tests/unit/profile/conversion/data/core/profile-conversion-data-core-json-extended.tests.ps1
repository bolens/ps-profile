<#
tests/unit/profile-conversion-data-core-json-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/core/json.ps1'
}
Describe 'profile.d/conversion-modules/data/core/json.ps1 extended scenarios' {
    It 'Documents JSON format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'JSON format conversion utilities'
        $c | Should -Match 'Initialize-FileConversion-CoreBasic'
    }
    It 'Defines Initialize-FileConversion-CoreBasicJson with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-CoreBasicJson'
        $c | Should -Match '_Format-Json'
    }
    It 'Registers json-pretty and Format-Json entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'json-pretty'
        $c | Should -Match 'Format-Json'
    }
}
