<#
tests/unit/profile-nuxt-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/nuxt.ps1'
}
Describe 'profile.d/nuxt.ps1 extended scenarios' {
    It 'Declares standard tier for Nuxt.js nuxi CLI helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.Nuxt'
    }
    It 'Defines Invoke-Nuxt wrapping nuxi commands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Nuxt'
        $c | Should -Match 'nuxi'
    }
    It 'Registers nuxi and nuxt-dev aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'nuxi'"
        $c | Should -Match "Set-AgentModeAlias -Name 'nuxt-dev'"
    }
}
