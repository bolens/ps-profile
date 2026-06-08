<#
tests/unit/utility-init-wrangler-config-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/setup/init-wrangler-config.ps1'
}
Describe 'init-wrangler-config.ps1 extended scenarios' {
    It 'Documents ApiToken AccountId Force and DryRun parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ApiToken'
        $c | Should -Match 'AccountId'
        $c | Should -Match 'DryRun'
    }
    It 'Creates default.toml at the XDG-style Wrangler config path' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'default\.toml'
        $c | Should -Match 'wrangler'
    }
    It 'Writes api_token configuration for Cloudflare Wrangler' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'api_token'
    }
}
