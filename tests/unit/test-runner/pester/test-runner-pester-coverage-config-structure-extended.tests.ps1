<#
tests/unit/test-runner-pester-coverage-config-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/PesterCoverageConfig.psm1'
}
Describe 'scripts/utils/code-quality/modules/PesterCoverageConfig.psm1 structure extended scenarios' {
    It 'Documents Pester code coverage configuration module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PesterCoverageConfig.psm1'
        $c | Should -Match 'code coverage'
    }
    It 'Defines Set-PesterCodeCoverage helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-PesterCodeCoverage'
    }
    It 'Exports coverage configuration function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Set-PesterCodeCoverage'
    }
}

