<#
tests/unit/profile-files-ensure-dev-tools-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files.ps1'
}
Describe 'profile.d/files.ps1 Ensure-DevTools extended scenarios' {
    It 'Documents lazy dev tools initializer' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Ensure-DevTools'
        $c | Should -Match 'dev tools utility functions on first use'
    }
    It 'Loads dev tools modules from registry' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Load-EnsureModules -EnsureFunctionName ''Ensure-DevTools'''
        $c | Should -Match 'dev-tools-modules'
    }
    It 'Initializes crypto formatting and data dev tool modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-DevTools-Hash'
        $c | Should -Match 'Initialize-DevTools-QrCode'
        $c | Should -Match 'Initialize-DevTools-Units'
    }
}

