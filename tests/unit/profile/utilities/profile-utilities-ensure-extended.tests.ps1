<#
tests/unit/profile-utilities-ensure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities.ps1'
}
Describe 'profile.d/utilities.ps1 Ensure-Utilities extended scenarios' {
    It 'Documents deferred utility module loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Utility Modules - DEFERRED LOADING'
        $c | Should -Match 'Ensure-Utilities function'
    }
    It 'References files-module-registry for module mappings' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'files-module-registry.ps1'
        $c | Should -Match 'Load-EnsureModules'
    }
    It 'Sets UtilitiesInitialized after registry load' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EnsureFunctionName ''Ensure-Utilities'''
        $c | Should -Match 'UtilitiesInitialized'
    }
}

