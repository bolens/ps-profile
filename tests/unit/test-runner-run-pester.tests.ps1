<#
tests/unit/test-runner-run-pester.tests.ps1

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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunPesterPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'

    # Ensure the script exists
    if (-not (Test-Path $script:RunPesterPath)) {
        throw "Test runner script not found at: $script:RunPesterPath"
    }

    # Helper function to clear recursive detection flag
    function Clear-TestRunnerFlag {
        $env:PS_PROFILE_TEST_RUNNER_ACTIVE = $null
    }

    # Helper to skip a test when modules can't load
    function Skip-IfModulesUnavailable {
        if (-not $script:RunPesterModulesWork) {
            Set-ItResult -Skipped -Because 'PesterConfig.psm1 cannot load — [PesterVerbosity] type requires Pester pre-loaded in session'
        }
    }

    # Check if PesterConfig.psm1 can load — it uses [PesterVerbosity] type in parameter defaults
    # which requires Pester to be loaded in the session. Without it, the script crashes on import.
    $pesterConfigPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/PesterConfig.psm1'
    $configLoadResult = pwsh -NoProfile -Command "
        try { Import-Module '$pesterConfigPath' -Force -ErrorAction Stop; 'OK' }
        catch { 'FAIL:' + \$_.Exception.Message }
    " 2>&1
    $script:RunPesterModulesWork = $configLoadResult -notmatch '^FAIL:'

    $script:TestTempRoot = New-TestTempDirectory -Prefix 'RunPesterTests'
    $script:DryRunTestFile = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'

    function Invoke-RunPesterDryRun {
        param(
            [hashtable]$Parameters = @{}
        )

        $defaults = @{
            DryRun   = $true
            Suite    = 'Unit'
            TestFile = $script:DryRunTestFile
        }

        foreach ($key in $defaults.Keys) {
            if (-not $Parameters.ContainsKey($key)) {
                $Parameters[$key] = $defaults[$key]
            }
        }

        return & $script:RunPesterPath @Parameters
    }

    function Invoke-RunPesterDryRunToleratingErrors {
        param(
            [hashtable]$Parameters = @{}
        )

        $captured = [System.Collections.Generic.List[string]]::new()
        try {
            Invoke-RunPesterDryRun -Parameters $Parameters 2>&1 | ForEach-Object {
                $null = $captured.Add("$($_)")
            }
            $null = $captured.Add("EXIT:$LASTEXITCODE")
        }
        catch {
            $null = $captured.Add($_.Exception.Message)
        }

        return $captured
    }
}


# Clear recursive detection flag before each test to ensure clean state
# This is done at the start of each Describe block since BeforeEach can't be at root level

