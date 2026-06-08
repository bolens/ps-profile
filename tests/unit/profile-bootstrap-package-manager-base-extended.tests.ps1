<#
tests/unit/profile-bootstrap-package-manager-base-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/PackageManagerBase.ps1'
}
Describe 'profile.d/bootstrap/PackageManagerBase.ps1 extended scenarios' {
    It 'Documents base module for package manager CLI wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Base module for package manager wrappers'
        $c | Should -Match 'npm, yarn, pip, cargo'
    }
    It 'Defines Register-PackageManager for standardized manager commands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Register-PackageManager'
        $c | Should -Match 'Install/uninstall packages'
        $c | Should -Match 'Manage lock files'
    }
    It 'Marks package-manager-base fragment loaded after registration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Test-FragmentLoaded -FragmentName 'package-manager-base'"
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'package-manager-base'"
    }
}
