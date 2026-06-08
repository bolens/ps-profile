<#
tests/unit/profile-psreadline-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/psreadline.ps1'
}
Describe 'profile.d/psreadline.ps1 extended scenarios' {
    It 'Declares essential tier for command-line editing configuration' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Imports PSReadLine only when the module is list-available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-Module -ListAvailable -Name PSReadLine'
        $c | Should -Match 'Import-Module PSReadLine'
    }
    It 'Configures prediction and key handlers with SilentlyContinue error handling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-PSReadLineOption -PredictionSource'
        $c | Should -Match 'Set-PSReadLineKeyHandler'
    }
}