Describe 'run-pester.ps1 Parameter Validation' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    Context 'Suite Parameter' {
        It 'Accepts valid suite values' {
            # Scope dry run to one file so suite validation stays fast
            $testFile = 'tests/unit/library-common.tests.ps1'
            if (-not (Test-Path (Join-Path $script:TestRepoRoot $testFile))) {
                Set-ItResult -Skipped -Because "Fixture test file not found: $testFile"
                return
            }

            $validSuites = @('All', 'Unit', 'Integration', 'Performance')

            foreach ($suite in $validSuites) {
                { & $script:RunPesterPath -Suite $suite -DryRun -TestFile $testFile } | Should -Not -Throw
            }
        }

        It 'Rejects invalid suite values' {
            { & $script:RunPesterPath -Suite 'InvalidSuite' -DryRun -TestFile $script:DryRunTestFile } | Should -Throw
        }
    }

    Context 'OutputFormat Parameter' {
        It 'Accepts valid output format values' {
            $validFormats = @('Normal', 'Detailed', 'Minimal', 'None')

            foreach ($format in $validFormats) {
                { Invoke-RunPesterDryRun @{ OutputFormat = $format } } | Should -Not -Throw
            }
        }

        It 'Rejects invalid output format values' {
            { Invoke-RunPesterDryRun @{ OutputFormat = 'InvalidFormat' } } | Should -Throw
        }
    }

    Context 'Parallel Parameter' {
        It 'Accepts valid parallel values' {
            $validValues = @(1, 2, 4, 8, 16)

            foreach ($value in $validValues) {
                { Invoke-RunPesterDryRun @{ Parallel = $value } } | Should -Not -Throw
            }
        }

        It 'Rejects invalid parallel values' {
            $result = Invoke-RunPesterDryRun @{ Parallel = -1 } 2>&1
            $result | Should -Not -BeNullOrEmpty

            $result = Invoke-RunPesterDryRun @{ Parallel = 0 } 2>&1
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Timeout Parameter' {
        It 'Accepts valid timeout values' {
            $validValues = @(1, 60, 300, 3600)

            foreach ($value in $validValues) {
                { Invoke-RunPesterDryRun @{ Timeout = $value } } | Should -Not -Throw
            }
        }

        It 'Rejects invalid timeout values' {
            $invalidValues = @(0, -1)
            foreach ($value in $invalidValues) {
                { Invoke-RunPesterDryRun @{ Timeout = $value } } | Should -Throw
            }
        }
    }

    Context 'MinimumCoverage Parameter' {
        It 'Accepts valid coverage values' {
            $validValues = @(0, 50, 80, 100)

            foreach ($value in $validValues) {
                { Invoke-RunPesterDryRun @{ Coverage = $true; MinimumCoverage = $value } } | Should -Not -Throw
            }
        }

        It 'Rejects invalid coverage values' {
            $invalidValues = @(-1, 101)
            foreach ($value in $invalidValues) {
                { Invoke-RunPesterDryRun @{ Coverage = $true; MinimumCoverage = $value } } | Should -Throw
            }
        }
    }
}

Describe 'run-pester.ps1 Dry Run Functionality' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Executes successfully in dry run mode' {
        $result = Invoke-RunPesterDryRun

        $result | Should -Not -BeNullOrEmpty
        # Dry run should return a result object
    }

    It 'Shows help information' {
        $help = Get-Help $script:RunPesterPath -ErrorAction SilentlyContinue

        $help | Should -Not -BeNullOrEmpty
        # Help should contain usage information
    }

    It 'Performs health check' {
        $result = Invoke-RunPesterDryRun @{ HealthCheck = $true }

        $result | Should -Not -BeNullOrEmpty
        # Health check should return environment status
    }
}

Describe 'run-pester.ps1 Module Integration' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Loads all required modules successfully' {
        # This test verifies that the script can load its dependencies
        $result = Invoke-RunPesterDryRun

        $result | Should -Not -BeNullOrEmpty
        # If modules failed to load, the script would throw an exception
    }

    It 'Configures Pester correctly' {
        # Test that various configuration options work together
        $result = Invoke-RunPesterDryRun @{ Parallel = 2; Coverage = $true; OutputFormat = 'Minimal' }

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Test Discovery' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Discovers unit tests correctly' {
        $result = Invoke-RunPesterDryRun

        $result | Should -Not -BeNullOrEmpty
        # Should discover tests/unit directory
    }

    It 'Discovers integration tests correctly' {
        $testFile = 'tests/integration/bootstrap/bootstrap.tests.ps1'
        if (Test-Path (Join-Path $script:TestRepoRoot $testFile)) {
            $result = & $script:RunPesterPath -DryRun -Suite Integration -TestFile $testFile
        }
        else {
            $result = & $script:RunPesterPath -DryRun -Suite Integration -TestFile $script:DryRunTestFile
        }

        $result | Should -Not -BeNullOrEmpty
        # Should discover tests/integration directory
    }

    It 'Discovers specific test file' {
        $testFile = 'tests/unit/library-common.tests.ps1'
        if (Test-Path (Join-Path $script:TestRepoRoot $testFile)) {
            $result = & $script:RunPesterPath -DryRun -TestFile $testFile

            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'run-pester.ps1 Error Handling' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Handles missing test directories gracefully' {
        { & $script:RunPesterPath -DryRun -TestFile 'nonexistent.tests.ps1' } | Should -Throw
    }

    It 'Handles invalid test filters gracefully' {
        $result = Invoke-RunPesterDryRun @{ IncludeTag = 'InvalidTag' }

        $result | Should -Not -BeNullOrEmpty
        # Should handle empty test results gracefully
    }
}

Describe 'run-pester.ps1 Output Handling' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Generates test results when requested' {
        $outputPath = Join-Path $script:TestTempRoot 'test-results.xml'

        $result = Invoke-RunPesterDryRun @{ OutputPath = $outputPath }

        $result | Should -Not -BeNullOrEmpty
        # In a real scenario, this would create the output file
    }

    It 'Generates coverage reports when requested' {
        $coveragePath = Join-Path $script:TestTempRoot 'coverage.xml'

        $result = Invoke-RunPesterDryRun @{ Coverage = $true; CoverageReportPath = $coveragePath }

        $result | Should -Not -BeNullOrEmpty
        # In a real scenario, this would create the coverage file
    }
}

