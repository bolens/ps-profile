<#
tests/unit/profile-files-module-registry-specialized-extended.tests.ps1
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
Describe 'profile.d/files-module-registry.ps1 Ensure-FileConversion-Specialized registry extended scenarios' {
    It 'Maps Ensure-FileConversion-Specialized to specialized loader' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-FileConversion-Specialized'''
        $c | Should -Match 'conversion-modules/specialized'
    }
    It 'Loads specialized.ps1 thin loader module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'specialized.ps1'
    }
    It 'Sits after media registry block in deferred loading map' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-FileConversion-Media'''
        $c | Should -Match '''Ensure-FileConversion-Specialized'''
    }
}

