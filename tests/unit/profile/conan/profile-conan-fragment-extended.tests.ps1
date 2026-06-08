<#
tests/unit/profile-conan-fragment-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conan.ps1'
}
Describe 'profile.d/conan.ps1 extended scenarios' {
    It 'Declares standard tier guarded by conan availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand conan\)'
    }
    It 'Defines Install-ConanPackages with build and profile parameters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-ConanPackages'
        $c | Should -Match 'conan install'
    }
    It 'Registers conaninstall and conansearch aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'conaninstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'conansearch'"
    }
}
