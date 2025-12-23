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
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
}

Describe 'TestDiscovery Module Tests' {
    Context 'Get-TestPaths' {
        It 'Returns unit test paths for Unit suite' {
            $paths = Get-TestPaths -Suite 'Unit' -RepoRoot $script:TestRepoRoot

            $expectedPath = Join-Path $script:TestRepoRoot 'tests/unit'
            $paths | Should -Contain $expectedPath
        }

        It 'Returns integration test paths for Integration suite' {
            $paths = Get-TestPaths -Suite 'Integration' -RepoRoot $script:TestRepoRoot

            $expectedPath = Join-Path $script:TestRepoRoot 'tests/integration'
            $paths | Should -Contain $expectedPath
        }

        It 'Returns all test paths for All suite' {
            $paths = Get-TestPaths -Suite 'All' -RepoRoot $script:TestRepoRoot

            $expectedUnitPath = Join-Path $script:TestRepoRoot 'tests/unit'
            $expectedIntegrationPath = Join-Path $script:TestRepoRoot 'tests/integration'
            $expectedPerformancePath = Join-Path $script:TestRepoRoot 'tests/performance'
            $paths | Should -Contain $expectedUnitPath
            $paths | Should -Contain $expectedIntegrationPath
            $paths | Should -Contain $expectedPerformancePath
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
            $unitPaths | Should -Contain $expectedUnitPath

            $integrationPaths = Get-TestSuitePaths -Suite 'Integration' -RepoRoot $script:TestRepoRoot
            $expectedIntegrationPath = Join-Path $script:TestRepoRoot 'tests/integration'
            $integrationPaths | Should -Contain $expectedIntegrationPath

            $performancePaths = Get-TestSuitePaths -Suite 'Performance' -RepoRoot $script:TestRepoRoot
            $expectedPerformancePath = Join-Path $script:TestRepoRoot 'tests/performance'
            $performancePaths | Should -Contain $expectedPerformancePath
        }

        It 'Filters to existing directories' {
            $paths = Get-TestSuitePaths -Suite 'Unit' -RepoRoot $script:TestRepoRoot

            foreach ($path in $paths) {
                if ($null -ne $path -and -not [string]::IsNullOrWhiteSpace($path)) {
                    Test-Path -LiteralPath $path | Should -Be $true -Because "Path should exist: $path"
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
            $tempDir = Join-Path $TestDrive 'empty-test-dir'
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
}
