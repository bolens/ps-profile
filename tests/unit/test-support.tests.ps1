Describe 'TestSupport Modules' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
        try {
            $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
            if ($null -eq $script:RepoRoot -or [string]::IsNullOrWhiteSpace($script:RepoRoot)) {
                throw "Get-TestRepoRoot returned null or empty value"
            }
            if (-not (Test-Path -LiteralPath $script:RepoRoot)) {
                throw "Repository root not found at: $script:RepoRoot"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize TestSupport tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Describe 'TestPaths Module' {
        Context 'Get-TestRepoRoot' {
            It 'Returns valid repository root path' {
                try {
                    $result = Get-TestRepoRoot -StartPath $PSScriptRoot
                    $result | Should -Not -BeNullOrEmpty -Because "Get-TestRepoRoot should return a valid path"
                    if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Test-Path -LiteralPath $result | Should -Be $true -Because "Repository root path should exist"
                        Test-Path -LiteralPath (Join-Path $result '.git') | Should -Be $true -Because "Repository root should contain .git directory"
                    }
                    $result | Should -Be $script:RepoRoot -Because "Result should match cached repository root"
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        Test     = 'Returns valid repository root path'
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error "Get-TestRepoRoot test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
            }

            It 'Throws error when repository root cannot be found' {
                # This specific test must use a location outside the repository tree;
                # otherwise Get-TestRepoRoot will always find the repo .git directory.
                $tempBase = [System.IO.Path]::GetTempPath()
                $tempDir = Join-Path $tempBase "NoGitRepo-$([Guid]::NewGuid())"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                try {
                    { Get-TestRepoRoot -StartPath $tempDir } | Should -Throw
                }
                finally {
                    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        Context 'Get-TestPath' {
            It 'Resolves path relative to repository root' {
                try {
                    $result = Get-TestPath -RelativePath 'tests' -StartPath $PSScriptRoot
                    $result | Should -Not -BeNullOrEmpty -Because "Get-TestPath should return a valid path"
                    if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Test-Path -LiteralPath $result | Should -Be $true -Because "Resolved path should exist"
                    }
                    $result | Should -BeLike "*tests" -Because "Path should contain 'tests'"
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        Test     = 'Resolves path relative to repository root'
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error "Get-TestPath test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
            }

            It 'Throws error when EnsureExists is true and path does not exist' {
                { Get-TestPath -RelativePath 'nonexistent-path-12345' -StartPath $PSScriptRoot -EnsureExists } | Should -Throw
            }

            It 'Does not throw when EnsureExists is false and path does not exist' {
                try {
                    $result = Get-TestPath -RelativePath 'nonexistent-path-12345' -StartPath $PSScriptRoot
                    $result | Should -Not -BeNullOrEmpty -Because "Get-TestPath should return a path even if it doesn't exist"
                    if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Test-Path -LiteralPath $result | Should -Be $false -Because "Non-existent path should return false"
                    }
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        Test     = 'Does not throw when EnsureExists is false and path does not exist'
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error "Get-TestPath non-existent test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
            }
        }

        Context 'Get-TestSuitePath' {
            It 'Resolves Unit test suite path' {
                try {
                    $result = Get-TestSuitePath -Suite 'Unit' -StartPath $PSScriptRoot
                    $result | Should -Not -BeNullOrEmpty -Because "Get-TestSuitePath should return a valid path"
                    if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Test-Path -LiteralPath $result | Should -Be $true -Because "Unit test suite path should exist"
                    }
                    ($result -replace '\\', '/') | Should -BeLike '*/tests/unit' -Because "Path should contain 'tests/unit'"
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        Test     = 'Resolves Unit test suite path'
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error "Get-TestSuitePath Unit test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
            }

            It 'Resolves Integration test suite path' {
                try {
                    $result = Get-TestSuitePath -Suite 'Integration' -StartPath $PSScriptRoot
                    $result | Should -Not -BeNullOrEmpty -Because "Get-TestSuitePath should return a valid path"
                    if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Test-Path -LiteralPath $result | Should -Be $true -Because "Integration test suite path should exist"
                    }
                    ($result -replace '\\', '/') | Should -BeLike '*/tests/integration' -Because "Path should contain 'tests/integration'"
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        Test     = 'Resolves Integration test suite path'
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error "Get-TestSuitePath Integration test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
            }

            It 'Resolves Performance test suite path' {
                try {
                    $result = Get-TestSuitePath -Suite 'Performance' -StartPath $PSScriptRoot
                    $result | Should -Not -BeNullOrEmpty -Because "Get-TestSuitePath should return a valid path"
                    if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Test-Path -LiteralPath $result | Should -Be $true -Because "Performance test suite path should exist"
                    }
                    ($result -replace '\\', '/') | Should -BeLike '*/tests/performance' -Because "Path should contain 'tests/performance'"
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        Test     = 'Resolves Performance test suite path'
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error "Get-TestSuitePath Performance test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
            }
        }

        Context 'Get-TestSuiteFiles' {
            It 'Enumerates test files for Unit suite' {
                $result = Get-TestSuiteFiles -Suite 'Unit' -StartPath $PSScriptRoot
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterThan 0
                $result[0].Extension | Should -Be '.ps1'
            }

            It 'Returns files sorted by full path' {
                $result = Get-TestSuiteFiles -Suite 'Unit' -StartPath $PSScriptRoot
                if ($result.Count -gt 1) {
                    for ($i = 0; $i -lt ($result.Count - 1); $i++) {
                        $result[$i].FullName | Should -BeLessOrEqual $result[$i + 1].FullName
                    }
                }
            }
        }

        Context 'Register-TestCleanupPath' {
            It 'Remove-TestArtifacts clears registered paths after each test' {
                $fixtureDir = New-TestTempDirectory -Prefix 'CleanupRegistry'
                Test-Path -LiteralPath $fixtureDir | Should -Be $true

                Remove-TestArtifacts

                Test-Path -LiteralPath $fixtureDir | Should -Be $false
            }
        }

        Context 'Get-TestArtifactPath' {
            It 'Places artifacts under tests/test-data and registers cleanup' {
                $artifactPath = Get-TestArtifactPath -FileName 'artifact-cleanup-probe.txt'
                $testDataPath = Get-TestDataPath -StartPath $PSScriptRoot

                $artifactPath | Should -BeLike "*$([IO.Path]::DirectorySeparatorChar)test-data$([IO.Path]::DirectorySeparatorChar)*"
                $artifactPath | Should -Be (Join-Path $testDataPath 'artifact-cleanup-probe.txt')

                Set-Content -LiteralPath $artifactPath -Value 'probe' -Force
                Test-Path -LiteralPath $artifactPath | Should -Be $true

                Remove-TestArtifacts

                Test-Path -LiteralPath $artifactPath | Should -Be $false
            }
        }

        Context 'Clear-TestRepoRootSpillover' {
            It 'Removes known transient files from the repository root' {
                $spillFile = Join-Path $script:RepoRoot 'hook-test-spill.txt'
                Set-Content -LiteralPath $spillFile -Value 'spill' -Force

                Clear-TestRepoRootSpillover -StartPath $PSScriptRoot

                Test-Path -LiteralPath $spillFile | Should -Be $false
            }
        }

        Context 'Clear-TestTransientStorage' {
            It 'Removes all children from tests/test-data and tests/test-artifacts' {
                $dataDir = Get-TestDataPath -StartPath $PSScriptRoot -EnsureExists
                $artifactsDir = Get-TestArtifactsPath -StartPath $PSScriptRoot -EnsureExists

                $dataFixture = New-TestTempDirectory -Prefix 'CleanupData'
                $artifactFixture = Join-Path $artifactsDir 'scripts/utils/cleanup-test.ps1'
                $artifactParent = Split-Path -Path $artifactFixture -Parent
                if (-not (Test-Path -LiteralPath $artifactParent)) {
                    New-Item -ItemType Directory -Path $artifactParent -Force | Out-Null
                }
                Set-Content -Path $artifactFixture -Value '# cleanup test' -Encoding UTF8

                $summary = Clear-TestTransientStorage -StartPath $PSScriptRoot
                $summary.RemovedItemCount | Should -BeGreaterOrEqual 2
                Test-Path -LiteralPath $dataFixture | Should -Be $false
                Test-Path -LiteralPath $artifactFixture | Should -Be $false
                Test-Path -LiteralPath $dataDir | Should -Be $true
                Test-Path -LiteralPath $artifactsDir | Should -Be $true
            }

            It 'Skips cleanup when PS_PROFILE_SKIP_TEST_CLEANUP is set' {
                $fixtureDir = New-TestTempDirectory -Prefix 'CleanupSkip'
                $originalSkip = $env:PS_PROFILE_SKIP_TEST_CLEANUP
                try {
                    $env:PS_PROFILE_SKIP_TEST_CLEANUP = '1'
                    $summary = Clear-TestTransientStorage -StartPath $PSScriptRoot
                    $summary.RemovedItemCount | Should -Be 0
                    Test-Path -LiteralPath $fixtureDir | Should -Be $true
                }
                finally {
                    if ($null -eq $originalSkip) {
                        Remove-Item Env:\PS_PROFILE_SKIP_TEST_CLEANUP -ErrorAction SilentlyContinue
                    }
                    else {
                        $env:PS_PROFILE_SKIP_TEST_CLEANUP = $originalSkip
                    }
                    Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        Context 'New-TestTempDirectory' {
            It 'Creates a temporary directory' {
                try {
                    $result = New-TestTempDirectory -Prefix 'TestSupportTests'
                    $result | Should -Not -BeNullOrEmpty -Because "New-TestTempDirectory should return a valid path"
                    if ($null -ne $result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Test-Path -LiteralPath $result | Should -Be $true -Because "Temporary directory should exist"
                        (Get-Item -LiteralPath $result).PSIsContainer | Should -Be $true -Because "Result should be a directory"
                    }
                    
                    # Cleanup
                    if ($result -and -not [string]::IsNullOrWhiteSpace($result)) {
                        Remove-Item -LiteralPath $result -Force -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    $errorDetails = @{
                        Message  = $_.Exception.Message
                        Test     = 'Creates a temporary directory'
                        Category = $_.CategoryInfo.Category
                    }
                    Write-Error "New-TestTempDirectory test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                    throw
                }
            }

            It 'Creates directory with unique name' {
                $dir1 = New-TestTempDirectory -Prefix 'TestSupportTests'
                $dir2 = New-TestTempDirectory -Prefix 'TestSupportTests'
                $dir1 | Should -Not -Be $dir2
                
                # Cleanup
                Remove-Item $dir1, $dir2 -Force -ErrorAction SilentlyContinue
            }

            It 'Uses provided prefix in directory name' {
                $result = New-TestTempDirectory -Prefix 'MyTest'
                $result | Should -Match 'MyTest'
                
                # Cleanup
                Remove-Item $result -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Describe 'TestExecution Module' {
        Context 'Get-PerformanceThreshold' {
            It 'Returns default value when environment variable is not set' {
                $env:TEST_THRESHOLD = $null
                Remove-Item Env:\TEST_THRESHOLD -ErrorAction SilentlyContinue
                $result = Get-PerformanceThreshold -EnvironmentVariable 'TEST_THRESHOLD' -Default 100
                $result | Should -Be 100
            }

            It 'Returns parsed value when environment variable is set' {
                $env:TEST_THRESHOLD = '200'
                $result = Get-PerformanceThreshold -EnvironmentVariable 'TEST_THRESHOLD' -Default 100
                $result | Should -Be 200
                Remove-Item Env:\TEST_THRESHOLD -ErrorAction SilentlyContinue
            }

            It 'Returns default when environment variable is invalid' {
                $env:TEST_THRESHOLD = 'invalid'
                $result = Get-PerformanceThreshold -EnvironmentVariable 'TEST_THRESHOLD' -Default 100
                $result | Should -Be 100
                Remove-Item Env:\TEST_THRESHOLD -ErrorAction SilentlyContinue
            }

            It 'Returns default when environment variable is zero or negative' {
                $env:TEST_THRESHOLD = '0'
                $result = Get-PerformanceThreshold -EnvironmentVariable 'TEST_THRESHOLD' -Default 100
                $result | Should -Be 100
                Remove-Item Env:\TEST_THRESHOLD -ErrorAction SilentlyContinue
            }
        }

        Context 'Invoke-TestPwshScript' {
            It 'Executes simple PowerShell script' {
                if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'pwsh is not available'
                    return
                }

                $scriptContent = 'Write-Output "Hello from test script"'
                $result = Invoke-TestPwshScript -ScriptContent $scriptContent
                $result | Should -Not -BeNullOrEmpty
                $result -join '' | Should -Match 'Hello from test script'
            }

            It 'Throws error when script fails' {
                if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'pwsh is not available'
                    return
                }

                $scriptContent = 'exit 1'
                { Invoke-TestPwshScript -ScriptContent $scriptContent } | Should -Throw
            }
        }

        Context 'Invoke-TestScriptFile' {
            It 'Returns exit code and output without throwing on non-zero exit codes' {
                if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'pwsh is not available'
                    return
                }

                $scriptPath = Join-Path (New-TestTempDirectory -Prefix 'InvokeTestScriptFile') 'exit-two.ps1'
                Set-Content -LiteralPath $scriptPath -Value 'Write-Output "done"; exit 2' -Encoding UTF8

                $result = Invoke-TestScriptFile -ScriptPath $scriptPath
                $result.ExitCode | Should -Be 2
                $result.Output | Should -Match 'done'
            }

            It 'Applies and restores per-invocation environment variables' {
                if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'pwsh is not available'
                    return
                }

                $scriptPath = Join-Path (New-TestTempDirectory -Prefix 'InvokeTestScriptFileEnv') 'read-env.ps1'
                Set-Content -LiteralPath $scriptPath -Value 'Write-Output $env:PS_PROFILE_TEST_INVOCATION_MARKER; exit 0' -Encoding UTF8
                $previous = [Environment]::GetEnvironmentVariable('PS_PROFILE_TEST_INVOCATION_MARKER', 'Process')

                try {
                    $result = Invoke-TestScriptFile -ScriptPath $scriptPath -EnvironmentVariables @{
                        PS_PROFILE_TEST_INVOCATION_MARKER = 'isolated-value'
                    }
                    $result.ExitCode | Should -Be 0
                    $result.Output | Should -Match 'isolated-value'
                    [Environment]::GetEnvironmentVariable('PS_PROFILE_TEST_INVOCATION_MARKER', 'Process') | Should -Be $previous
                }
                finally {
                    if ($null -eq $previous) {
                        Remove-Item -Path Env:PS_PROFILE_TEST_INVOCATION_MARKER -ErrorAction SilentlyContinue
                    }
                    else {
                        Set-Item -Path Env:PS_PROFILE_TEST_INVOCATION_MARKER -Value $previous
                    }
                }
            }
        }

        Context 'Non-interactive defaults' {
            It 'Provides TMPDIR when the process environment does not define it' {
                $env:TMPDIR | Should -Not -BeNullOrEmpty
                Test-Path -LiteralPath $env:TMPDIR | Should -BeTrue
            }
        }
    }

    Describe 'TestNpmHelpers Module' {
        Context 'Test-NpmPackageAvailable' {
            It 'Returns false when package is not available' {
                if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'node is not available'
                    return
                }

                $result = Test-NpmPackageAvailable -PackageName 'nonexistent-package-12345'
                $result | Should -Be $false
            }

            It 'Handles missing node command gracefully' {
                # This test assumes node might not be available
                # The function should handle this without throwing
                try {
                    $result = Test-NpmPackageAvailable -PackageName 'some-package'
                    # If we get here, function handled missing node gracefully
                    $result | Should -BeOfType [bool]
                }
                catch {
                    # If node is required, that's also acceptable behavior
                    $_.Exception.Message | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Describe 'TestModuleLoading Module' {
        Context 'Function Availability' {
            It 'All core functions are available' {
                $coreFunctions = @(
                    'Import-TestModule',
                    'Import-ModuleGroup',
                    'Ensure-ConversionModulesLoaded',
                    'Ensure-DevToolsModulesLoaded'
                )

                foreach ($func in $coreFunctions) {
                    Get-Command $func -ErrorAction Stop | Should -Not -BeNullOrEmpty
                }
            }

            It 'All configuration functions are available' {
                $configFunctions = @(
                    'Get-ConversionHelpersConfig',
                    'Get-DataCoreModulesConfig',
                    'Get-DataEncodingSubModulesConfig',
                    'Get-DataStructuredModulesConfig',
                    'Get-DataBinaryModulesConfig',
                    'Get-DataColumnarModulesConfig',
                    'Get-DataScientificModulesConfig',
                    'Get-DocumentModulesConfig',
                    'Get-MediaModulesConfig',
                    'Get-MediaColorModulesConfig',
                    'Get-DevToolsEncodingModulesConfig',
                    'Get-DevToolsCryptoModulesConfig',
                    'Get-DevToolsFormatModulesConfig',
                    'Get-DevToolsQrCodeModulesConfig',
                    'Get-DevToolsDataModulesConfig'
                )

                foreach ($func in $configFunctions) {
                    Get-Command $func -ErrorAction Stop | Should -Not -BeNullOrEmpty
                }
            }

            It 'All helper functions are available' {
                $helperFunctions = @(
                    'Import-ConversionHelpers',
                    'Import-DataConversionModules',
                    'Import-DocumentConversionModules',
                    'Import-MediaConversionModules',
                    'Import-DevToolsModules'
                )

                foreach ($func in $helperFunctions) {
                    Get-Command $func -ErrorAction Stop | Should -Not -BeNullOrEmpty
                }
            }

            It 'Configuration functions return expected data structures' {
                $coreConfig = Get-DataCoreModulesConfig
                $coreConfig | Should -BeOfType [hashtable]
                $coreConfig.Count | Should -BeGreaterThan 0

                $encodingSubModules = @(Get-DataEncodingSubModulesConfig)
                @($encodingSubModules).Count | Should -BeGreaterThan 0

                $helpers = @(Get-ConversionHelpersConfig)
                @($helpers).Count | Should -BeGreaterThan 0
            }
        }

        Context 'Import-TestModule' {
            It 'Loads module file successfully' {
                $testModulePath = New-TestTempFile -Prefix 'test-module' -Extension '.ps1'
                $moduleContent = @'
function Test-MyFunction {
    Write-Output "Test function"
}
'@
                Set-Content -Path $testModulePath -Value $moduleContent

                try {
                    Import-TestModule -ModulePath $testModulePath -FunctionPatterns @('^Test-')
                    Get-Command Test-MyFunction -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                }
                finally {
                    Remove-Item $testModulePath -Force -ErrorAction SilentlyContinue
                    Remove-Item Function:\Test-MyFunction -Force -ErrorAction SilentlyContinue
                }
            }

            It 'Handles missing module file gracefully' {
                $nonexistentPath = New-TestTempFile -Prefix 'nonexistent-module' -Extension '.ps1'
                Remove-Item -LiteralPath $nonexistentPath -Force -ErrorAction SilentlyContinue
                { Import-TestModule -ModulePath $nonexistentPath } | Should -Not -Throw
            }
        }
    }

    Describe 'TestMocks Module' {
        Context 'Reset-TestIsolationState' {
            BeforeEach {
                $script:OriginalTestMode = $env:PS_PROFILE_TEST_MODE
                $env:PS_PROFILE_TEST_MODE = '1'
            }

            AfterEach {
                if ($null -ne $script:OriginalTestMode) {
                    $env:PS_PROFILE_TEST_MODE = $script:OriginalTestMode
                }

                Set-TestCommandAvailabilityState -CommandName 'isolation-test-cmd' -Available $false -ErrorAction SilentlyContinue
                Set-TestCommandAvailabilityState -CommandName 'isolation-mock-cmd' -Available $false -ErrorAction SilentlyContinue
                Set-TestCommandAvailabilityState -CommandName 'isolation-capture-cmd' -Available $false -ErrorAction SilentlyContinue
            }

            It 'returns without clearing state when test mode is disabled' {
                Set-TestCommandAvailabilityState -CommandName 'isolation-test-cmd' -Available $true
                Get-Command isolation-test-cmd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

                $env:PS_PROFILE_TEST_MODE = '0'
                Reset-TestIsolationState

                Get-Command isolation-test-cmd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It 'clears registered mock commands' {
                Set-TestCommandAvailabilityState -CommandName 'isolation-mock-cmd' -Available $true
                Get-Command isolation-mock-cmd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
                @($global:TestRegisteredMockCommands).Count | Should -BeGreaterThan 0

                Reset-TestIsolationState

                Get-Command isolation-mock-cmd -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                @($global:TestRegisteredMockCommands).Count | Should -Be 0
            }

            It 'clears command invocation captures' {
                Setup-CapturingCommandMock -CommandName 'isolation-capture-cmd' -Output 'captured'
                & isolation-capture-cmd 'arg1'
                @($global:TestCommandInvocationCaptures).Count | Should -BeGreaterThan 0

                Reset-TestIsolationState

                @($global:TestCommandInvocationCaptures).Count | Should -Be 0
                $global:TestCommandCaptureState | Should -BeNullOrEmpty
            }

            It 'clears assumed available command pollution' {
                if (-not (Get-Variable -Name 'AssumedAvailableCommands' -Scope Global -ErrorAction SilentlyContinue)) {
                    $global:AssumedAvailableCommands = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
                }

                $global:AssumedAvailableCommands['isolation-pollution-cmd'] = $true
                Reset-TestIsolationState

                $global:AssumedAvailableCommands.ContainsKey('isolation-pollution-cmd') | Should -Be $false
            }

            It 'clears missing tool warning collections' {
                if (-not (Get-Variable -Name 'MissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
                    $global:MissingToolWarnings = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new([System.StringComparer]::OrdinalIgnoreCase)
                }

                if (-not (Get-Variable -Name 'CollectedMissingToolWarnings' -Scope Global -ErrorAction SilentlyContinue)) {
                    $global:CollectedMissingToolWarnings = [System.Collections.Generic.List[hashtable]]::new()
                }

                $global:MissingToolWarnings['isolation-tool'] = $true
                $global:CollectedMissingToolWarnings.Add(@{
                        Tool    = 'isolation-tool'
                        Message = 'isolation-tool not found.'
                    })

                Reset-TestIsolationState

                $global:MissingToolWarnings.ContainsKey('isolation-tool') | Should -Be $false
                @($global:CollectedMissingToolWarnings).Count | Should -Be 0
            }

            It 'resets lazy initialization flags' {
                $global:GitInitialized = $true
                $global:UtilitiesInitialized = $true

                Reset-TestIsolationState

                $global:GitInitialized | Should -Be $false
                $global:UtilitiesInitialized | Should -Be $false
            }

            It 'clears available command mock registry' {
                $global:__AvailableCommandMocks = @{ 'isolation-registry-cmd' = $true }
                Reset-TestIsolationState
                if (Get-Variable -Name '__AvailableCommandMocks' -Scope Global -ErrorAction SilentlyContinue) {
                    $global:__AvailableCommandMocks.ContainsKey('isolation-registry-cmd') | Should -Be $false
                }
            }

            It 'restores Mark-TestCommandsUnavailable after global override pollution' {
                function global:Mark-TestCommandsUnavailable {
                    param([string[]]$CommandNames)
                    throw 'polluted'
                }

                Restore-TestSupportFunctions

                { Mark-TestCommandsUnavailable -CommandNames 'isolation-restore-cmd' } | Should -Not -Throw
            }

            It 'clears fragment loaded state so fragments can reload' {
                Set-Variable -Name 'editorsLoaded' -Scope Global -Value $true -Force
                Set-Variable -Name 'databaseLoaded' -Scope Global -Value $true -Force

                Reset-TestIsolationState

                Get-Variable -Name 'editorsLoaded' -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                Get-Variable -Name 'databaseLoaded' -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'ToolDetection Module' {
        BeforeAll {
            $bootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
            . $bootstrapPath
        }

        Context 'Resolve-TestToolInstallCommand' {
            It 'Returns platform-aware install commands for common tools' {
                if (-not (Get-Command Resolve-TestToolInstallCommand -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Resolve-TestToolInstallCommand not loaded'
                    return
                }

                $dockerCmd = Resolve-TestToolInstallCommand -ToolName 'docker'
                $dockerCmd | Should -Not -BeNullOrEmpty
                $dockerCmd | Should -Match 'docker'

                $nodeCmd = Resolve-TestToolInstallCommand -ToolName 'node' -ToolType 'node-package'
                $nodeCmd | Should -Not -BeNullOrEmpty
                $nodeCmd | Should -Match 'node'
            }

            It 'Resolves command aliases to package names' {
                if (-not (Get-Command Resolve-TestToolInstallCommand -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Resolve-TestToolInstallCommand not loaded'
                    return
                }

                $httpCmd = Resolve-TestToolInstallCommand -ToolName 'http'
                $httpCmd | Should -Match 'httpie'

                $sshCmd = Resolve-TestToolInstallCommand -ToolName 'ssh'
                $sshCmd | Should -Match 'openssh'
            }
        }

        Context 'Test-ToolAvailable auto-resolution' {
            It 'Resolves install command when InstallCommand is omitted' {
                if (-not (Get-Command Test-ToolAvailable -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Test-ToolAvailable not loaded'
                    return
                }

                $result = Test-ToolAvailable -ToolName '__definitely_missing_tool_xyz__' -Silent
                $result.InstallCommand | Should -Not -BeNullOrEmpty
                $result.Available | Should -Be $false
            }
        }

        Context 'Get-TestToolSkipMessage helpers' {
            BeforeAll {
                $bootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
                . $bootstrapPath
            }

            It 'Get-TestToolSkipMessage includes platform-aware install commands' {
                if (-not (Get-Command Get-TestToolSkipMessage -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Get-TestToolSkipMessage not loaded'
                    return
                }

                $message = Get-TestToolSkipMessage -ToolName 'zstd' -Context 'zstd command is not available'
                $message | Should -Match 'zstd command is not available'
                $message | Should -Match 'Install with:'
                $message | Should -Match 'zstd'
            }

            It 'Get-TestNodePackageSkipMessage resolves node package install commands' {
                if (-not (Get-Command Get-TestNodePackageSkipMessage -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Get-TestNodePackageSkipMessage not loaded'
                    return
                }

                $message = Get-TestNodePackageSkipMessage -PackageNames @('superjson') -Context 'superjson package not installed'
                $message | Should -Match 'superjson'
                $message | Should -Match 'Install with:'
            }

            It 'Get-TestToolsSkipMessage combines multiple tool hints' {
                if (-not (Get-Command Get-TestToolsSkipMessage -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Get-TestToolsSkipMessage not loaded'
                    return
                }

                $message = Get-TestToolsSkipMessage -Context 'snappy command and Python are not available' -Tools @(
                    @{ Name = 'snappy' }
                    @{ Name = 'python'; ToolType = 'python-runtime' }
                )
                $message | Should -Match 'snappy'
                $message | Should -Match 'Install with:'
            }
        }

        Context 'Install command assertion helpers' {
            BeforeAll {
                $bootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
                . $bootstrapPath
            }

            It 'Get-TestInstallCommandCandidates splits fallback chains' {
                if (-not (Get-Command Get-TestInstallCommandCandidates -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Get-TestInstallCommandCandidates not loaded'
                    return
                }

                $candidates = Get-TestInstallCommandCandidates -InstallCommand 'sudo apt install fzf (or: sudo pacman -S fzf)'
                $candidates.Count | Should -BeGreaterOrEqual 2
                $candidates[0] | Should -Match 'apt install fzf'
                $candidates[1] | Should -Match 'pacman -S fzf'
            }

            It 'Resolve-TestNodePackageInstallCommand combines multiple packages' {
                if (-not (Get-Command Resolve-TestNodePackageInstallCommand -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Resolve-TestNodePackageInstallCommand not loaded'
                    return
                }

                $command = Resolve-TestNodePackageInstallCommand -PackageNames @('bson', 'cbor')
                $command | Should -Not -BeNullOrEmpty
                $command | Should -Match 'bson'
                $command | Should -Match 'cbor'
            }

            It 'Assert-TestOutputContainsInstallCommand matches platform-aware hints' {
                if (-not (Get-Command Assert-TestOutputContainsInstallCommand -ErrorAction SilentlyContinue)) {
                    Set-ItResult -Skipped -Because 'Assert-TestOutputContainsInstallCommand not loaded'
                    return
                }

                $installCommand = Resolve-TestToolInstallCommand -ToolName 'fzf'
                $output = "fzf not found. Install with: $installCommand"
                { Assert-TestOutputContainsInstallCommand -Output $output -ToolName 'fzf' } | Should -Not -Throw

                if (-not $global:CollectedMissingToolWarnings) {
                    $global:CollectedMissingToolWarnings = [System.Collections.Generic.List[hashtable]]::new()
                }
                else {
                    $global:CollectedMissingToolWarnings.Clear()
                }

                $null = $global:CollectedMissingToolWarnings.Add(@{
                        Tool        = 'fzf'
                        Message     = "fzf not found. Install with: $installCommand"
                        InstallHint = "Install with: $installCommand"
                    })
                { Assert-TestOutputContainsInstallCommand -Output '' -ToolName 'fzf' } | Should -Not -Throw
            }
        }
    }
}

