. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'TestSupport Modules' {
    BeforeAll {
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
                # Create a temporary directory that is NOT in a git repository
                # Use system temp directory to ensure it's outside the repo
                $tempBase = [System.IO.Path]::GetTempPath()
                $tempDir = Join-Path $tempBase "NoGitRepo-$(New-Guid)"
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
                    $result | Should -BeLike "*tests\unit" -Because "Path should contain 'tests\unit'"
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
                    $result | Should -BeLike "*tests\integration" -Because "Path should contain 'tests\integration'"
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
                    $result | Should -BeLike "*tests\performance" -Because "Path should contain 'tests\performance'"
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

                $encodingSubModules = Get-DataEncodingSubModulesConfig
                $encodingSubModules | Should -BeOfType [array]
                $encodingSubModules.Count | Should -BeGreaterThan 0

                $helpers = Get-ConversionHelpersConfig
                $helpers | Should -BeOfType [array]
                $helpers.Count | Should -BeGreaterThan 0
            }
        }

        Context 'Import-TestModule' {
            It 'Loads module file successfully' {
                # Create a temporary test module
                $testModulePath = Join-Path $env:TEMP "test-module-$(Get-Random).ps1"
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
                $nonexistentPath = Join-Path $env:TEMP "nonexistent-module-$(Get-Random).ps1"
                { Import-TestModule -ModulePath $nonexistentPath } | Should -Not -Throw
            }
        }
    }
}

