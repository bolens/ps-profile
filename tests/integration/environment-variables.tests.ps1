. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Environment Variables Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '07-system.ps1')
        . (Join-Path $script:ProfileDir '05-utilities.ps1')
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
            $testName = 'TEST_VAR_GET'
            $testValue = 'test_value_get'
            try {
                [Environment]::SetEnvironmentVariable($testName, $testValue, 'User')
                $result = Get-EnvVar -Name $testName
                $result | Should -Be $testValue
            }
            finally {
                [Environment]::SetEnvironmentVariable($testName, $null, 'User')
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
            . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
            . (Join-Path $script:ProfileDir '05-utilities.ps1')
        }

        It 'Set-EnvVar sets user environment variable' {
            $testName = 'TEST_VAR_SET'
            $testValue = 'test_value_set'
            try {
                Set-EnvVar -Name $testName -Value $testValue
                $result = [Environment]::GetEnvironmentVariable($testName, 'User')
                $result | Should -Be $testValue
            }
            finally {
                [Environment]::SetEnvironmentVariable($testName, $null, 'User')
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
