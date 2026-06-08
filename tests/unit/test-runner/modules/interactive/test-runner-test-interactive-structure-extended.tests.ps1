<#
tests/unit/test-runner-test-interactive-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestInteractive.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestInteractive.psm1 structure extended scenarios' {
    It 'Documents interactive test selection utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'interactive test selection'
        $c | Should -Match 'TestInteractive.psm1'
    }
    It 'Defines Select-TestsInteractively helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Select-TestsInteractively'
        $c | Should -Match 'SelectedTests'
        $c | Should -Match 'SelectedFiles'
    }
    It 'Exports interactive selection function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember'
        $c | Should -Match 'Select-TestsInteractively'
    }
}
