<#
tests/unit/test-runner-check-missing-tests.tests.ps1

.SYNOPSIS
    Behavioral unit tests for check-missing-tests.ps1 module coverage audit.
#>

function global:Invoke-CheckMissingTestsScript {
    $output = & pwsh -NoProfile -File $script:CheckScript 2>&1 | Out-String
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
    $script:CheckScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'code-quality' 'check-missing-tests.ps1'
}

Describe 'check-missing-tests.ps1 execution' {
    It 'Recursively scans scripts/lib and reports full module coverage for this repository' {
        $result = Invoke-CheckMissingTestsScript

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Total modules:\s+[1-9]\d*'
        $result.Output | Should -Match 'Modules with tests:\s+[1-9]\d*'
        $result.Output | Should -Match 'Missing tests for:\s*\(none\)'
    }
}
