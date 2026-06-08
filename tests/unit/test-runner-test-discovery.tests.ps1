<#
tests/unit/TestDiscovery.tests.ps1

.SYNOPSIS
    Tests for the TestDiscovery module.
#>

BeforeAll {
    # Import test support
    . $PSScriptRoot/../TestSupport.ps1

    # Import the modules to test
    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    $libPath = Join-Path $PSScriptRoot '../../scripts/lib'
    Import-Module (Join-Path $modulePath 'PesterConfig.psm1') -Force
    # Import TestDiscovery submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'TestPathResolution.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'TestPathUtilities.psm1') -Force -Global
    # Import dependencies - must be Global so TestPathUtilities can access them
    Import-Module (Join-Path $libPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $libPath 'core' 'Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $libPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force -Global
    # Import TestExecution submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'TestRetry.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestEnvironment.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestPerformanceMonitoring.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestTimeoutHandling.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestRecovery.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestSummaryGeneration.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestReporting.psm1') -Force
    # Import OutputUtils submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputSanitizer.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputInterceptor.psm1') -Force -Global
    # Remove duplicate Logging import - already imported above

    # Set up test repository root (two levels up from tests/unit)
    $script:TestRepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:TestTempRoot = New-TestTempDirectory -Prefix 'TestDiscovery'
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot

    function script:Assert-TestPathsUnderDirectory {
        param(
            [string[]]$Paths,
            [string]$Directory
        )

        $normalizedDirectory = (Resolve-Path -LiteralPath $Directory).Path
        @($Paths | Where-Object {
                $_ -and $_.StartsWith($normalizedDirectory, [System.StringComparison]::Ordinal)
            }).Count | Should -BeGreaterThan 0
    }
}

Describe 'TestDiscovery Module Tests' {
    Context 'Get-TestPaths' {
        It 'Returns unit test paths for Unit suite' {
            $paths = Get-TestPaths -Suite 'Unit' -RepoRoot $script:TestRepoRoot

            $expectedPath = Join-Path $script:TestRepoRoot 'tests/unit'
            Assert-TestPathsUnderDirectory -Paths $paths -Directory $expectedPath
        }

        It 'Returns integration test paths for Integration suite' {
            $paths = Get-TestPaths -Suite 'Integration' -RepoRoot $script:TestRepoRoot

            $expectedPath = Join-Path $script:TestRepoRoot 'tests/integration'
            Assert-TestPathsUnderDirectory -Paths $paths -Directory $expectedPath
        }

        It 'Returns all test paths for All suite' {
            $paths = Get-TestPaths -Suite 'All' -RepoRoot $script:TestRepoRoot

            $expectedUnitPath = Join-Path $script:TestRepoRoot 'tests/unit'
            $expectedIntegrationPath = Join-Path $script:TestRepoRoot 'tests/integration'
            $expectedPerformancePath = Join-Path $script:TestRepoRoot 'tests/performance'
            Assert-TestPathsUnderDirectory -Paths $paths -Directory $expectedUnitPath
            Assert-TestPathsUnderDirectory -Paths $paths -Directory $expectedIntegrationPath
            Assert-TestPathsUnderDirectory -Paths $paths -Directory $expectedPerformancePath
        }

        It 'Returns specific test file when TestFile is provided' {
            $testFile = 'tests/unit/library-common.tests.ps1'
            $fullTestFile = Join-Path $script:TestRepoRoot $testFile
            $paths = Get-TestPaths -Suite 'Unit' -TestFile $testFile -RepoRoot $script:TestRepoRoot

            $paths | Should -Contain $fullTestFile
        }
    }

    Context 'Get-TestSuitePaths' {
        It 'Returns correct paths for each suite' {
            $unitPaths = Get-TestSuitePaths -Suite 'Unit' -RepoRoot $script:TestRepoRoot
            $expectedUnitPath = Join-Path $script:TestRepoRoot 'tests/unit'
            Assert-TestPathsUnderDirectory -Paths $unitPaths -Directory $expectedUnitPath

            $integrationPaths = Get-TestSuitePaths -Suite 'Integration' -RepoRoot $script:TestRepoRoot
            $expectedIntegrationPath = Join-Path $script:TestRepoRoot 'tests/integration'
            Assert-TestPathsUnderDirectory -Paths $integrationPaths -Directory $expectedIntegrationPath

            $performancePaths = Get-TestSuitePaths -Suite 'Performance' -RepoRoot $script:TestRepoRoot
            $expectedPerformancePath = Join-Path $script:TestRepoRoot 'tests/performance'
            Assert-TestPathsUnderDirectory -Paths $performancePaths -Directory $expectedPerformancePath
        }

        It 'Filters to existing test files' {
            $paths = Get-TestSuitePaths -Suite 'Unit' -RepoRoot $script:TestRepoRoot

            foreach ($path in $paths) {
                if ($null -ne $path -and -not [string]::IsNullOrWhiteSpace($path)) {
                    Test-Path -LiteralPath $path -PathType Leaf | Should -Be $true -Because "Path should exist: $path"
                }
            }
        }
    }

    Context 'Get-SpecificTestPaths' {
        It 'Returns directory contents for directory input' {
            $testDir = 'tests/unit'
            $paths = Get-SpecificTestPaths -TestFile $testDir -Suite 'Unit' -RepoRoot $script:TestRepoRoot

            $paths | Should -Not -BeNullOrEmpty
            $paths | ForEach-Object { 
                $_ | Should -Match '\.tests\.ps1$'
                if ($null -ne $_ -and -not [string]::IsNullOrWhiteSpace($_)) {
                    Test-Path -LiteralPath $_ | Should -Be $true -Because "Test file should exist: $_"
                }
            }
        }

        It 'Returns file path for file input' {
            $testFile = 'tests/unit/library-common.tests.ps1'
            $fullTestFile = Join-Path $script:TestRepoRoot $testFile
            $paths = Get-SpecificTestPaths -TestFile $testFile -Suite 'Unit' -RepoRoot $script:TestRepoRoot

            $paths | Should -Contain $fullTestFile
        }
    }

    Context 'Get-TestFilesFromDirectory' {
        It 'Finds test files recursively' {
            $testFiles = Get-TestFilesFromDirectory -Directory (Join-Path $script:TestRepoRoot 'tests/unit')

            $testFiles | Should -Not -BeNullOrEmpty
            $testFiles | ForEach-Object { 
                $_ | Should -Match '\.tests\.ps1$'
                Test-Path $_ | Should -Be $true
            }
        }

        It 'Returns directory if no test files found' {
            # Create a temporary directory without test files
            $tempDir = Join-Path $script:TestTempRoot 'empty-test-dir'
            New-Item -ItemType Directory -Path $tempDir -Force

            $result = Get-TestFilesFromDirectory -Directory $tempDir

            $result | Should -Contain $tempDir
        }
    }

    Context 'Test-TestPaths' {
        It 'Validates existing paths' {
            $validPaths = @(
                (Join-Path $script:TestRepoRoot 'tests/unit'),
                (Join-Path $script:TestRepoRoot 'tests/integration')
            )
            $result = Test-TestPaths -TestPaths $validPaths -Suite 'All' -RepoRoot $script:TestRepoRoot

            $result | Should -Contain (Join-Path $script:TestRepoRoot 'tests/unit')
            $result | Should -Contain (Join-Path $script:TestRepoRoot 'tests/integration')
        }

        It 'Filters out invalid paths' {
            $mixedPaths = @(
                (Join-Path $script:TestRepoRoot 'tests/unit'),
                'nonexistent/path'
            )
            $result = Test-TestPaths -TestPaths $mixedPaths -Suite 'All' -RepoRoot $script:TestRepoRoot -WarningAction SilentlyContinue

            $result | Should -Contain (Join-Path $script:TestRepoRoot 'tests/unit')
            $result | Should -Not -Contain 'nonexistent/path'
        }

        It 'Returns tests directory as fallback' {
            $invalidPaths = @('nonexistent/path1', 'nonexistent/path2')
            $result = Test-TestPaths -TestPaths $invalidPaths -Suite 'All' -RepoRoot $script:TestRepoRoot -WarningAction SilentlyContinue

            # Test-TestPaths returns absolute path as fallback
            $expectedFallback = Join-Path $script:TestRepoRoot 'tests'
            $result | Should -Contain $expectedFallback
        }
    }

    Context 'Get-ShuffledTestPaths' {
        It 'Returns a single path unchanged' {
            $path = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'
            $result = Get-ShuffledTestPaths -TestPaths @($path)

            $result | Should -Be @($path)
        }

        It 'Returns all paths without duplicates' {
            $paths = @(
                (Join-Path $script:TestRepoRoot 'tests/unit/a.tests.ps1'),
                (Join-Path $script:TestRepoRoot 'tests/unit/b.tests.ps1'),
                (Join-Path $script:TestRepoRoot 'tests/unit/c.tests.ps1')
            )

            $result = Get-ShuffledTestPaths -TestPaths $paths

            $result.Count | Should -Be 3
            @($result | Sort-Object) | Should -Be @($paths | Sort-Object)
        }

        It 'Can produce a different order across multiple shuffles' {
            $paths = 1..8 | ForEach-Object { Join-Path $script:TestRepoRoot "tests/unit/file-$_.tests.ps1" }
            $orders = [System.Collections.Generic.HashSet[string]]::new()

            1..20 | ForEach-Object {
                $shuffled = Get-ShuffledTestPaths -TestPaths $paths
                $null = $orders.Add(($shuffled -join '|'))
            }

            $orders.Count | Should -BeGreaterThan 1
        }
    }

    Context 'Filter-TestPaths' {
        It 'Expands directories and excludes test-runner test files' {
            $unitDir = Join-Path $script:TestRepoRoot 'tests/unit'
            $result = Filter-TestPaths -TestPaths @($unitDir) -TestRunnerScriptPath $null

            $result.Count | Should -BeGreaterThan 0
            ($result | ForEach-Object { Split-Path -Leaf $_ }) | Should -Not -Contain 'test-runner-run-pester.tests.ps1'
        }

        It 'Allows explicit test-runner file when it is the only path' {
            $runnerTest = Join-Path $script:TestRepoRoot 'tests/unit/test-runner-run-pester.tests.ps1'
            if (-not (Test-Path -LiteralPath $runnerTest)) {
                Set-ItResult -Skipped -Because 'test-runner-run-pester.tests.ps1 not found'
                return
            }

            $result = Filter-TestPaths -TestPaths @($runnerTest) -TestRunnerScriptPath $null
            $result | Should -Contain $runnerTest
        }

        It 'Excludes the test runner script path itself' {
            $unitDir = Join-Path $script:TestRepoRoot 'tests/unit'
            $runnerScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'
            $result = Filter-TestPaths -TestPaths @($unitDir, $runnerScript) -TestRunnerScriptPath $runnerScript

            $result | Should -Not -Contain $runnerScript
        }

        It 'Skips paths that do not exist' {
            $validFile = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'
            $result = Filter-TestPaths -TestPaths @('nonexistent-path-xyz', $validFile) -TestRunnerScriptPath $null

            $result | Should -Contain $validFile
            $result | Should -Not -Contain 'nonexistent-path-xyz'
        }
    }

    Context 'Write-TestDiscoveryInfo' {
        It 'Emits suite discovery output when no TestFile override is provided' {
            $paths = @(
                (Join-Path $script:TestRepoRoot 'tests/unit'),
                (Join-Path $script:TestRepoRoot 'tests/integration')
            )
            $output = Write-TestDiscoveryInfo -TestPaths $paths -Suite 'All' -TestFile ''
            @($output | ForEach-Object { "$_" }) -join ' ' | Should -Match 'all suites'
        }

        It 'Emits a warning when TestFile overrides suite selection' {
            $testFile = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'
            if (-not (Test-Path -LiteralPath $testFile)) {
                Set-ItResult -Skipped -Because 'library-common.tests.ps1 not found'
                return
            }

            $output = Write-TestDiscoveryInfo -TestPaths @($testFile) -Suite 'Unit' -TestFile $testFile *>&1 |
                ForEach-Object { "$_" }

            ($output -join ' ') | Should -Match 'overriding Suite'
        }
    }
}
