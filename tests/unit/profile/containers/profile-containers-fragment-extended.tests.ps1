<#
tests/unit/profile-containers-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/containers.ps1'
}
Describe 'profile.d/containers.ps1 extended scenarios' {
    It 'Declares essential tier with bootstrap dependency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Loads container modules via Import-FragmentModules when available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-FragmentModules'
        $c | Should -Match 'container-modules'
    }
    It 'Includes compose helpers for docker and podman' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'container-compose\.ps1'
        $c | Should -Match 'container-compose-podman\.ps1'
    }
}
