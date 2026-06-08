<#
tests/unit/profile-container-compose-podman-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/container-modules/container-compose-podman.ps1'
}
Describe 'profile.d/container-modules/container-compose-podman.ps1 extended scenarios' {
    It 'Documents Podman-first container compose operations' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Container compose functions \(Podman-first\)'
        $c | Should -Match 'preferring Podman over Docker'
    }
    It 'Defines Start-ContainerComposePodman and Stop-ContainerComposePodman helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-ContainerComposePodman'
        $c | Should -Match 'Stop-ContainerComposePodman'
        $c | Should -Match 'podman compose up -d'
    }
    It 'Registers pcu, pcd, pcl, and pprune compose aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'pcu'"
        $c | Should -Match "Set-AgentModeAlias -Name 'pcd'"
        $c | Should -Match "Set-AgentModeAlias -Name 'pcl'"
    }
}
