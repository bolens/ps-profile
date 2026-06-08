<#
tests/unit/profile-modern-cli-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/modern-cli.ps1'
}
Describe 'profile.d/modern-cli.ps1 extended scenarios' {
    It 'Declares standard tier for web and development environments' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Dot-sources modern-cli.ps1 from cli-modules directory' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'cli-modules'
        $c | Should -Match 'modern-cli\.ps1'
    }
    It 'Uses Write-ProfileError for fragment load failures when debug is enabled' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-ProfileError'
        $c | Should -Match 'Fragment: modern-cli'
    }
}
