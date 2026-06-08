<#
tests/unit/profile-system-text-search-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system/TextSearch.ps1'
}
Describe 'profile.d/system/TextSearch.ps1 extended scenarios' {
    It 'Documents text search utilities as grep equivalent' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Text search utilities'
        $c | Should -Match "Unix 'grep' equivalent"
    }
    It 'Defines Find-String with Select-String and Invoke-WithWideEvent' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Find-String'
        $c | Should -Match 'Select-String'
        $c | Should -Match 'textsearch.find-string'
    }
    It 'Registers pgrep alias targeting Find-String' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'pgrep'"
        $c | Should -Match "Target 'Find-String'"
    }
}