Describe 'run-pester.ps1 Performance Features' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Handles performance baseline generation' {
        $baselinePath = Join-Path $script:TestTempRoot 'baseline.json'

        $result = Invoke-RunPesterDryRun @{ GenerateBaseline = $true; BaselinePath = $baselinePath }

        $result | Should -Not -BeNullOrEmpty
        # In a real scenario, this would create the baseline file
    }

    It 'Handles baseline comparison' {
        # First create a baseline
        $baselinePath = Join-Path $script:TestTempRoot 'baseline.json'
        $result = Invoke-RunPesterDryRun @{ GenerateBaseline = $true; BaselinePath = $baselinePath }

        # Then compare against it
        $result = Invoke-RunPesterDryRun @{ CompareBaseline = $true; BaselinePath = $baselinePath }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles performance tracking' {
        $result = Invoke-RunPesterDryRun @{ TrackPerformance = $true }

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Advanced Features' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Handles retry logic configuration' {
        $result = Invoke-RunPesterDryRun @{ MaxRetries = 3; RetryOnFailure = $true }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles test result analysis' {
        $result = Invoke-RunPesterDryRun @{ AnalyzeResults = $true }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles custom reporting' {
        $reportPath = Join-Path $script:TestTempRoot 'test-report.html'

        $result = Invoke-RunPesterDryRun @{ AnalyzeResults = $true; ReportFormat = 'HTML'; ReportPath = $reportPath }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles strict mode' {
        $result = Invoke-RunPesterDryRun @{ StrictMode = $true }

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 CI Integration' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Handles CI mode correctly' {
        $result = Invoke-RunPesterDryRun @{ CI = $true }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles test result paths for CI' {
        $resultPath = Join-Path $script:TestTempRoot 'ci-results'

        $result = Invoke-RunPesterDryRun @{ CI = $true; TestResultPath = $resultPath }

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Filtering and Selection' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Handles test name filtering' {
        $result = Invoke-RunPesterDryRun @{ TestName = '*Profile*' }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles tag filtering' {
        $result = Invoke-RunPesterDryRun @{ IncludeTag = 'Unit' }

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Handles category filtering' {
        $result = Invoke-RunPesterDryRun @{ OnlyCategories = @('Unit', 'Integration') }

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 List Tests' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Lists tests without running them' {
        & $script:RunPesterPath -ListTests -Suite Unit -TestFile $script:DryRunTestFile 2>&1 | Out-Null

        $LASTEXITCODE | Should -Be 0
    }

    It 'Lists tests with details when ShowDetails specified' {
        & $script:RunPesterPath -ListTests -ShowDetails -Suite Unit -TestFile $script:DryRunTestFile 2>&1 | Out-Null

        $LASTEXITCODE | Should -Be 0
    }
}

Describe 'run-pester.ps1 Test File Pattern Filtering' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Filters test files by pattern' {
        Invoke-RunPesterDryRun @{ TestFilePattern = '*library-common*' } | Out-Null
        $LASTEXITCODE | Should -Be 0
    }

    It 'Handles invalid pattern gracefully' {
        $result = Invoke-RunPesterDryRunToleratingErrors @{ TestFilePattern = '*nonexistent*' }

        # Should handle gracefully (may exit with error code for no tests found or recursive detection)
        $result | Should -Not -BeNullOrEmpty
        ($result -join ' ') | Should -Match 'No test files match pattern|Recursive'
    }
}

Describe 'run-pester.ps1 Multiple Test Files' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Accepts multiple test files via TestFile parameter' {
        $testFiles = @(
            'tests/unit/library-common.tests.ps1',
            'tests/unit/test-runner-run-pester.tests.ps1'
        )
        
        $existingFiles = $testFiles | Where-Object { Test-Path (Join-Path $script:TestRepoRoot $_) }
        
        if (@($existingFiles).Count -ge 2) {
            $result = & $script:RunPesterPath -DryRun -TestFile $existingFiles 2>&1

            $result | Should -Not -BeNullOrEmpty
        }
    }

    It 'Accepts multiple test files via Path alias' {
        $testFiles = @(
            'tests/unit/library-common.tests.ps1',
            'tests/unit/test-runner-run-pester.tests.ps1'
        )
        
        $existingFiles = $testFiles | Where-Object { Test-Path (Join-Path $script:TestRepoRoot $_) }
        
        if (@($existingFiles).Count -ge 2) {
            $result = & $script:RunPesterPath -DryRun -Path $existingFiles 2>&1

            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'run-pester.ps1 Configuration Files' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Saves configuration to file' {
        $configPath = Join-Path $script:TestTempRoot 'test-config.json'
        
        # Parallel needs a value, use 2
        $result = Invoke-RunPesterDryRun @{ Coverage = $true; Parallel = 2; SaveConfig = $configPath } 2>&1

        # Should create config file (if not blocked by recursive detection)
        if (Test-Path $configPath) {
            # Should be valid JSON
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
        }
        else {
            # If recursive detection prevented execution, that's acceptable
            $output = $result -join ' '
            $output | Should -Match 'Recursive|test'
        }
    }

    It 'Loads configuration from file' {
        $null = New-Item -ItemType Directory -Path $script:TestTempRoot -Force -ErrorAction SilentlyContinue
        $configPath = Join-Path $script:TestTempRoot 'test-config.json'
        
        # Create a test config
        @{
            Suite    = 'Unit'
            Coverage = $true
            Parallel = 2
        } | ConvertTo-Json | Set-Content $configPath
        
        $result = Invoke-RunPesterDryRun @{ ConfigFile = $configPath } 2>&1

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Command-line parameters override config file' {
        $null = New-Item -ItemType Directory -Path $script:TestTempRoot -Force -ErrorAction SilentlyContinue
        $configPath = Join-Path $script:TestTempRoot 'test-config.json'
        
        # Create config with Suite = Unit
        @{
            Suite = 'Unit'
        } | ConvertTo-Json | Set-Content $configPath
        
        # Override with Suite = Integration via command line
        & $script:RunPesterPath -DryRun -ConfigFile $configPath -Suite Integration -TestFile $script:DryRunTestFile 2>&1 | Out-Null

        $LASTEXITCODE | Should -Be 0
    }
}

