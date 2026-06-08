<#
tests/unit/profile-system-ensure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system.ps1'
}
Describe 'profile.d/system.ps1 Ensure-System extended scenarios' {
    It 'Documents deferred system module loading' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'System Modules - DEFERRED LOADING'
        $c | Should -Match 'Ensure-System function'
    }
    It 'References files-module-registry for module mappings' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'files-module-registry.ps1'
        $c | Should -Match 'Load-EnsureModules'
    }
    It 'Sets SystemInitialized after registry load' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'EnsureFunctionName ''Ensure-System'''
        $c | Should -Match 'SystemInitialized'
    }
}

