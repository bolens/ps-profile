<#
tests/unit/utility-debug-run-tests-with-interception-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for scripts/utils/debug/run-tests-with-interception.ps1.
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/debug/run-tests-with-interception.ps1'
}
Describe 'run-tests-with-interception.ps1 extended scenarios' {
    It 'Requires a mandatory TestFile parameter' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\[Parameter\(Mandatory\)\]'
        $c | Should -Match 'TestFile'
    }
    It 'Loads intercept-testpath.ps1 before invoking Pester' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'intercept-testpath\.ps1'
        $c | Should -Match 'Invoke-Pester'
    }
    It 'Runs tests in an isolated pwsh child process' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'pwsh -NoProfile -Command'
    }
}
