<#
tests/unit/profile-utilities-env-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/utilities-modules/system/utilities-env.ps1'
}
Describe 'profile.d/utilities-modules/system/utilities-env.ps1 extended scenarios' {
    It 'Documents cross-platform environment variable management' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Environment variable management functions'
        $c | Should -Match 'Cross-platform persistent and session env var'
    }
    It 'Defines Get-EnvVar, Set-EnvVar, and Publish-EnvVar helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-EnvVar'
        $c | Should -Match 'Set-EnvVar'
        $c | Should -Match 'Publish-EnvVar'
        $c | Should -Match 'Platform.psm1'
    }
    It 'Provides Add-Path and Remove-Path PATH manipulation helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Add-Path'
        $c | Should -Match 'Remove-Path'
        $c | Should -Match 'Split-PathEnvironmentValue'
    }
}
