<#
tests/unit/profile-files-module-registry-utilities-extended.tests.ps1
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
Describe 'profile.d/files-module-registry.ps1 Ensure-Utilities registry extended scenarios' {
    It 'Maps Ensure-Utilities to utilities-modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '''Ensure-Utilities'''
        $c | Should -Match 'utilities-modules/system'
    }
    It 'Includes system network and history utility modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'utilities-profile.ps1'
        $c | Should -Match 'utilities-network.ps1'
        $c | Should -Match 'utilities-history.ps1'
    }
    It 'Includes data and filesystem utility modules' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'utilities-encoding.ps1'
        $c | Should -Match 'utilities-datetime.ps1'
        $c | Should -Match 'utilities-filesystem.ps1'
    }
}

