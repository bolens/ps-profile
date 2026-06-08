<#
tests/unit/utility-debug-intercept-testpath-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/intercept-testpath.ps1.
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/intercept-testpath.ps1'
}
Describe 'intercept-testpath.ps1 extended scenarios' {
    It 'Shadows Test-Path with a logging wrapper function' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'function global:Test-Path'
        $c | Should -Match 'originalTestPath'
    }
    It 'Supports both Path and LiteralPath parameter sets' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match "ParameterSetName = 'Path'"
        $c | Should -Match "ParameterSetName = 'LiteralPath'"
    }
    It 'Logs null or empty path usage before delegating to the original cmdlet' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'null or empty'
    }
}
