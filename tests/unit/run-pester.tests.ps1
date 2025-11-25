<#
tests/unit/run-pester.tests.ps1

.SYNOPSIS
    Tests for the main run-pester.ps1 script.

.DESCRIPTION
    Integration tests for the PowerShell profile test runner script,
    testing parameter handling, module integration, and end-to-end functionality.
#>

BeforeAll {
    # Import test support
    . $PSScriptRoot/../TestSupport.ps1

    # Set up test environment
    $script:TestRepoRoot = Split-Path $PSScriptRoot -Parent
    $script:RunPesterPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'

    # Ensure the script exists
    if (-not (Test-Path $script:RunPesterPath)) {
        throw "Test runner script not found at: $script:RunPesterPath"
    }
}

Describe 'run-pester.ps1 Parameter Validation' {
    Context 'Suite Parameter' {
        It 'Accepts valid suite values' {
            # Test that the script accepts valid suite parameters without throwing
            $validSuites = @('All', 'Unit', 'Integration', 'Performance')

            foreach ($suite in $validSuites) {
                { & $script:RunPesterPath -Suite $suite -DryRun } | Should -Not -Throw
            }
        }

        It 'Rejects invalid suite values' {
            { & $script:RunPesterPath -Suite 'InvalidSuite' -DryRun } | Should -Throw
        }
    }

    Context 'OutputFormat Parameter' {
        It 'Accepts valid output format values' {
            $validFormats = @('Normal', 'Detailed', 'Minimal', 'None')

            foreach ($format in $validFormats) {
                { & $script:RunPesterPath -OutputFormat $format -DryRun } | Should -Not -Throw
            }
        }

        It 'Rejects invalid output format values' {
            { & $script:RunPesterPath -OutputFormat 'InvalidFormat' -DryRun } | Should -Throw
        }
    }

    Context 'Parallel Parameter' {
        It 'Accepts valid parallel values' {
            $validValues = @(1, 2, 4, 8, 16)

            foreach ($value in $validValues) {
                { & $script:RunPesterPath -Parallel $value -DryRun } | Should -Not -Throw
            }
        }

        It 'Rejects invalid parallel values' {
            $invalidValues = @(0, 17, -1, 'notanumber')

            foreach ($value in $invalidValues) {
                { & $script:RunPesterPath -Parallel $value -DryRun } | Should -Throw
            }
        }
    }

    Context 'Timeout Parameter' {
        It 'Accepts valid timeout values' {
            $validValues = @(1, 60, 300, 3600)

            foreach ($value in $validValues) {
                { & $script:RunPesterPath -Timeout $value -DryRun } | Should -Not -Throw
            }
        }

        It 'Rejects invalid timeout values' {
            $invalidValues = @(0, -1, 'notanumber')

            foreach ($value in $invalidValues) {
                { & $script:RunPesterPath -Timeout $value -DryRun } | Should -Throw
            }
        }
    }

    Context 'MinimumCoverage Parameter' {
        It 'Accepts valid coverage values' {
            $validValues = @(0, 50, 80, 100)

            foreach ($value in $validValues) {
                { & $script:RunPesterPath -Coverage -MinimumCoverage $value -DryRun } | Should -Not -Throw
            }
        }

        It 'Rejects invalid coverage values' {
            $invalidValues = @(-1, 101, 'notanumber')

            foreach ($value in $invalidValues) {
                { & $script:RunPesterPath -Coverage -MinimumCoverage $value -DryRun } | Should -Throw
            }
        }
    }
}

Describe 'run-pester.ps1 Dry Run Functionality' {
    It 'Executes successfully in dry run mode' {
        $result = & $script:RunPesterPath -DryRun

        $result | Should -Not -BeNullOrEmpty
        # Dry run should return a result object
    }

    It 'Shows help information' {
        $result = & $script:RunPesterPath -Help

        $result | Should -Not -BeNullOrEmpty
        # Help should contain usage information
    }

    It 'Performs health check' {
        $result = & $script:RunPesterPath -HealthCheck

        $result | Should -Not -BeNullOrEmpty
        # Health check should return environment status
    }
}

