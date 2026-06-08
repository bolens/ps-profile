<#
tests/unit/profile-bun-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bun.ps1'
}
Describe 'profile.d/bun.ps1 extended scenarios' {
    It 'Declares standard tier for web and development Bun helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Invoke-Bunx and Invoke-BunRun guarded by bun availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Bunx'
        $c | Should -Match 'function Invoke-BunRun'
        $c | Should -Match 'Test-CachedCommand bun'
    }
    It 'Registers bunx alias and documents PowerShell.Profile.Bun module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'bunx'"
        $c | Should -Match 'PowerShell.Profile.Bun'
    }
}
