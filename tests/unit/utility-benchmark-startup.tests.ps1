<#
tests/unit/utility-benchmark-startup.tests.ps1

.SYNOPSIS
    Behavioral unit tests for benchmark-startup.ps1 parameter validation.
#>

function global:Invoke-BenchmarkStartupScript {
    param(
        [string[]]$ArgumentList
    )

    $output = & pwsh -NoProfile -File $script:BenchmarkStartupScript @ArgumentList 2>&1 | Out-String
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:BenchmarkStartupScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'benchmark-startup.ps1'
    $ConfirmPreference = 'None'
}

Describe 'benchmark-startup.ps1 execution' {
    It 'Rejects non-positive Iterations values' {
        $result = Invoke-BenchmarkStartupScript -ArgumentList @('-Iterations', '0')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Iterations must be a positive integer'
    }

    It 'Rejects invalid WorkspaceRoot paths' {
        $invalidPath = Join-Path (New-TestTempDirectory -Prefix 'MissingWorkspace') 'does-not-exist'
        $result = Invoke-BenchmarkStartupScript -ArgumentList @('-WorkspaceRoot', $invalidPath, '-Iterations', '1')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'WorkspaceRoot must be a valid directory path'
    }

    It 'Completes a single-iteration startup benchmark smoke test' {
        if ($env:CI -eq 'true' -or $env:GITHUB_ACTIONS -eq 'true') {
            Set-ItResult -Skipped -Because 'startup benchmark smoke test is too slow for CI'
            return
        }

        $result = Invoke-BenchmarkStartupScript -ArgumentList @(
            '-Iterations', '1',
            '-WorkspaceRoot', $script:TestRepoRoot
        )

        $result.Output | Should -Match 'Measuring full profile startup'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }
}
