<#
tests/unit/profile-starship-prompt-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/starship/StarshipPrompt.ps1'
}
Describe 'profile.d/starship/StarshipPrompt.ps1 extended scenarios' {
    It 'Documents direct starship executable prompt creation' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Starship prompt function creation'
        $c | Should -Match 'bypassing module scope issues'
    }
    It 'Defines New-StarshipPromptFunction with StarshipCommandPath parameter' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'New-StarshipPromptFunction'
        $c | Should -Match 'StarshipCommandPath'
        $c | Should -Match 'Get-StarshipPromptArguments'
    }
    It 'Provides fallback prompt when helper is unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-StarshipPromptArguments not available'
        $c | Should -Match 'PS \$\('
    }
}
