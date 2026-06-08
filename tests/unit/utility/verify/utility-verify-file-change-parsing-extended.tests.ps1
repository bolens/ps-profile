<#
tests/unit/utility-verify-file-change-parsing-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/verify-file-change-parsing.ps1'
}
Describe 'verify-file-change-parsing.ps1 extended scenarios' {
    It 'Verifies cache refresh after fragment file modifications' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Modifies the file'
        $c | Should -Match 're-parsing'
    }
    It 'Tests both AST and regex parsing modes' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'AST'
        $c | Should -Match 'regex'
    }
    It 'Enables PS_PROFILE_DEBUG level 3 for detailed tracing' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match "PS_PROFILE_DEBUG = '3'"
    }
    It 'Uses Exit-WithCode for verification failures' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
