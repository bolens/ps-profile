<#
tests/unit/profile-dev-tools-regex-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/format/regex.ps1'
}
Describe 'profile.d/dev-tools-modules/format/regex.ps1 extended scenarios' {
    It 'Documents regular expression testing and description utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Regular expression testing utilities'
        $c | Should -Match 'RegexUtilities.psm1'
    }
    It 'Defines Test-Regex and ConvertTo-RegexFromDescription helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-Regex'
        $c | Should -Match 'ConvertTo-RegexFromDescription'
        $c | Should -Match 'Initialize-DevTools-Regex'
    }
    It 'Registers regex-test and regex-explain aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'regex-test'"
        $c | Should -Match "Set-AgentModeAlias -Name 'regex-explain'"
        $c | Should -Match 'Get-RegexDescriptionCatalog'
    }
}
