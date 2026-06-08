<#
tests/unit/profile-conversion-document-fb2-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/document/document-fb2.ps1'
}
Describe 'profile.d/conversion-modules/document/document-fb2.ps1 extended scenarios' {
    It 'Documents FictionBook FB2 e-book conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FB2 \(FictionBook\) e-book format conversion utilities'
        $c | Should -Match 'FictionBook'
    }
    It 'Defines Initialize-FileConversion-DocumentFb2 with pandoc fb2 format' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-DocumentFb2'
        $c | Should -Match '-f fb2'
        $c | Should -Match "Test-CachedCommand 'pandoc'"
    }
    It 'Registers fb2-to-markdown and fb2-to-html aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'fb2-to-markdown'"
        $c | Should -Match "Set-AgentModeAlias -Name 'fb2-to-html'"
    }
}
