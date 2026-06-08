<#
tests/unit/test-runner-pester-execution-config-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/PesterExecutionConfig.psm1'
}
Describe 'scripts/utils/code-quality/modules/PesterExecutionConfig.psm1 structure extended scenarios' {
    It 'Documents Pester execution configuration module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PesterExecutionConfig.psm1'
        $c | Should -Match 'execution'
    }
    It 'Defines Set-PesterExecutionOptions and filter helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-PesterExecutionOptions'
        $c | Should -Match 'Set-PesterTestFilters'
    }
    It 'Exports execution configuration functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
    }
}

