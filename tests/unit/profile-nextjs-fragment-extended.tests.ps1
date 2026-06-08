<#
tests/unit/profile-nextjs-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/nextjs.ps1'
}
Describe 'profile.d/nextjs.ps1 extended scenarios' {
    It 'Declares standard tier for Next.js development helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.NextJs'
    }
    It 'Defines Start-NextJsDev wrapping npx next dev' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-NextJsDev'
        $c | Should -Match 'next dev'
    }
    It 'Registers next-dev and create-next-app aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'next-dev'"
        $c | Should -Match "Set-AgentModeAlias -Name 'create-next-app'"
    }
}
