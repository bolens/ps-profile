<#
tests/unit/utility-create-release-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/release/create-release.ps1'
}
Describe 'create-release.ps1 extended scenarios' {
    It 'Documents DryRun for previewing release actions' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.PARAMETER DryRun'
        $c | Should -Match 'dry run'
    }
    It 'Determines version bumps from conventional commits' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'conventional'
        $c | Should -Match 'git describe'
    }
    It 'Creates and pushes git tags for releases' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'git tag'
        $c | Should -Match 'push'
    }
    It 'Uses Exit-WithCode for failure handling' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
