<#
tests/unit/profile-starship-module-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/starship/StarshipModule.ps1'
}
Describe 'profile.d/starship/StarshipModule.ps1 extended scenarios' {
    It 'Documents Starship module retention for prompt stability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Starship module management'
        $c | Should -Match 'garbage collected'
    }
    It 'Defines Initialize-StarshipModule to store global module reference' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-StarshipModule'
        $c | Should -Match 'Get-Module starship'
        $c | Should -Match 'StarshipModule'
    }
    It 'Emits debug output when PS_PROFILE_DEBUG is set' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PS_PROFILE_DEBUG'
        $c | Should -Match 'Starship module loaded and stored globally'
    }
}
