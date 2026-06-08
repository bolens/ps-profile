<#
tests/unit/test-runner-analyze-test-performance.tests.ps1

.SYNOPSIS
    Behavioral unit tests for analyze-test-performance.ps1 parameter validation.
#>

function global:Invoke-AnalyzeTestPerformanceScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:AnalyzeTestPerformanceScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

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
    $script:AnalyzeTestPerformanceScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'analyze-test-performance.ps1'
    $ConfirmPreference = 'None'
}

Describe 'analyze-test-performance.ps1 execution' {
    It 'Rejects TopN values outside the allowed range' {
        $result = Invoke-AnalyzeTestPerformanceScript -ArgumentList @('-TopN', '0')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'TopN|range|validation'
    }

    It 'Validates Suite values without enum load errors' {
        $result = Invoke-AnalyzeTestPerformanceScript -ArgumentList @('-Suite', 'Bogus')

        $result.Output | Should -Not -Match 'Unable to find type \[TestSuite\]'
        $result.Output | Should -Match 'Bogus|ValidateSet|cannot be validated'
        $result.ExitCode | Should -Not -Be 0
    }
}
