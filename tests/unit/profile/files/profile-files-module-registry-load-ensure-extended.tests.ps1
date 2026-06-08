<#
tests/unit/profile-files-module-registry-load-ensure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-module-registry.ps1'
}
Describe 'profile.d/files-module-registry.ps1 Load-EnsureModules extended scenarios' {
    It 'Documents Load-EnsureModules deferred loading helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Load-EnsureModules'
        $c | Should -Match 'modules are only loaded when their Ensure function is called'
    }
    It 'Uses Import-FragmentModule when standardized loading is available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-FragmentModule'
        $c | Should -Match '-CacheResults'
        $c | Should -Match 'FileConversionModuleRegistry'
    }
    It 'Falls back to Invoke-GlobalProfileScript when import helper is missing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-GlobalProfileScript'
        $c | Should -Match 'Test-ModulePath'
        $c | Should -Match 'failedCount'
    }
}

