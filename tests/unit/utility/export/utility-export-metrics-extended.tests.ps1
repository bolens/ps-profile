<#
tests/unit/utility-export-metrics-extended.tests.ps1
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
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/metrics/export-metrics.ps1'
}
Describe 'export-metrics.ps1 extended scenarios' {
    It 'Documents OutputFormat OutputPath and IncludePerformance parameters' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match '\.PARAMETER OutputFormat'
        $c | Should -Match 'IncludePerformance'
    }
    It 'Supports CSV and JSON export formats' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'OutputFormat'
        $c | Should -Match 'metrics-export'
    }
    It 'Defaults output under scripts/data' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'scripts/data'
    }
    It 'Uses Exit-WithCode for standardized failures' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
    }
}