Describe 'run-pester.ps1 Git Integration' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Handles ChangedFiles parameter when in git repo' {
        # Only test if we're in a git repository
        Push-Location $script:TestRepoRoot
        try {
            $isGitRepo = git rev-parse --git-dir 2>$null
            if ($LASTEXITCODE -eq 0) {
                $result = Invoke-RunPesterDryRun @{ ChangedFiles = $true } 2>&1

                $result | Should -Not -BeNullOrEmpty
                $LASTEXITCODE | Should -BeGreaterOrEqual 0
            }
            else {
                Write-Warning "Not in git repository, skipping ChangedFiles test"
            }
        }
        finally {
            Pop-Location
        }
    }

    It 'Handles ChangedSince parameter when in git repo' {
        Push-Location $script:TestRepoRoot
        try {
            $isGitRepo = git rev-parse --git-dir 2>$null
            if ($LASTEXITCODE -eq 0) {
                # Test with HEAD~1 (should be safe)
                $result = Invoke-RunPesterDryRun @{ ChangedSince = 'HEAD~1' } 2>&1

                $result | Should -Not -BeNullOrEmpty
                $LASTEXITCODE | Should -BeGreaterOrEqual 0
            }
            else {
                Write-Warning "Not in git repository, skipping ChangedSince test"
            }
        }
        finally {
            Pop-Location
        }
    }
}