Describe 'run-pester.ps1 Module Integration' {
    It 'Loads all required modules successfully' {
        # This test verifies that the script can load its dependencies
        $result = & $script:RunPesterPath -DryRun -Suite Unit

        $result | Should -Not -BeNullOrEmpty
        # If modules failed to load, the script would throw an exception
    }

    It 'Configures Pester correctly' {
        # Test that various configuration options work together
        $result = & $script:RunPesterPath -DryRun -Suite Unit -Parallel 2 -Coverage -OutputFormat Minimal

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Test Discovery' {
    It 'Discovers unit tests correctly' {
        $result = & $script:RunPesterPath -DryRun -Suite Unit

        $result | Should -Not -BeNullOrEmpty
        # Should discover tests/unit directory
    }

    It 'Discovers integration tests correctly' {
        $result = & $script:RunPesterPath -DryRun -Suite Integration

        $result | Should -Not -BeNullOrEmpty
        # Should discover tests/integration directory
    }

    It 'Discovers specific test file' {
        $testFile = 'tests/unit/common.tests.ps1'
        if (Test-Path (Join-Path $script:TestRepoRoot $testFile)) {
            $result = & $script:RunPesterPath -DryRun -TestFile $testFile

            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'run-pester.ps1 Error Handling' {
    It 'Handles missing test directories gracefully' {
        # Test with a non-existent test file
        $result = & $script:RunPesterPath -DryRun -TestFile 'nonexistent.tests.ps1'

        $result | Should -Not -BeNullOrEmpty
        # Should handle the error gracefully
    }

    It 'Handles invalid test filters gracefully' {
        $result = & $script:RunPesterPath -DryRun -IncludeTag 'InvalidTag'

        $result | Should -Not -BeNullOrEmpty
        # Should handle empty test results gracefully
    }
}

Describe 'run-pester.ps1 Output Handling' {
    It 'Generates test results when requested' {
        $outputPath = Join-Path $TestDrive 'test-results.xml'

        $result = & $script:RunPesterPath -DryRun -OutputPath $outputPath

        $result | Should -Not -BeNullOrEmpty
        # In a real scenario, this would create the output file
    }

    It 'Generates coverage reports when requested' {
        $coveragePath = Join-Path $TestDrive 'coverage.xml'

        $result = & $script:RunPesterPath -DryRun -Coverage -CoverageReportPath $coveragePath

        $result | Should -Not -BeNullOrEmpty
        # In a real scenario, this would create the coverage file
    }
}

Describe 'run-pester.ps1 Performance Features' {
    It 'Handles performance baseline generation' {
        $baselinePath = Join-Path $TestDrive 'baseline.json'

        $result = & $script:RunPesterPath -DryRun -GenerateBaseline -BaselinePath $baselinePath

        $result | Should -Not -BeNullOrEmpty
        # In a real scenario, this would create the baseline file
    }

    It 'Handles baseline comparison' {
        # First create a baseline
        $baselinePath = Join-Path $TestDrive 'baseline.json'
        $result = & $script:RunPesterPath -DryRun -GenerateBaseline -BaselinePath $baselinePath

        # Then compare against it
        $result = & $script:RunPesterPath -DryRun -CompareBaseline -BaselinePath $baselinePath

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles performance tracking' {
        $result = & $script:RunPesterPath -DryRun -TrackPerformance

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Advanced Features' {
    It 'Handles retry logic configuration' {
        $result = & $script:RunPesterPath -DryRun -MaxRetries 3 -RetryOnFailure

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles test result analysis' {
        $result = & $script:RunPesterPath -DryRun -AnalyzeResults

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles custom reporting' {
        $reportPath = Join-Path $TestDrive 'test-report.html'

        $result = & $script:RunPesterPath -DryRun -AnalyzeResults -ReportFormat HTML -ReportPath $reportPath

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles strict mode' {
        $result = & $script:RunPesterPath -DryRun -StrictMode

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 CI Integration' {
    It 'Handles CI mode correctly' {
        $result = & $script:RunPesterPath -DryRun -CI

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles test result paths for CI' {
        $resultPath = Join-Path $TestDrive 'ci-results'

        $result = & $script:RunPesterPath -DryRun -CI -TestResultPath $resultPath

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Filtering and Selection' {
    It 'Handles test name filtering' {
        $result = & $script:RunPesterPath -DryRun -TestName '*Profile*'

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles tag filtering' {
        $result = & $script:RunPesterPath -DryRun -IncludeTag 'Unit'

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles category filtering' {
        $result = & $script:RunPesterPath -DryRun -OnlyCategories Unit, Integration

        $result | Should -Not -BeNullOrEmpty
    }
}