<#
tests/unit/profile-starship-init-extended.tests.ps1
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
