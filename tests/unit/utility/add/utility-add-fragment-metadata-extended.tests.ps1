<#
tests/unit/utility-add-fragment-metadata-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/fragment/add-fragment-metadata.ps1'
}
Describe 'add-fragment-metadata.ps1 extended scenarios' {
    It 'Documents Fragment and DryRun parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.PARAMETER Fragment'
        $c | Should -Match '\.PARAMETER DryRun'
    }
    It 'Adds Tier Dependencies and Environment metadata tags' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Tier'
        $c | Should -Match 'Dependencies'
        $c | Should -Match 'Environment'
    }
    It 'Scans profile.d fragments for missing metadata' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'profile\.d'
    }
    It 'Uses Exit-WithCode for validation failures' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
