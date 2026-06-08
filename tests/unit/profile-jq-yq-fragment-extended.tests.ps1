<#
tests/unit/profile-jq-yq-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/jq-yq.ps1'
}
Describe 'profile.d/jq-yq.ps1 extended scenarios' {
    It 'Declares essential tier for JSON and YAML conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'jq and yq helper'
    }
    It 'Defines Convert-JqToJson and Convert-YqToJson file converters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Convert-JqToJson'
        $c | Should -Match 'Convert-YqToJson'
    }
    It 'Registers jq2json and yq2json aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'jq2json'"
        $c | Should -Match "Set-AgentModeAlias -Name 'yq2json'"
    }
}
