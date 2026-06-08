<#
tests/unit/test-runner-pester-config-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/PesterConfig.psm1'
}
Describe 'scripts/utils/code-quality/modules/PesterConfig.psm1 structure extended scenarios' {
    It 'Documents Pester configuration management module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Pester configuration utilities'
        $c | Should -Match 'PesterConfig.psm1'
    }
    It 'Defines New-PesterTestConfiguration with submodule imports' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-PesterTestConfiguration'
        $c | Should -Match 'PesterOutputConfig.psm1'
        $c | Should -Match 'PesterExecutionConfig.psm1'
    }
    It 'Uses PesterVerbosity enum from CommonEnums' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PesterVerbosity'
        $c | Should -Match 'CommonEnums.psm1'
        $c | Should -Match 'Export-ModuleMember'
    }
}
