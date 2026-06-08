<#
tests/unit/profile-aws-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/aws.ps1'
}
Describe 'profile.d/aws.ps1 extended scenarios' {
    It 'Declares standard tier for cloud and development AWS helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: cloud, development'
    }
    It 'Defines Invoke-Aws guarded by Test-CachedCommand aws availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Aws'
        $c | Should -Match 'Test-CachedCommand aws'
    }
    It 'Documents PowerShell.Profile.Aws module metadata in comment help' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PowerShell.Profile.Aws'
    }
}
