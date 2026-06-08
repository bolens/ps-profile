<#
tests/unit/profile-bootstrap-install-hint-resolver-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/InstallHintResolver.ps1'
}
Describe 'profile.d/bootstrap/InstallHintResolver.ps1 extended scenarios' {
    It 'Documents preference-aware install hint resolution' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Preference-aware install hint resolution'
        $c | Should -Match 'ToolInstallRegistry.ps1'
    }
    It 'Defines Get-PreferenceAwareInstallHint and Invoke-MissingToolWarning' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-PreferenceAwareInstallHint'
        $c | Should -Match 'Invoke-MissingToolWarning'
        $c | Should -Match 'PS_PYTHON_PACKAGE_MANAGER'
    }
    It 'Defines Resolve-InstallPackageName and Get-PlatformInstallHint' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Resolve-InstallPackageName'
        $c | Should -Match 'Get-PlatformInstallHint'
        $c | Should -Match 'Get-ContainerEngineInstallHint'
    }
}
