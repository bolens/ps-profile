<#
tests/unit/profile-dev-tools-lorem-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dev-tools-modules/data/lorem.ps1'
}
Describe 'profile.d/dev-tools-modules/data/lorem.ps1 extended scenarios' {
    It 'Documents Lorem Ipsum text generation utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Lorem Ipsum text generation utilities'
        $c | Should -Match 'Ensure-DevTools'
    }
    It 'Defines Get-LoremIpsum with words and paragraphs parameters' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-LoremIpsum'
        $c | Should -Match 'Initialize-DevTools-Lorem'
        $c | Should -Match 'StartWithLorem'
    }
    It 'Registers lorem alias targeting Get-LoremIpsum' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'lorem'"
        $c | Should -Match "Target 'Get-LoremIpsum'"
    }
}
