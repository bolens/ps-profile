

Describe 'Environment Variable Integration Tests' {
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
            Write-Error "Failed to initialize environment variable tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }
    
    AfterAll {
        # Restore all mocked environment variables
        if (Get-Command Restore-AllMocks -ErrorAction SilentlyContinue) {
            Restore-AllMocks
        }
    }

    BeforeEach {
        . (Join-Path $script:ProfileDir 'env.ps1')
    }

    Context 'Environment defaults and helpers' {
        It 'sets EDITOR default when not set' {
            try {
                # Mock EDITOR as unset
                Mock-EnvironmentVariable -Name 'EDITOR' -Value $null
                
                . (Join-Path $script:ProfileDir 'env.ps1')
                $env:EDITOR | Should -Be 'code' -Because "EDITOR should default to 'code' when not set"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Variable = 'EDITOR'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "EDITOR default test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'does not overwrite existing EDITOR' {
            try {
                $testEditor = 'vim'
                Mock-EnvironmentVariable -Name 'EDITOR' -Value $testEditor
                
                . (Join-Path $script:ProfileDir 'env.ps1')
                $env:EDITOR | Should -Be $testEditor -Because "EDITOR should not be overwritten when already set"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Variable = 'EDITOR'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "EDITOR preservation test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'sets GIT_EDITOR default when not set' {
            try {
                # Mock GIT_EDITOR as unset
                Mock-EnvironmentVariable -Name 'GIT_EDITOR' -Value $null
                
                . (Join-Path $script:ProfileDir 'env.ps1')
                $env:GIT_EDITOR | Should -Be 'code --wait' -Because "GIT_EDITOR should default to 'code --wait' when not set"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Variable = 'GIT_EDITOR'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "GIT_EDITOR default test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'sets VISUAL default when not set' {
            try {
                # Mock VISUAL as unset
                Mock-EnvironmentVariable -Name 'VISUAL' -Value $null
                
                . (Join-Path $script:ProfileDir 'env.ps1')
                $env:VISUAL | Should -Be 'code' -Because "VISUAL should default to 'code' when not set"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Variable = 'VISUAL'
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "VISUAL default test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
        }

        It 'Get-EnvVar handles non-existent variables' {
            $nonExistent = "NON_EXISTENT_VAR_$(Get-Random)"
            $result = Get-EnvVar -Name $nonExistent
            ($result -eq $null -or $result -eq '') | Should -Be $true
        }

        It 'Set-EnvVar handles null values for deletion' {
            $tempVar = "TEST_DELETE_$(Get-Random)"
            try {
                Set-EnvVar -Name $tempVar -Value 'test'
                $before = Get-EnvVar -Name $tempVar
                $before | Should -Be 'test'

                Set-EnvVar -Name $tempVar -Value $null
                $after = Get-EnvVar -Name $tempVar
                ($after -eq $null -or $after -eq '') | Should -Be $true
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }
    }
}

