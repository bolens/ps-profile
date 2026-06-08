<#
tests/unit/profile-lang-python-packages-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-python-packages.ps1'
}
Describe 'profile.d/lang-python-packages.ps1 extended scenarios' {
    It 'Declares standard tier for unified Python package installation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Install-PythonPackage'
    }
    It 'Prefers uv then pip for Install-PythonPackage resolution' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'uv \(if available\)'
        $c | Should -Match 'pip \(if available\)'
    }
    It 'Registers pyinstall alias for Install-PythonPackage' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'pyinstall'"
        $c | Should -Match 'Install-PythonPackage'
    }
}
