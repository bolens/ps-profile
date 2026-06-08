<#
tests/unit/utility-debug-trace-testpath.tests.ps1

.SYNOPSIS
    Behavioral unit tests for trace-testpath.ps1 with a minimal Pester file.
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
    $script:TraceTestPathScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'debug' 'trace-testpath.ps1'
    $ConfirmPreference = 'None'
}

Describe 'trace-testpath.ps1 execution' {
    It 'Runs a minimal unit test file with tracing enabled' {
        $minimalTest = Join-Path (New-TestTempDirectory -Prefix 'TraceMinimalTest') 'minimal.tests.ps1'
        try {
            Set-Content -LiteralPath $minimalTest -Value @'
Describe 'trace minimal fixture' {
    It 'passes' {
        $true | Should -BeTrue
    }
}
'@ -Encoding UTF8

            Push-Location $script:TestRepoRoot
            try {
                $result = Invoke-TestScriptFile -ScriptPath $script:TraceTestPathScript -ArgumentList @(
                    '-TestFile', $minimalTest
                )

                $result.Output | Should -Match 'Test-Path Tracing Enabled'
                $result.Output | Should -Match '=== Test Results ===|Tests Passed|Passed:'
                $result.ExitCode | Should -BeIn @(0, 1)
            }
            finally {
                Pop-Location
            }
        }
        finally {
            $parent = Split-Path -Parent $minimalTest
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
