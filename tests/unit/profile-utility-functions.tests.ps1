#
# Tests for general-purpose utility helpers exposed by profile fragments.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
}

Describe 'Profile utility functions' {
    Context 'Environment variable helpers' {
        It 'Get-EnvVar retrieves environment variable from registry' {
            $tempVar = "TEST_VAR_{0}" -f (Get-Random)
            try {
                Set-EnvVar -Name $tempVar -Value 'test_value'
                $value = Get-EnvVar -Name $tempVar
                $value | Should -Be 'test_value'
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }

        It 'Set-EnvVar sets environment variable in registry' {
            $tempVar = "TEST_VAR_{0}" -f (Get-Random)
            try {
                Set-EnvVar -Name $tempVar -Value 'test_value'
                Get-EnvVar -Name $tempVar | Should -Be 'test_value'
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }

        It 'Get-EnvVar handles non-existent variables gracefully' {
            $name = "NON_EXISTENT_VAR_{0}" -f (Get-Random)
            $result = Get-EnvVar -Name $name
            ($result -eq $null -or $result -eq '') | Should -Be $true
        }

        It 'Set-EnvVar can delete variables by setting to null' {
            $tempVar = "TEST_DELETE_{0}" -f (Get-Random)
            try {
                Set-EnvVar -Name $tempVar -Value 'test'
                Get-EnvVar -Name $tempVar | Should -Be 'test'
                Set-EnvVar -Name $tempVar -Value $null
                $cleared = Get-EnvVar -Name $tempVar
                ($cleared -eq $null -or $cleared -eq '') | Should -Be $true
            }
            finally {
                Set-EnvVar -Name $tempVar -Value $null
            }
        }
    }

    Context 'Time helpers' {
        It 'from-epoch converts Unix timestamp correctly' {
            $timestamp = 1609459200
            $result = from-epoch $timestamp
            $result.Year | Should -Be 2020
            $result.Month | Should -Be 12
            $result.Day | Should -Be 31
        }

        It 'epoch returns current Unix timestamp' {
            $before = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $result = epoch
            $after = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $result | Should -BeGreaterThan ($before - 1)
            $result | Should -BeLessThan ($after + 1)
        }

        It 'from-epoch handles epoch 0 correctly' {
            $result = from-epoch 0
            $utc = $result.ToUniversalTime()
            $utc.Year | Should -Be 1970
            $utc.Month | Should -Be 1
            $utc.Day | Should -Be 1
        }
    }

    Context 'Password helpers' {
        It 'pwgen generates password of correct length' {
            $password = pwgen
            $password.Length | Should -Be 16
            $password | Should -Match '^[a-zA-Z0-9]+$'
        }

        It 'pwgen generates unique passwords on consecutive calls' {
            $first = pwgen
            $second = pwgen
            $first | Should -Not -Be $second
        }
    }

    Context 'PATH management helpers' {
        It 'Remove-Path removes directory from PATH' {
            $testPath = Join-Path $TestDrive 'TestPath'
            $originalPath = $env:PATH
            try {
                $env:PATH = "$env:PATH;$testPath"
                $env:PATH | Should -Match ([regex]::Escape($testPath))
                Remove-Path -Path $testPath
                $env:PATH | Should -Not -Match ([regex]::Escape($testPath))
            }
            finally {
                $env:PATH = $originalPath
                if (Test-Path $testPath) {
                    Remove-Item -Path $testPath -Recurse -Force
                }
            }
        }

        It 'Add-Path adds directory to PATH' {
            $testPath = Join-Path $TestDrive 'TestAddPath'
            if (-not (Test-Path $testPath)) {
                New-Item -ItemType Directory -Path $testPath -Force | Out-Null
            }

            $originalPath = $env:PATH
            try {
                if ($env:PATH -split ';' -contains $testPath) {
                    Remove-Path -Path $testPath
                }

                Add-Path -Path $testPath
                $env:PATH | Should -Match ([regex]::Escape($testPath))

                Remove-Path -Path $testPath
                $env:PATH | Should -Not -Match ([regex]::Escape($testPath))
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }
}
