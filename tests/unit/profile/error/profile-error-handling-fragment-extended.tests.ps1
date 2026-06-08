<#
tests/unit/profile-error-handling-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/error-handling.ps1'
}
Describe 'profile.d/error-handling.ps1 extended scenarios' {
    It 'Declares optional tier with bootstrap and env dependencies' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Loads diagnostics-error-handling module from diagnostics-modules/core' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'diagnostics-modules'
        $c | Should -Match 'diagnostics-error-handling\.ps1'
    }
    It 'Reports fragment load failures through Write-ProfileError when available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-ProfileError'
        $c | Should -Match 'Fragment: error-handling'
    }
}
