<#
tests/unit/profile-conversion-data-structured-sexpr-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/data/structured/sexpr.ps1'
}
Describe 'profile.d/conversion-modules/data/structured/sexpr.ps1 extended scenarios' {
    It 'Documents S-Expressions \(Lisp-style\) format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'S-Expressions \(Lisp-style\) format conversion utilities'
        $c | Should -Match 'Ensure-FileConversion-Data'
    }
    It 'Defines Initialize-FileConversion-Sexpr with core conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-Sexpr'
        $c | Should -Match '_ConvertFrom-SexprToJson'
    }
    It 'Registers _ConvertTo-SexprFromJson and _ConvertFrom-SexprToYaml entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertTo-SexprFromJson'
        $c | Should -Match '_ConvertFrom-SexprToYaml'
    }
}
