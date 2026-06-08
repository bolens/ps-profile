<#
tests/unit/profile-conversion-base-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/helpers/ConversionBase.ps1'
}
Describe 'profile.d/conversion-modules/helpers/ConversionBase.ps1 extended scenarios' {
    It 'Documents base module for format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base module for format conversion utilities'
        $c | Should -Match 'Input file validation'
        $c | Should -Match 'Tool availability checking'
    }
    It 'Defines Invoke-FormatConversion with standardized validation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-FormatConversion'
        $c | Should -Match 'Test-ConversionToolAvailable'
        $c | Should -Match 'Get-OutputPathFromInput'
    }
    It 'Marks conversion-base fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'conversion-base'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'conversion-base'"
    }
}
