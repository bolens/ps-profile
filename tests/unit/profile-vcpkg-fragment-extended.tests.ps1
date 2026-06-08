<#
tests/unit/profile-vcpkg-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/vcpkg.ps1'
}
Describe 'profile.d/vcpkg.ps1 extended scenarios' {
    It 'Declares standard tier guarded by vcpkg availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand vcpkg\)'
    }
    It 'Defines Install-VcpkgPackage with triplet support for C++ libraries' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-VcpkgPackage'
        $c | Should -Match '\[string\]\$Triplet'
    }
    It 'Registers vcpkginstall and vcpkgupgrade aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'vcpkginstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'vcpkgupgrade'"
    }
}
