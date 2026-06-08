<#
tests/unit/profile-diagnostics-error-handling-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/diagnostics-modules/core/diagnostics-error-handling.ps1'
}
Describe 'profile.d/diagnostics-modules/core/diagnostics-error-handling.ps1 extended scenarios' {
    It 'Documents enhanced error handling and recovery mechanisms' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Error handling diagnostic functions'
        $c | Should -Match 'Global error handler with smart fallbacks'
    }
    It 'Defines Write-ProfileError and Invoke-SafeFragmentLoad helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-ProfileError'
        $c | Should -Match 'Invoke-ProfileErrorHandler'
        $c | Should -Match 'Invoke-SafeFragmentLoad'
        $c | Should -Match 'ErrorHandlingLoaded'
    }
    It 'Sets ErrorHandlingLoaded global after initialization' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Get-Variable -Name 'ErrorHandlingLoaded'"
        $c | Should -Match "Set-Variable -Name 'ErrorHandlingLoaded'"
    }
}
