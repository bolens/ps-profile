<#
tests/unit/profile-container-compose-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/container-modules/container-compose.ps1'
}
Describe 'profile.d/container-modules/container-compose.ps1 extended scenarios' {
    It 'Documents Docker-first container compose operations' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Container compose functions \(Docker-first\)'
        $c | Should -Match 'preferring Docker over Podman'
    }
    It 'Defines Start-ContainerCompose and Stop-ContainerCompose using Get-ContainerEngineInfo' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-ContainerCompose'
        $c | Should -Match 'Stop-ContainerCompose'
        $c | Should -Match 'Get-ContainerEngineInfo'
        $c | Should -Match 'docker compose up -d'
    }
    It 'Registers dcu, dcd, dcl, and dprune compose aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'dcu'"
        $c | Should -Match "Set-AgentModeAlias -Name 'dcd'"
        $c | Should -Match "Set-AgentModeAlias -Name 'dcl'"
    }
}
