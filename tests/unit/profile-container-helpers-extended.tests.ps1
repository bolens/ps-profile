<#
tests/unit/profile-container-helpers-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/container-modules/container-helpers.ps1'
}
Describe 'profile.d/container-modules/container-helpers.ps1 extended scenarios' {
    It 'Documents container engine detection and preference management' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Container engine helper functions'
        $c | Should -Match 'CONTAINER_ENGINE_PREFERENCE'
    }
    It 'Defines Get-ContainerEnginePreference with docker and podman detection' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ContainerEnginePreference'
        $c | Should -Match 'Test-CachedCommand docker'
        $c | Should -Match 'Test-CachedCommand podman'
    }
    It 'Defines Test-ContainerEngine and Set-ContainerEnginePreference helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-ContainerEngine'
        $c | Should -Match 'Set-ContainerEnginePreference'
        $c | Should -Match 'Get-ContainerEngineInfo'
    }
}
