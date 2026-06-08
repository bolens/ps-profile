<#
tests/unit/profile-starship-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/starship.ps1'
}
Describe 'profile.d/starship.ps1 extended scenarios' {
    It 'Declares essential tier with bootstrap dependency' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Loads starship helper modules from profile.d/starship subdirectory' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'StarshipInit\.ps1'
        $c | Should -Match 'SmartPrompt\.ps1'
    }
    It 'Defines Initialize-Starship using Test-CachedCommand and starship.toml config' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-Starship'
        $c | Should -Match "Test-CachedCommand 'starship'"
        $c | Should -Match 'starship\.toml'
    }
}
