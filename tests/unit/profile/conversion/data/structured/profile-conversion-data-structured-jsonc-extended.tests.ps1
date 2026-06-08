<#
tests/unit/profile-conversion-data-structured-jsonc-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/jsonc.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/jsonc.ps1 extended scenarios' {
    It 'Documents JSONC \(JSON with Comments\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'JSONC \(JSON with Comments\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Jsonc with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Jsonc'
        $c | Should -Match '_ConvertFrom-JsoncToJson'
    }
    It 'Registers jsonc-to-json and json-to-jsonc entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'jsonc-to-json'
        $c | Should -Match 'json-to-jsonc'
    }
}
