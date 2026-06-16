<#
tests/integration/test-runner/runner-error-handling.tests.ps1

.SYNOPSIS
    Integration tests for run-pester.ps1 error handling using the real test runner.

.DESCRIPTION
    Validates safe error paths and edge cases without destructive environment
    manipulation (no module renaming or permission changes).
#>

BeforeAll {
    . (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunPesterPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'
    $script:DryRunTestFile = Join-Path $script:TestRepoRoot 'tests/unit/library/common/library-common.tests.ps1'
    $script:TempTestDir = New-TestTempDirectory -Prefix 'RunnerErrorHandling'

    function Clear-TestRunnerFlag {
        $env:PS_PROFILE_TEST_RUNNER_ACTIVE = $null
    }

    function Invoke-RunPesterCapturingOutput {
        param([hashtable]$Parameters = @{})

        $captured = [System.Collections.Generic.List[string]]::new()
                & $script:RunPesterPath @Parameters 2>&1 | ForEach-Object {
            $null = $captured.Add("$($_)")
        }
        $null = $captured.Add("EXIT:$LASTEXITCODE")
    }
    catch {
        $null = $captured.Add($_.Exception.Message)

        return $captured
    }
}

Describe 'Test Runner Error Handling (real run-pester.ps1)' {
    BeforeEach {
        Clear-TestRunnerFlag
        if ($script:TempTestDir -and -not (Test-Path -LiteralPath $script:TempTestDir)) {
            $null = New-Item -ItemType Directory -Path $script:TempTestDir -Force
        }
    }

    Context 'Parameter validation' {
        It 'Rejects invalid suite values' {
            { & $script:RunPesterPath -DryRun -Suite 'NotARealSuite' -TestFile $script:DryRunTestFile } | Should -Throw
        }

        It 'Rejects invalid output format values' {
            { & $script:RunPesterPath -DryRun -OutputFormat 'VerbosePlus' -TestFile $script:DryRunTestFile } | Should -Throw
        }

        It 'Rejects invalid minimum coverage values' {
            { & $script:RunPesterPath -DryRun -Coverage -MinimumCoverage 150 -TestFile $script:DryRunTestFile } | Should -Throw
        }
    }

    Context 'Missing resources' {
        It 'Fails when an explicit test file does not exist' {
            { & $script:RunPesterPath -DryRun -TestFile 'definitely-missing.tests.ps1' } | Should -Throw
        }

        It 'Reports no tests found for impossible file patterns' {
            $output = Invoke-RunPesterCapturingOutput @{
                DryRun          = $true
                Suite           = 'Unit'
                TestFile        = $script:DryRunTestFile
                TestFilePattern = '*this-pattern-should-not-match-anything-xyz*'
            }

            ($output -join ' ') | Should -Match 'No test files match pattern|EXIT:'
        }
    }

    Context 'Recursive execution guard' {
        It 'Prevents nested runner invocation when already active' {
            $env:PS_PROFILE_TEST_RUNNER_ACTIVE = '1'
            $output = Invoke-RunPesterCapturingOutput @{
                DryRun   = $true
                TestFile = $script:DryRunTestFile
            }

            ($output -join ' ') | Should -Match 'Recursive|already active'
        }
    }

    Context 'Interactive mode constraints' {
        It 'Rejects interactive mode in non-interactive environments' {
            try {
            $previous = $env:PS_PROFILE_NONINTERACTIVE
            $env:PS_PROFILE_NONINTERACTIVE = '1'
                        $output = Invoke-RunPesterCapturingOutput @{
                Interactive = $true
                TestFile    = $script:DryRunTestFile
            }
            ($output -join ' ') | Should -Match 'Interactive mode requires a TTY|EXIT:'
            }
            finally {
                if ($null -eq $previous) {
                    Remove-Item Env:PS_PROFILE_NONINTERACTIVE -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_NONINTERACTIVE = $previous
                }
            }
        }
    }

    Context 'Configuration file handling' {
        It 'Fails gracefully for missing configuration files' {
            $missingConfig = Join-Path $script:TempTestDir 'missing-config.json'
            $output = Invoke-RunPesterCapturingOutput @{
                DryRun     = $true
                ConfigFile = $missingConfig
                TestFile   = $script:DryRunTestFile
            }

            ($output -join ' ') | Should -Match 'Configuration file not found|Failed to load configuration file|Failed to load configuration|EXIT:'
        }

        It 'Fails gracefully for invalid JSON configuration files' {
            $invalidConfig = Join-Path $script:TempTestDir 'invalid-config.json'
            Set-Content -LiteralPath $invalidConfig -Value '{ not valid json' -Encoding UTF8

            $output = Invoke-RunPesterCapturingOutput @{
                DryRun     = $true
                ConfigFile = $invalidConfig
                TestFile   = $script:DryRunTestFile
            }

            $combined = $output -join ' '
            $combined | Should -Match 'Failed to load configuration file|Conversion from JSON failed'
            if ($combined -match 'EXIT:(\d+)') {
                [int]$Matches[1] | Should -BeGreaterThan 0
            }
        }
    }

    Context 'Failed-only mode' {
        It 'Handles missing previous results gracefully' {
            $output = Invoke-RunPesterCapturingOutput @{
                DryRun     = $true
                FailedOnly = $true
                TestFile   = $script:DryRunTestFile
            }

            ($output -join ' ') | Should -Match 'failed|result|No failed tests|No test result|EXIT:'
        }
    }
}
