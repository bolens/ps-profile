<#
tests/unit/profile-dotnet-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dotnet.ps1'
}
Describe 'profile.d/dotnet.ps1 extended scenarios' {
    It 'Declares standard tier guarded by dotnet CLI availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand dotnet'
    }
    It 'Defines Test-DotnetOutdated using dotnet list package --outdated' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-DotnetOutdated'
        $c | Should -Match 'dotnet list package --outdated'
    }
    It 'Registers dotnet-outdated and dotnet-update aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'dotnet-outdated'"
        $c | Should -Match "Set-AgentModeAlias -Name 'dotnet-update'"
    }
}