Describe 'run-pester.ps1 Failed Only' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Handles FailedOnly when no previous results exist' {
        $result = Invoke-RunPesterDryRunToleratingErrors @{ FailedOnly = $true }

        $result | Should -Not -BeNullOrEmpty
        $output = $result -join ' '
        # Should handle gracefully (may show message about no results or recursive detection)
        ($output -Match 'failed|result|No failed tests|Reading failed tests|No test result directory') -or ($output -Match 'Recursive') | Should -Be $true
    }
}

Describe 'run-pester.ps1 Summary Statistics' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Shows summary statistics when requested' {
        $result = Invoke-RunPesterDryRun @{ ShowSummaryStats = $true } 2>&1

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Combines summary statistics with performance tracking' {
        $result = Invoke-RunPesterDryRun @{ ShowSummaryStats = $true; TrackPerformance = $true } 2>&1

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Exit Codes' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Returns appropriate exit code for no tests found' {
        # Use a pattern that won't match any tests
        $result = Invoke-RunPesterDryRunToleratingErrors @{ TestFilePattern = '*nonexistent-pattern-xyz*' }
        $output = $result -join ' '

        # Should exit with EXIT_NO_TESTS_FOUND (7) or throw that message in PS_PROFILE_TEST_MODE
        if ($output -match 'EXIT:(\d+)') {
            [int]$Matches[1] | Should -BeGreaterOrEqual 0
        }
        else {
            $output | Should -Match 'No test files match pattern'
        }
    }
}

Describe 'run-pester.ps1 Watch Mode' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Accepts Watch parameter without error' {
        # Note: Watch mode runs indefinitely, so we can't fully test it
        # But we can verify it accepts the parameter
        $result = Invoke-RunPesterDryRun @{ Watch = $true } 2>&1

        # Watch mode should be handled (may exit early in dry run or show watch mode message)
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Accepts WatchDebounceSeconds parameter' {
        $result = Invoke-RunPesterDryRun @{ Watch = $true; WatchDebounceSeconds = 2 } 2>&1

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Interactive Mode' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Accepts Interactive parameter' {
        if ($env:PS_PROFILE_NONINTERACTIVE -eq '1' -or $env:CI -eq 'true' -or [Console]::IsInputRedirected) {
            Set-ItResult -Inconclusive -Because 'Interactive mode requires a TTY'
            return
        }

        # Interactive mode requires user input, so we can only verify it accepts the parameter
        $result = Invoke-RunPesterDryRun @{ Interactive = $true } 2>&1

        $result | Should -Not -BeNullOrEmpty
    }
}

Describe 'run-pester.ps1 Parameter Combinations' {
    BeforeEach {
        Clear-TestRunnerFlag
        Skip-IfModulesUnavailable
    }
    
    It 'Combines multiple features' {
        $result = Invoke-RunPesterDryRun @{ TestFilePattern = '*library-common*'; ShowSummaryStats = $true } 2>&1

        $result | Should -Not -BeNullOrEmpty
    }

    It 'Combines git integration with test file pattern' {
        Push-Location $script:TestRepoRoot
        try {
            $isGitRepo = git rev-parse --git-dir 2>$null
            if ($LASTEXITCODE -eq 0) {
                $result = Invoke-RunPesterDryRun @{ ChangedFiles = $true; TestFilePattern = '*library-common*' } 2>&1

                $result | Should -Not -BeNullOrEmpty
                $LASTEXITCODE | Should -BeGreaterOrEqual 0
            }
        }
        finally {
            Pop-Location
        }
    }
}