<#
tests/unit/utility-update-embedded-install-hints-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/fragment/update-embedded-install-hints.ps1'
}
Describe 'update-embedded-install-hints.ps1 extended scenarios' {
    It 'Expands embedded Python and Node install hint templates' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Expand-EmbeddedPythonInstallHints'
        $c | Should -Match 'Expand-EmbeddedNodeInstallHints'
    }
    It 'Targets conversion-modules under profile.d' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'conversion-modules'
    }
    It 'Uses ModuleImport bootstrap when available' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'ModuleImport|repoRoot'
    }
}
