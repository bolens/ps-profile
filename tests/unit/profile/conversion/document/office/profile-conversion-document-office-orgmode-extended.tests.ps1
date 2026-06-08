<#
tests/unit/profile-conversion-document-office-orgmode-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-office-orgmode.ps1'
}
Describe 'profile.d/conversion-modules/document/document-office-orgmode.ps1 extended scenarios' {
    It 'Documents Org-mode document format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Org-mode format conversion utilities'
        $c | Should -Match 'Requires pandoc for conversions'
    }
    It 'Defines Initialize-FileConversion-DocumentOfficeOrgmode with org conversions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentOfficeOrgmode'
        $c | Should -Match '_ConvertFrom-OrgmodeToMarkdown'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers org-to-markdown and org-to-html aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'org-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'org-to-html'"
    }
}
