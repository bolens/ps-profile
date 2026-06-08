<#
tests/unit/profile-starship-init-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/starship/StarshipInit.ps1'
}
Describe 'profile.d/starship/StarshipInit.ps1 extended scenarios' {
    It 'Documents Starship initialization script execution flow' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Starship initialization script'
        $c | Should -Match 'print-full-init'
    }
    It 'Defines Invoke-StarshipInitScript with temp file execution' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-StarshipInitScript'
        $c | Should -Match 'StarshipCommandPath'
        $c | Should -Match 'GetTempFileName'
    }
    It 'Filters error lines from starship init output before execution' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Filter out error messages and empty lines'
        $c | Should -Match 'cleanOutput'
        $c | Should -Match 'Under a'
    }
}
