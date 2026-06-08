<#
tests/unit/profile-poetry-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/poetry.ps1'
}
Describe 'profile.d/poetry.ps1 extended scenarios' {
    It 'Declares standard tier guarded by poetry availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand poetry\)'
    }
    It 'Defines Add-PoetryDependency with dev test and docs group flags' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Add-PoetryDependency'
        $c | Should -Match '--group dev'
    }
    It 'Registers poetry-install and poetry-add aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'poetry-install'"
        $c | Should -Match "Set-AgentModeAlias -Name 'poetry-add'"
    }
}
