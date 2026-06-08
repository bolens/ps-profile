<#
tests/unit/utility-init-wrangler-config.tests.ps1

.SYNOPSIS
    Behavioral unit tests for init-wrangler-config.ps1 dry-run execution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:InitWranglerScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'setup' 'init-wrangler-config.ps1'
    $ConfirmPreference = 'None'
}

Describe 'init-wrangler-config.ps1 execution' {
    It 'DryRun previews config creation without prompting for an API token' {
        $result = Invoke-TestScriptFile -ScriptPath $script:InitWranglerScript -ArgumentList @('-DryRun')

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'DRY RUN'
        $result.Output | Should -Not -Match 'Enter Cloudflare API token'
    }
}
