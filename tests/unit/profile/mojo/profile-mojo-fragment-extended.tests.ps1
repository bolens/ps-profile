<#
tests/unit/profile-mojo-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/mojo.ps1'
}
Describe 'profile.d/mojo.ps1 extended scenarios' {
    It 'Declares standard tier guarded by mojo availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand mojo'
    }
    It 'Defines Invoke-MojoRun and Build-MojoProgram helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-MojoRun'
        $c | Should -Match 'Build-MojoProgram'
    }
    It 'Registers mojo-run and mojo-build aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'mojo-run'"
        $c | Should -Match "Set-AgentModeAlias -Name 'mojo-build'"
    }
}
