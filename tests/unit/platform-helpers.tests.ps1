. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Resolves bootstrap resources for platform helper tests.
.DESCRIPTION
    Locates the repository profile directory and bootstrap fragment so tests can dot-source
    the same helpers used by the interactive profile. The resolved paths are stored in
    script-scoped variables for reuse within the current test file.
.PARAMETER BasePath
    Optional start path for repository discovery. Defaults to the current test directory.
#>
function script:Set-TestBootstrapContext {
    param(
        [string]$BasePath = $PSScriptRoot
    )

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
    $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $BasePath -EnsureExists
}

Describe 'Platform Detection Helpers' {
    BeforeAll {
        Set-TestBootstrapContext
    }

    BeforeEach {
        # Load bootstrap to get platform helpers
        . $script:BootstrapPath
    }

    Context 'Platform Detection Functions' {
        It 'Test-IsWindows returns boolean' {
            $result = Test-IsWindows
            $result | Should -BeOfType [bool]
        }

        It 'Test-IsLinux returns boolean' {
            $result = Test-IsLinux
            $result | Should -BeOfType [bool]
        }

        It 'Test-IsMacOS returns boolean' {
            $result = Test-IsMacOS
            $result | Should -BeOfType [bool]
        }

        It 'Only one platform detection returns true' {
            $platformIndicators = @(
                (Test-IsWindows)
                (Test-IsLinux)
                (Test-IsMacOS)
            )

            $platformCount = $platformIndicators | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
            $platformCount | Should -BeLessOrEqual 1
        }
    }

    Context 'Get-UserHome Function' {
        It 'Get-UserHome returns a string' {
            $result = Get-UserHome
            $result | Should -BeOfType [string]
        }

        It 'Get-UserHome returns non-empty path' {
            $result = Get-UserHome
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Get-UserHome path exists' {
            $homePath = Get-UserHome
            Test-Path $homePath | Should -Be $true
        }

        It 'Get-UserHome works with Join-Path' {
            $homePath = Get-UserHome
            $configPath = Join-Path $homePath '.config'
            $configPath | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Cross-Platform Compatibility' {
        It 'Get-UserHome prefers $env:HOME on Unix' {
            if ((Test-IsLinux) -or (Test-IsMacOS)) {
                $originalHome = $env:HOME
                try {
                    $env:HOME = '/test/home'
                    $result = Get-UserHome
                    $result | Should -Be '/test/home'
                }
                finally {
                    $env:HOME = $originalHome
                }
            }
        }

        It 'Get-UserHome falls back to $env:USERPROFILE' {
            $originalHome = $env:HOME
            $originalUserProfile = $env:USERPROFILE
            try {
                $env:HOME = $null
                if ($env:USERPROFILE) {
                    $result = Get-UserHome
                    $result | Should -Not -BeNullOrEmpty
                }
            }
            finally {
                $env:HOME = $originalHome
                $env:USERPROFILE = $originalUserProfile
            }
        }
    }
}

Describe 'Register-LazyFunction Helper' {
    BeforeAll {
        Set-TestBootstrapContext
    }

    BeforeEach {
        . $script:BootstrapPath
    }

    Context 'Lazy Function Registration' {
        It 'Register-LazyFunction creates a function stub' {
            $testFuncName = "Test-LazyFunction_$(Get-Random)"
            $flagName = "TestLazyInitialized_{0}" -f (Get-Random)
            Set-Variable -Name $flagName -Value $false -Scope Global

            $initializer = {
                Set-Variable -Name $flagName -Value $true -Scope Global
                Set-AgentModeFunction -Name $testFuncName -Body { Write-Output 'initialized' }
            }.GetNewClosure()

            Register-LazyFunction -Name $testFuncName -Initializer $initializer

            Test-Path "Function:$testFuncName" | Should -Be $true
            (Get-Variable -Name $flagName -Scope Global -ValueOnly) | Should -Be $false

            # Cleanup
            Remove-Item "Function:$testFuncName" -ErrorAction SilentlyContinue
            Remove-Variable -Name $flagName -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Register-LazyFunction initializes on first call' {
            $testFuncName = "Test-LazyInit_$(Get-Random)"
            $flagName = "TestLazyInitialized_{0}" -f (Get-Random)
            Set-Variable -Name $flagName -Value $false -Scope Global

            $initializer = {
                Set-Variable -Name $flagName -Value $true -Scope Global
                Set-AgentModeFunction -Name $testFuncName -Body { Write-Output 'initialized' }
            }.GetNewClosure()

            Register-LazyFunction -Name $testFuncName -Initializer $initializer

            $result = & $testFuncName
            (Get-Variable -Name $flagName -Scope Global -ValueOnly) | Should -Be $true
            $result | Should -Be 'initialized'

            # Cleanup
            Remove-Item "Function:$testFuncName" -ErrorAction SilentlyContinue
            Remove-Variable -Name $flagName -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Register-LazyFunction creates alias when specified' {
            $testFuncName = "Test-LazyWithAlias_$(Get-Random)"
            $testAlias = "tla_$(Get-Random)"
            $flagName = "TestLazyInitialized_{0}" -f (Get-Random)
            Set-Variable -Name $flagName -Value $false -Scope Global

            $initializer = {
                Set-Variable -Name $flagName -Value $true -Scope Global
                Set-AgentModeFunction -Name $testFuncName -Body { Write-Output 'aliased' }
            }.GetNewClosure()

            Register-LazyFunction -Name $testFuncName -Initializer $initializer -Alias $testAlias

            Get-Alias -Name $testAlias -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

            # Cleanup
            Remove-Item "Function:$testFuncName" -ErrorAction SilentlyContinue
            Remove-Item "Alias:$testAlias" -ErrorAction SilentlyContinue
            Remove-Variable -Name $flagName -Scope Global -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Test-CachedCommand with TTL' {
    BeforeAll {
        Set-TestBootstrapContext
    }

    BeforeEach {
        . $script:BootstrapPath
    }

    Context 'Command Cache TTL' {
        It 'Test-CachedCommand caches results' {
            $result1 = Test-CachedCommand 'Get-Command'
            $result2 = Test-CachedCommand 'Get-Command'
            $result1 | Should -Be $result2
        }

        It 'Test-CachedCommand accepts CacheTTLMinutes parameter' {
            { Test-CachedCommand -Name 'Get-Command' -CacheTTLMinutes 10 } | Should -Not -Throw
        }

        It 'Test-CachedCommand returns boolean' {
            $result = Test-CachedCommand 'Get-Command'
            $result | Should -BeOfType [bool]
        }
    }
}

Describe 'Test-SafePath Security Helper' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:UtilitiesPath = Get-TestPath -RelativePath 'profile.d\05-utilities.ps1' -StartPath $PSScriptRoot -EnsureExists
    }

    BeforeEach {
        . $script:UtilitiesPath
    }

    Context 'Path Validation' {
        It 'Test-SafePath returns boolean' {
            $testBase = $TestDrive
            $testPath = Join-Path $testBase 'test.txt'
            New-Item -ItemType File -Path $testPath -Force | Out-Null

            $result = Test-SafePath -Path $testPath -BasePath $testBase
            $result | Should -BeOfType [bool]
        }

        It 'Test-SafePath allows paths within base directory' {
            $testBase = $TestDrive
            $testPath = Join-Path $testBase 'subdir' 'test.txt'
            New-Item -ItemType File -Path $testPath -Force | Out-Null

            $result = Test-SafePath -Path $testPath -BasePath $testBase
            $result | Should -Be $true
        }

        It 'Test-SafePath rejects paths outside base directory' {
            $testBase = $TestDrive
            $outsidePath = Join-Path (Split-Path $testBase -Parent) 'outside.txt'

            $result = Test-SafePath -Path $outsidePath -BasePath $testBase
            $result | Should -Be $false
        }

        It 'Test-SafePath handles path traversal attempts' {
            $testBase = $TestDrive
            $traversalPath = Join-Path $testBase '..' '..' 'etc' 'passwd'

            $result = Test-SafePath -Path $traversalPath -BasePath $testBase
            $result | Should -Be $false
        }

        It 'Test-SafePath handles invalid paths gracefully' {
            $testBase = $TestDrive
            $invalidPath = "C:\Invalid<>Path|Test"

            { Test-SafePath -Path $invalidPath -BasePath $testBase } | Should -Not -Throw
            $result = Test-SafePath -Path $invalidPath -BasePath $testBase
            $result | Should -Be $false
        }
    }
}

Describe 'Register-DeprecatedFunction Helper' {
    BeforeAll {
        Set-TestBootstrapContext
    }

    BeforeEach {
        . $script:BootstrapPath
    }

    Context 'Deprecation Warnings' {
        It 'Register-DeprecatedFunction creates wrapper function' {
            $oldName = "Test-OldFunction_$(Get-Random)"
            $newName = "Test-NewFunction_$(Get-Random)"

            # Create the new function
            Set-AgentModeFunction -Name $newName -Body { Write-Output 'new function' }

            Register-DeprecatedFunction -OldName $oldName -NewName $newName -RemovalVersion '2.0.0'

            Test-Path "Function:$oldName" | Should -Be $true

            # Cleanup
            Remove-Item "Function:$oldName" -ErrorAction SilentlyContinue
            Remove-Item "Function:$newName" -ErrorAction SilentlyContinue
        }

        It 'Register-DeprecatedFunction displays warning' {
            $oldName = "Test-Old_$(Get-Random)"
            $newName = "Test-New_$(Get-Random)"

            Set-AgentModeFunction -Name $newName -Body { Write-Output 'result' }
            Register-DeprecatedFunction -OldName $oldName -NewName $newName

            $warningOutput = & $oldName 3>&1 2>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
            $warningOutput | Should -Not -BeNullOrEmpty

            # Cleanup
            Remove-Item "Function:$oldName" -ErrorAction SilentlyContinue
            Remove-Item "Function:$newName" -ErrorAction SilentlyContinue
        }

        It 'Register-DeprecatedFunction forwards to new function' {
            $oldName = "Test-OldForward_$(Get-Random)"
            $newName = "Test-NewForward_$(Get-Random)"

            Set-AgentModeFunction -Name $newName -Body { Write-Output 'forwarded' }
            Register-DeprecatedFunction -OldName $oldName -NewName $newName

            $result = & $oldName 3>&1 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.WarningRecord] }
            $result | Should -Be 'forwarded'

            # Cleanup
            Remove-Item "Function:$oldName" -ErrorAction SilentlyContinue
            Remove-Item "Function:$newName" -ErrorAction SilentlyContinue
        }
    }
}

