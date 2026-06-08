<#
tests/unit/profile-bootstrap-tool-install-registry-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/ToolInstallRegistry.ps1'
}
Describe 'profile.d/bootstrap/ToolInstallRegistry.ps1 extended scenarios' {
    It 'Documents tool install method registry for missing tool hints' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tool installation method registry'
        $c | Should -Match 'Get-ToolInstallMethodRegistry'
    }
    It 'Defines Get-ToolSpecificInstallMethod and Get-InstallMethodFallbackChain' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ToolSpecificInstallMethod'
        $c | Should -Match 'Get-InstallMethodFallbackChain'
        $c | Should -Match 'Test-CommandAvailable'
    }
    It 'Defines preference-aware install preference helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-PreferenceAwareInstallPreferences'
        $c | Should -Match 'Set-PreferenceAwareInstallPreferences'
        $c | Should -Match 'Show-MissingToolWarningsTable'
    }
}
