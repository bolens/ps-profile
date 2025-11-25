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
function Set-TestBootstrapContext {
    param(
        [string]$BasePath = $PSScriptRoot
    )

    # Use Get-TestPath from TestSupport.ps1 for consistent path resolution
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
    $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $BasePath -EnsureExists
}

Describe 'Platform Detection Helpers' {
    BeforeAll {
        # Define function locally if not available
        if (-not (Get-Command Set-TestBootstrapContext -ErrorAction SilentlyContinue)) {
            function Set-TestBootstrapContext {
                param([string]$BasePath = $PSScriptRoot)
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
                $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $BasePath -EnsureExists
            }
        }
        Set-TestBootstrapContext
        # Import Platform module directly (functions are in scripts/lib/Platform.psm1, not bootstrap)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'Platform.psm1') -DisableNameChecking -ErrorAction Stop
    }

    BeforeEach {
        # Load bootstrap to get other helpers (Register-LazyFunction, etc.)
        # Ensure bootstrap path exists and can be loaded
        if (-not (Test-Path $script:BootstrapPath)) {
            throw "Bootstrap path not found: $script:BootstrapPath"
        }
        . $script:BootstrapPath
        # Verify Get-UserHome is available after loading bootstrap
        if (-not (Get-Command Get-UserHome -ErrorAction SilentlyContinue)) {
            throw "Get-UserHome function not available after loading bootstrap"
        }
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
        # Define function locally if not available
        if (-not (Get-Command Set-TestBootstrapContext -ErrorAction SilentlyContinue)) {
            function Set-TestBootstrapContext {
                param([string]$BasePath = $PSScriptRoot)
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
                $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $BasePath -EnsureExists
            }
        }
        Set-TestBootstrapContext
    }

    BeforeEach {
        # Ensure bootstrap path exists and can be loaded
        if (-not (Test-Path $script:BootstrapPath)) {
            throw "Bootstrap path not found: $script:BootstrapPath"
        }
        . $script:BootstrapPath
        # Verify Register-LazyFunction is available after loading bootstrap
        if (-not (Get-Command Register-LazyFunction -ErrorAction SilentlyContinue)) {
            throw "Register-LazyFunction not available after loading bootstrap"
        }
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
        # Define function locally if not available
        if (-not (Get-Command Set-TestBootstrapContext -ErrorAction SilentlyContinue)) {
            function Set-TestBootstrapContext {
                param([string]$BasePath = $PSScriptRoot)
                $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $BasePath -EnsureExists
                $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\00-bootstrap.ps1' -StartPath $BasePath -EnsureExists
            }
        }
        Set-TestBootstrapContext
    }

    BeforeEach {
        # Ensure bootstrap path exists and can be loaded
        if (-not (Test-Path $script:BootstrapPath)) {
            throw "Bootstrap path not found: $script:BootstrapPath"
        }
        . $script:BootstrapPath
        # Verify Register-LazyFunction is available after loading bootstrap
        if (-not (Get-Command Register-LazyFunction -ErrorAction SilentlyContinue)) {
            throw "Register-LazyFunction not available after loading bootstrap"
        }
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
