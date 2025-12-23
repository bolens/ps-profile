

Describe 'Environment Variables Integration Tests' {
    BeforeAll {
        try {
            # Load TestSupport to get Mock-EnvironmentVariable
            $testSupportPath = Get-TestSupportPath -StartPath $PSScriptRoot
            if ($null -eq $testSupportPath -or [string]::IsNullOrWhiteSpace($testSupportPath)) {
                throw "Get-TestSupportPath returned null or empty value"
            }
            if (-not (Test-Path -LiteralPath $testSupportPath)) {
                throw "TestSupport file not found at: $testSupportPath"
            }
            . $testSupportPath
            
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
            
            $systemPath = Join-Path $script:ProfileDir 'system.ps1'
            if ($systemPath -and (Test-Path -LiteralPath $systemPath)) {
                . $systemPath
            }
            
            $utilitiesPath = Join-Path $script:ProfileDir 'utilities.ps1'
            if ($null -eq $utilitiesPath -or [string]::IsNullOrWhiteSpace($utilitiesPath)) {
                throw "UtilitiesPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $utilitiesPath)) {
                throw "Utilities fragment not found at: $utilitiesPath"
            }
            . $utilitiesPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize environment variables tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }
    
    AfterAll {
        # Restore all mocked environment variables
        if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
            Restore-AllMocks
        }
    }

    Context 'Error recovery tests' {

        It 'Get-EnvVar handles non-existent variables' {
            $result = Get-EnvVar -Name 'NonExistentVar'
            $result | Should -Be $null
        }

        It 'Get-EnvVar handles null name' {
            { Get-EnvVar -Name $null } | Should -Throw
        }

        It 'Get-EnvVar handles empty name' {
            { Get-EnvVar -Name '' } | Should -Throw
        }

        It 'Get-EnvVar retrieves existing variables' {
            try {
                $testName = 'TEST_VAR_GET'
                $testValue = 'test_value_get'
                Mock-EnvironmentVariable -Name $testName -Value $testValue
                
                $result = Get-EnvVar -Name $testName
                $result | Should -Be $testValue -Because "Get-EnvVar should retrieve the value of an existing variable"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Function = 'Get-EnvVar'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Get-EnvVar retrieval test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Remove-Path handles malformed PATH' {
            $originalPath = $env:PATH
            try {
                # Create a malformed PATH with double semicolons
                $env:PATH = 'C:\Path1;;C:\Path2;;;C:\Path3'
                Remove-Path -Path 'C:\Path2'
                # Should still work despite malformed PATH
                $env:PATH | Should -Not -Match 'C:\\Path2'
            }
            finally {
                $env:PATH = $originalPath
            }
        }

        It 'Remove-Path handles PATH with only one entry' {
            $originalPath = $env:PATH
            try {
                $env:PATH = 'C:\SinglePath'
                Remove-Path -Path 'C:\SinglePath'
                $env:PATH | Should -Be ''
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }

    Context 'Environment variable management tests' {
        BeforeAll {
            . (Join-Path $script:ProfileDir 'bootstrap.ps1')
            . (Join-Path $script:ProfileDir 'utilities.ps1')
        }

        It 'Set-EnvVar sets user environment variable' {
            try {
                $testName = 'TEST_VAR_SET'
                $testValue = 'test_value_set'
                
                Set-EnvVar -Name $testName -Value $testValue
                $result = [Environment]::GetEnvironmentVariable($testName, 'User')
                $result | Should -Be $testValue -Because "Set-EnvVar should set the environment variable value"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Function = 'Set-EnvVar'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Set-EnvVar test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
            finally {
                # Clean up user environment variable (Set-EnvVar sets User-level, not Process-level)
                [Environment]::SetEnvironmentVariable('TEST_VAR_SET', $null, 'User')
            }
        }

        It 'Set-EnvVar handles null value' {
            $testName = 'TEST_VAR_NULL'
            try {
                Set-EnvVar -Name $testName -Value $null
                $result = [Environment]::GetEnvironmentVariable($testName, 'User')
                ($result -eq $null -or $result -eq '') | Should -Be $true
            }
            finally {
                [Environment]::SetEnvironmentVariable($testName, $null, 'User')
            }
        }

        It 'Set-EnvVar handles empty value' {
            $testName = 'TEST_VAR_EMPTY'
            try {
                Set-EnvVar -Name $testName -Value ''
                $result = [Environment]::GetEnvironmentVariable($testName, 'User')
                ($result -eq $null -or $result -eq '') | Should -Be $true
            }
            finally {
                [Environment]::SetEnvironmentVariable($testName, $null, 'User')
            }
        }

        It 'Set-EnvVar handles null name' {
            { Set-EnvVar -Name $null -Value 'test' } | Should -Throw
        }

        It 'Set-EnvVar handles empty name' {
            { Set-EnvVar -Name '' -Value 'test' } | Should -Throw
        }

        It 'Publish-EnvVar function exists and can be called' {
            Get-Command Publish-EnvVar -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Publish-EnvVar doesn't take parameters - it just broadcasts changes
            { Publish-EnvVar } | Should -Not -Throw
        }

        It 'Publish-EnvVar handles null value' {
            # Publish-EnvVar doesn't take parameters, but we can test it after setting a null value
            $testName = 'TEST_NULL_PUBLISH'
            try {
                Set-EnvVar -Name $testName -Value $null
                { Publish-EnvVar } | Should -Not -Throw
            }
            finally {
                [Environment]::SetEnvironmentVariable($testName, $null, 'User')
            }
        }

        It 'Publish-EnvVar handles empty value' {
            # Publish-EnvVar doesn't take parameters, but we can test it after setting an empty value
            $testName = 'TEST_EMPTY_PUBLISH'
            try {
                Set-EnvVar -Name $testName -Value ''
                { Publish-EnvVar } | Should -Not -Throw
            }
            finally {
                [Environment]::SetEnvironmentVariable($testName, $null, 'User')
            }
        }
    }
}

