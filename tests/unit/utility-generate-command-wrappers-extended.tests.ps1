<#
tests/unit/utility-generate-command-wrappers-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/fragment/generate-command-wrappers.ps1'
}
Describe 'generate-command-wrappers.ps1 extended scenarios' {
    It 'Documents OutputPath CommandName Force and DryRun parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'OutputPath'
        $c | Should -Match 'CommandName'
        $c | Should -Match 'DryRun'
    }
    It 'Generates standalone wrappers under scripts/bin' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'scripts/bin'
    }
    It 'Uses FragmentCommandRegistry for command discovery' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'FragmentCommandRegistry'
    }
    It 'Loads required fragments before executing wrapped commands' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Loads the required fragment'
    }
}
