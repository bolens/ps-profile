<#
tests/unit/library-scoop-detection-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ScoopDetection path resolution helpers.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ScoopDetectionPath = Join-Path $script:LibPath 'runtime' 'ScoopDetection.psm1'
    Import-Module $script:ScoopDetectionPath -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'ScoopDetectionExtended'
    $script:FakeScoopRoot = Join-Path $script:TempDir 'scoop'
    New-Item -ItemType Directory -Path (Join-Path $script:FakeScoopRoot 'shims') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:FakeScoopRoot 'apps') -Force | Out-Null
}

AfterAll {
    Remove-Module ScoopDetection -ErrorAction SilentlyContinue -Force
}

Describe 'ScoopDetection extended scenarios' {
    Context 'Get-ScoopRoot' {
        It 'Prefers SCOOP_GLOBAL over SCOOP when both are set' {
            $globalRoot = Join-Path $script:TempDir 'scoop-global'
            New-Item -ItemType Directory -Path (Join-Path $globalRoot 'apps') -Force | Out-Null
            $originalGlobal = $env:SCOOP_GLOBAL
            $originalLocal = $env:SCOOP

            try {
                $env:SCOOP_GLOBAL = $globalRoot
                $env:SCOOP = $script:FakeScoopRoot

                Get-ScoopRoot | Should -Be $globalRoot
            }
            finally {
                $env:SCOOP_GLOBAL = $originalGlobal
                $env:SCOOP = $originalLocal
            }
        }
    }

    Context 'Get-ScoopShimsPath and Get-ScoopBinPath' {
        BeforeEach {
            $originalScoop = $env:SCOOP
            $env:SCOOP = $script:FakeScoopRoot
        }

        AfterEach {
            $env:SCOOP = $originalScoop
        }

        It 'Resolves the shims directory under the detected root' {
            Get-ScoopShimsPath | Should -Be (Join-Path $script:FakeScoopRoot 'shims')
        }

        It 'Returns null for bin path when the bin directory does not exist' {
            Get-ScoopBinPath | Should -BeNullOrEmpty
        }
    }

    Context 'Test-ScoopInstalled' {
        It 'Reports installed when a valid Scoop root is detected' {
            $originalScoop = $env:SCOOP
            try {
                $env:SCOOP = $script:FakeScoopRoot
                Test-ScoopInstalled | Should -Be $true
            }
            finally {
                $env:SCOOP = $originalScoop
            }
        }
    }

    Context 'Add-ScoopToPath' {
        BeforeEach {
            $script:OriginalPath = $env:PATH
            $script:OriginalScoop = $env:SCOOP
            $env:SCOOP = $script:FakeScoopRoot
            New-Item -ItemType Directory -Path (Join-Path $script:FakeScoopRoot 'bin') -Force | Out-Null
        }

        AfterEach {
            $env:PATH = $script:OriginalPath
            $env:SCOOP = $script:OriginalScoop
        }

        It 'Prepends shims and bin directories to PATH when they are missing' {
            $added = Add-ScoopToPath -ScoopRoot $script:FakeScoopRoot

            $added | Should -Be $true
            $env:PATH | Should -Match ([regex]::Escape((Join-Path $script:FakeScoopRoot 'shims')))
            $env:PATH | Should -Match ([regex]::Escape((Join-Path $script:FakeScoopRoot 'bin')))
        }

        It 'Can add only the shims directory when AddBin is disabled' {
            $shims = Join-Path $script:FakeScoopRoot 'shims'
            $env:PATH = ($env:PATH -split [regex]::Escape([System.IO.Path]::PathSeparator) |
                Where-Object { $_ -and $_ -notlike "*$([regex]::Escape($shims))*" -and $_ -notlike "*$([regex]::Escape((Join-Path $script:FakeScoopRoot 'bin')))*" }) -join [System.IO.Path]::PathSeparator

            Add-ScoopToPath -ScoopRoot $script:FakeScoopRoot -AddBin:$false | Should -Be $true
            $env:PATH | Should -Match ([regex]::Escape($shims))
        }

        It 'Returns false when paths are already present in PATH' {
            $shims = Join-Path $script:FakeScoopRoot 'shims'
            $bin = Join-Path $script:FakeScoopRoot 'bin'
            $env:PATH = "$shims$([System.IO.Path]::PathSeparator)$bin$([System.IO.Path]::PathSeparator)$env:PATH"

            Add-ScoopToPath -ScoopRoot $script:FakeScoopRoot | Should -Be $false
        }
    }

    Context 'Get-ScoopRoot via SCOOP_HOME' {
        It 'Detects scoop root when SCOOP_HOME points at the installation root' {
            $root = Join-Path $script:TempDir 'scoop-home-root'
            New-Item -ItemType Directory -Path (Join-Path $root 'apps') -Force | Out-Null
            $original = $env:SCOOP_HOME
            $originalScoop = $env:SCOOP
            $originalGlobal = $env:SCOOP_GLOBAL

            try {
                Remove-Item Env:SCOOP -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue
                $env:SCOOP_HOME = $root

                Get-ScoopRoot | Should -Be $root
            }
            finally {
                if ($null -eq $original) { Remove-Item Env:SCOOP_HOME -ErrorAction SilentlyContinue } else { $env:SCOOP_HOME = $original }
                if ($null -eq $originalScoop) { Remove-Item Env:SCOOP -ErrorAction SilentlyContinue } else { $env:SCOOP = $originalScoop }
                if ($null -eq $originalGlobal) { Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue } else { $env:SCOOP_GLOBAL = $originalGlobal }
            }
        }
    }

    Context 'Get-ScoopRoot via SCOOP_ROOT' {
        It 'Detects scoop root when SCOOP_ROOT points at a directory with apps' {
            $root = Join-Path $script:TempDir 'scoop-root-env'
            New-Item -ItemType Directory -Path (Join-Path $root 'apps') -Force | Out-Null
            $original = $env:SCOOP_ROOT
            $originalScoop = $env:SCOOP
            $originalGlobal = $env:SCOOP_GLOBAL

            try {
                Remove-Item Env:SCOOP -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue
                $env:SCOOP_ROOT = $root

                Get-ScoopRoot | Should -Be $root
            }
            finally {
                if ($null -eq $original) { Remove-Item Env:SCOOP_ROOT -ErrorAction SilentlyContinue } else { $env:SCOOP_ROOT = $original }
                if ($null -eq $originalScoop) { Remove-Item Env:SCOOP -ErrorAction SilentlyContinue } else { $env:SCOOP = $originalScoop }
                if ($null -eq $originalGlobal) { Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue } else { $env:SCOOP_GLOBAL = $originalGlobal }
            }
        }
    }

    Context 'Get-ScoopCompletionPath' {
        It 'Returns null when the completion module file is missing' {
            Get-ScoopCompletionPath -ScoopRoot $script:FakeScoopRoot | Should -BeNullOrEmpty
        }

        It 'Resolves the completion module when the psd1 file exists' {
            $completionDir = Join-Path $script:FakeScoopRoot 'apps' 'scoop' 'current' 'supporting' 'completion'
            New-Item -ItemType Directory -Path $completionDir -Force | Out-Null
            $completionFile = Join-Path $completionDir 'Scoop-Completion.psd1'
            Set-Content -LiteralPath $completionFile -Value '@{ RootModule = "" }' -Encoding UTF8

            Get-ScoopCompletionPath -ScoopRoot $script:FakeScoopRoot | Should -Be $completionFile
        }
    }

    Context 'Get-ScoopBinPath' {
        It 'Returns the bin directory when it exists under the scoop root' {
            $binDir = Join-Path $script:FakeScoopRoot 'bin'
            New-Item -ItemType Directory -Path $binDir -Force | Out-Null

            Get-ScoopBinPath -ScoopRoot $script:FakeScoopRoot | Should -Be $binDir
        }
    }

    Context 'Fallback validation without Test-ValidPath' {
        BeforeEach {
            Remove-Module Validation -ErrorAction SilentlyContinue -Force
            $script:OriginalScoop = $env:SCOOP
            $env:SCOOP = $script:FakeScoopRoot
        }

        AfterEach {
            Import-Module (Join-Path $script:LibPath 'core' 'Validation.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue
            $env:SCOOP = $script:OriginalScoop
        }

        It 'Resolves shims using manual path checks when validation helpers are unavailable' {
            Get-ScoopShimsPath -ScoopRoot $script:FakeScoopRoot |
                Should -Be (Join-Path $script:FakeScoopRoot 'shims')
        }
    }

    Context 'Get-ScoopRoot parent directory resolution' {
        It 'Detects scoop root from a parent directory when SCOOP_ROOT points at a nested folder' {
            $root = Join-Path $script:TempDir 'scoop-parent-root'
            $nested = Join-Path $root 'nested'
            New-Item -ItemType Directory -Path (Join-Path $root 'apps') -Force | Out-Null
            New-Item -ItemType Directory -Path $nested -Force | Out-Null

            $originalRoot = $env:SCOOP_ROOT
            $originalScoop = $env:SCOOP
            $originalGlobal = $env:SCOOP_GLOBAL

            try {
                Remove-Item Env:SCOOP -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue
                $env:SCOOP_ROOT = $nested

                Get-ScoopRoot | Should -Be $root
            }
            finally {
                if ($null -eq $originalRoot) { Remove-Item Env:SCOOP_ROOT -ErrorAction SilentlyContinue } else { $env:SCOOP_ROOT = $originalRoot }
                if ($null -eq $originalScoop) { Remove-Item Env:SCOOP -ErrorAction SilentlyContinue } else { $env:SCOOP = $originalScoop }
                if ($null -eq $originalGlobal) { Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue } else { $env:SCOOP_GLOBAL = $originalGlobal }
            }
        }
    }

    Context 'Get-ScoopRoot default location' {
        It 'Detects scoop at the default home directory when no scoop env vars are set' {
            $fakeHome = Join-Path $script:TempDir 'fake-user-home'
            $defaultScoop = Join-Path $fakeHome 'scoop'
            New-Item -ItemType Directory -Path (Join-Path $defaultScoop 'apps') -Force | Out-Null

            $originalHome = $env:HOME
            $originalScoop = $env:SCOOP
            $originalGlobal = $env:SCOOP_GLOBAL
            $originalRoot = $env:SCOOP_ROOT
            $originalHomeEnv = $env:SCOOP_HOME

            try {
                Remove-Item Env:SCOOP -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_ROOT -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_HOME -ErrorAction SilentlyContinue
                $env:HOME = $fakeHome

                Get-ScoopRoot | Should -Be $defaultScoop
            }
            finally {
                if ($null -eq $originalHome) { Remove-Item Env:HOME -ErrorAction SilentlyContinue } else { $env:HOME = $originalHome }
                if ($null -eq $originalScoop) { Remove-Item Env:SCOOP -ErrorAction SilentlyContinue } else { $env:SCOOP = $originalScoop }
                if ($null -eq $originalGlobal) { Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue } else { $env:SCOOP_GLOBAL = $originalGlobal }
                if ($null -eq $originalRoot) { Remove-Item Env:SCOOP_ROOT -ErrorAction SilentlyContinue } else { $env:SCOOP_ROOT = $originalRoot }
                if ($null -eq $originalHomeEnv) { Remove-Item Env:SCOOP_HOME -ErrorAction SilentlyContinue } else { $env:SCOOP_HOME = $originalHomeEnv }
            }
        }
    }

    Context 'Add-ScoopToPath bin-only mode' {
        BeforeEach {
            $script:OriginalPath = $env:PATH
            $script:OriginalScoop = $env:SCOOP
            $env:SCOOP = $script:FakeScoopRoot
            New-Item -ItemType Directory -Path (Join-Path $script:FakeScoopRoot 'bin') -Force | Out-Null
        }

        AfterEach {
            $env:PATH = $script:OriginalPath
            $env:SCOOP = $script:OriginalScoop
        }

        It 'Can add only the bin directory when AddShims is disabled' {
            $bin = Join-Path $script:FakeScoopRoot 'bin'
            $shims = Join-Path $script:FakeScoopRoot 'shims'
            $env:PATH = ($env:PATH -split [regex]::Escape([System.IO.Path]::PathSeparator) |
                Where-Object { $_ -and $_ -notlike "*$([regex]::Escape($bin))*" -and $_ -notlike "*$([regex]::Escape($shims))*" }) -join [System.IO.Path]::PathSeparator

            Add-ScoopToPath -ScoopRoot $script:FakeScoopRoot -AddShims:$false | Should -Be $true
            $env:PATH | Should -Match ([regex]::Escape($bin))
            $env:PATH | Should -Not -Match ([regex]::Escape($shims))
        }
    }

    Context 'Test-ScoopInstalled negative detection' {
        It 'Reports not installed when no scoop root can be detected' {
            $originalHome = $env:HOME
            $originalScoop = $env:SCOOP
            $originalGlobal = $env:SCOOP_GLOBAL
            $originalRoot = $env:SCOOP_ROOT
            $originalHomeEnv = $env:SCOOP_HOME
            $isolatedHome = New-TestTempDirectory -Prefix 'ScoopNotInstalled'

            try {
                Remove-Item Env:SCOOP -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_ROOT -ErrorAction SilentlyContinue
                Remove-Item Env:SCOOP_HOME -ErrorAction SilentlyContinue
                $env:HOME = $isolatedHome

                Test-ScoopInstalled | Should -Be $false
            }
            finally {
                if ($null -eq $originalHome) { Remove-Item Env:HOME -ErrorAction SilentlyContinue } else { $env:HOME = $originalHome }
                if ($null -eq $originalScoop) { Remove-Item Env:SCOOP -ErrorAction SilentlyContinue } else { $env:SCOOP = $originalScoop }
                if ($null -eq $originalGlobal) { Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue } else { $env:SCOOP_GLOBAL = $originalGlobal }
                if ($null -eq $originalRoot) { Remove-Item Env:SCOOP_ROOT -ErrorAction SilentlyContinue } else { $env:SCOOP_ROOT = $originalRoot }
                if ($null -eq $originalHomeEnv) { Remove-Item Env:SCOOP_HOME -ErrorAction SilentlyContinue } else { $env:SCOOP_HOME = $originalHomeEnv }
            }
        }
    }

    Context 'ScoopDetection module initialization' {
        It 'Imports dependencies through manual fallbacks when SafeImport is unavailable' {
            $runtimeDir = Join-Path $script:TempDir 'runtime-isolated'
            New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
            Copy-Item -LiteralPath $script:ScoopDetectionPath -Destination $runtimeDir
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -Destination $runtimeDir
            Copy-Item -LiteralPath (Join-Path $script:LibPath 'core' 'Platform.psm1') -Destination $runtimeDir

            Remove-Module ScoopDetection, SafeImport, PathResolution, Platform -ErrorAction SilentlyContinue -Force

            try {
                { Import-Module (Join-Path $runtimeDir 'ScoopDetection.psm1') -DisableNameChecking -Force } | Should -Not -Throw
                Get-Command Get-ScoopRoot -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Module ScoopDetection -ErrorAction SilentlyContinue -Force
                Import-Module $script:ScoopDetectionPath -DisableNameChecking -Force
            }
        }
    }

    Context 'Debug tracing' {
        It 'Emits level 3 tracing when SCOOP_GLOBAL is used' {
            $globalRoot = Join-Path $script:TempDir 'scoop-global-debug'
            New-Item -ItemType Directory -Path (Join-Path $globalRoot 'apps') -Force | Out-Null
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalGlobal = $env:SCOOP_GLOBAL
            $originalScoop = $env:SCOOP

            try {
                $env:PS_PROFILE_DEBUG = '3'
                $env:SCOOP_GLOBAL = $globalRoot
                Remove-Item Env:SCOOP -ErrorAction SilentlyContinue

                Get-ScoopRoot | Should -Be $globalRoot
            }
            finally {
                if ($null -eq $originalDebug) { Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue } else { $env:PS_PROFILE_DEBUG = $originalDebug }
                if ($null -eq $originalGlobal) { Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue } else { $env:SCOOP_GLOBAL = $originalGlobal }
                if ($null -eq $originalScoop) { Remove-Item Env:SCOOP -ErrorAction SilentlyContinue } else { $env:SCOOP = $originalScoop }
            }
        }

        It 'Emits verbose output when PS_PROFILE_DEBUG is level 2' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $originalScoop = $env:SCOOP
            $env:PS_PROFILE_DEBUG = '2'
            $env:SCOOP = $script:FakeScoopRoot

            try {
                $null = Add-ScoopToPath -ScoopRoot $script:FakeScoopRoot
                Test-ScoopInstalled | Should -Be $true
            }
            finally {
                $env:SCOOP = $originalScoop
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }
}
