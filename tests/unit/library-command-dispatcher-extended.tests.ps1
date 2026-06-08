<#
tests/unit/library-command-dispatcher-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ModulePath = Join-Path $script:TestRepoRoot 'scripts/lib/fragment/CommandDispatcher.psm1'
}
Describe 'scripts/lib/fragment/CommandDispatcher.psm1 extended scenarios' {
    It 'Documents command-not-found dispatcher for fragment auto-loading' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'Command-not-found dispatcher for on-demand fragment loading'
        $c | Should -Match 'PS_PROFILE_AUTO_LOAD_FRAGMENTS'
    }
    It 'Defines Invoke-CommandDispatcher and auto-load timeout helpers' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'Invoke-CommandDispatcher'
        $c | Should -Match 'Get-AutoLoadTimeoutSeconds'
        $c | Should -Match 'Test-RegistryAvailable'
    }
    It 'Registers and unregisters CommandNotFoundAction handler' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'Register-CommandDispatcher'
        $c | Should -Match 'Unregister-CommandDispatcher'
        $c | Should -Match 'CommandNotFoundAction'
    }
}
