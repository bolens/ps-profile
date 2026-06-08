<#
tests/unit/profile-nuget-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/nuget.ps1'
}
Describe 'profile.d/nuget.ps1 extended scenarios' {
    It 'Declares standard tier guarded by nuget availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand nuget\)'
    }
    It 'Defines Install-NuGetPackage with version and source parameters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-NuGetPackage'
        $c | Should -Match '\[string\]\$Version'
    }
    It 'Registers nugetinstall and nugetrestore aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'nugetinstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'nugetrestore'"
    }
}
