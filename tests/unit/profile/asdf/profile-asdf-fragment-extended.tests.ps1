<#
tests/unit/profile-asdf-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/asdf.ps1'
}
Describe 'profile.d/asdf.ps1 extended scenarios' {
    It 'Declares standard tier guarded by asdf availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand asdf'
    }
    It 'Defines Install-AsdfTool for multi-language version installs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Install-AsdfTool'
        $c | Should -Match 'asdf install'
    }
    It 'Registers asdfinstall and asdfadd aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'asdfinstall'"
        $c | Should -Match "Set-AgentModeAlias -Name 'asdfadd'"
    }
}
