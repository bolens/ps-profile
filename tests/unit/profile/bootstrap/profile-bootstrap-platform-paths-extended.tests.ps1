<#
tests/unit/profile-bootstrap-platform-paths-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/PlatformPaths.ps1'
}
Describe 'profile.d/bootstrap/PlatformPaths.ps1 extended scenarios' {
    It 'Documents cross-platform directory resolution helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Cross-platform directory resolution helpers'
    }
    It 'Imports PlatformPaths module from scripts/lib/core' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PlatformPaths.psm1'
        $c | Should -Match "scripts' 'lib' 'core'"
        $c | Should -Match 'Import-Module'
    }
    It 'Resolves repo root relative to bootstrap directory' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'repoRoot'
        $c | Should -Match 'Split-Path'
        $c | Should -Match 'PS_PROFILE_DEBUG'
    }
}
