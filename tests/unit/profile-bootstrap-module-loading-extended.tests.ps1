<#
tests/unit/profile-bootstrap-module-loading-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/ModuleLoading.ps1'
}
Describe 'profile.d/bootstrap/ModuleLoading.ps1 extended scenarios' {
    It 'Documents standardized module loading system for fragments' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Standardized module loading system'
        $c | Should -Match 'Path validation and caching'
    }
    It 'Defines Import-FragmentModule with dependency and retry support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Import-FragmentModule'
        $c | Should -Match 'Import-FragmentModules'
        $c | Should -Match 'Test-ModulePath'
    }
    It 'Defines Invoke-GlobalProfileScript and Test-FragmentModulePath' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-GlobalProfileScript'
        $c | Should -Match 'Test-FragmentModulePath'
        $c | Should -Match 'RetryCount'
    }
}
