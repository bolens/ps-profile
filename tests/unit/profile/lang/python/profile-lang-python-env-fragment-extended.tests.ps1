<#
tests/unit/profile-lang-python-env-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lang-python-env.ps1'
}
Describe 'profile.d/lang-python-env.ps1 extended scenarios' {
    It 'Declares standard tier for Python runtime and virtualenv helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Defines Invoke-PythonScript and New-PythonVirtualEnv wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-PythonScript'
        $c | Should -Match 'New-PythonVirtualEnv'
    }
    It 'Registers pyvenv alias targeting New-PythonVirtualEnv' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'pyvenv'"
        $c | Should -Match 'New-PythonVirtualEnv'
    }
}
