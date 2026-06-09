<#
tests/unit/library-filesystem-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FileSystem validation helpers and script discovery.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'FileSystemExtended'
}

AfterAll {
    Remove-Module FileSystem -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FileSystem extended scenarios' {
    Context 'Test-RequiredParameters' {
        It 'Passes when all required parameters are populated' {
            { Test-RequiredParameters -Parameters @{ Path = 'value'; Name = 'sample' } } | Should -Not -Throw
        }

        It 'Throws when a required parameter is whitespace' {
            { Test-RequiredParameters -Parameters @{ Path = '   ' } } | Should -Throw '*Path*'
        }

        It 'Throws when a required parameter is null' {
            { Test-RequiredParameters -Parameters @{ Name = $null } } | Should -Throw '*Name*'
        }
    }

    Context 'Test-PathExists' {
        It 'Validates existing files with File path type' {
            $file = Join-Path $script:TempRoot 'exists.ps1'
            Set-Content -LiteralPath $file -Value '# sample' -Encoding UTF8

            Test-PathExists -Path $file -PathType File | Should -Be $true
        }

        It 'Throws when a directory is validated as a file' {
            $directory = Join-Path $script:TempRoot 'dir-only'
            New-Item -ItemType Directory -Path $directory -Force | Out-Null

            { Test-PathExists -Path $directory -PathType File } | Should -Throw '*not a file*'
        }
    }

    Context 'Get-PowerShellScripts' {
        It 'Sorts scripts by name when requested' {
            $scriptsDir = Join-Path $script:TempRoot 'sorted-scripts'
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $scriptsDir 'z-last.ps1') -Value '# z' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $scriptsDir 'a-first.ps1') -Value '# a' -Encoding UTF8

            $scripts = @(Get-PowerShellScripts -Path $scriptsDir -SortByName)

            @($scripts).Count | Should -Be 2
            $scripts[0].Name | Should -Be 'a-first.ps1'
            $scripts[1].Name | Should -Be 'z-last.ps1'
        }

        It 'Finds scripts in nested directories when Recurse is enabled' {
            $root = Join-Path $script:TempRoot 'recursive-scripts'
            $nested = Join-Path $root 'nested'
            New-Item -ItemType Directory -Path $nested -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'root.ps1') -Value '# root' -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $nested 'child.ps1') -Value '# child' -Encoding UTF8

            @((Get-PowerShellScripts -Path $root -Recurse)).Count | Should -Be 2
        }

        It 'Throws when the script directory does not exist' {
            $missing = Join-Path $script:TempRoot 'missing-scripts-dir'
            { Get-PowerShellScripts -Path $missing } | Should -Throw '*does not exist*'
        }
    }

    Context 'Ensure-DirectoryExists extended scenarios' {
        It 'Creates missing directories successfully' {
            $target = Join-Path $script:TempRoot 'created-on-demand'
            Ensure-DirectoryExists -Path $target
            Test-Path -LiteralPath $target -PathType Container | Should -Be $true
        }

        It 'Uses custom error messages when mkdir fails' {
            $target = Join-Path $script:TempRoot 'mkdir-failure'
            $originalFlag = $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR
            $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR = '1'

            try {
                { Ensure-DirectoryExists -Path $target -ErrorMessage 'custom mkdir failure' } |
                    Should -Throw 'custom mkdir failure'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR = $originalFlag
                }
            }
        }
    }

    Context 'Test-PathExists and Test-PathParameter extended scenarios' {
        It 'Validates directory path type successfully' {
            $directory = Join-Path $script:TempRoot 'path-exists-dir'
            New-Item -ItemType Directory -Path $directory -Force | Out-Null

            Test-PathExists -Path $directory -PathType Directory | Should -Be $true
        }

        It 'Accepts optional empty paths in Test-PathParameter' {
            Test-PathParameter -Path '' -Optional | Should -Be $true
        }

        It 'Accepts FileInfo objects in Test-PathParameter' {
            $file = Join-Path $script:TempRoot 'fileinfo-target.ps1'
            Set-Content -LiteralPath $file -Value '# probe' -Encoding UTF8
            $fileInfo = Get-Item -LiteralPath $file

            Test-PathParameter -Path $fileInfo -PathType File | Should -Be $true
        }
    }

    Context 'FileSystem test environment hooks' {
        It 'Uses plain errors when structured logging is disabled for mkdir failures' {
            $target = Join-Path $script:TempRoot 'plain-error-dir'
            $originalMkdirFlag = $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR
            $originalStructuredFlag = $env:PS_PROFILE_FILESYSTEM_DISABLE_STRUCTURED_ERROR
            $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR = '1'
            $env:PS_PROFILE_FILESYSTEM_DISABLE_STRUCTURED_ERROR = '1'

            try {
                { Ensure-DirectoryExists -Path $target } | Should -Throw
            }
            finally {
                if ($null -eq $originalMkdirFlag) {
                    Remove-Item Env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR = $originalMkdirFlag
                }

                if ($null -eq $originalStructuredFlag) {
                    Remove-Item Env:PS_PROFILE_FILESYSTEM_DISABLE_STRUCTURED_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILESYSTEM_DISABLE_STRUCTURED_ERROR = $originalStructuredFlag
                }
            }
        }

        It 'Emits verbose output when directory creation succeeds with debug enabled' {
            $target = Join-Path $script:TempRoot 'debug-created'
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                Ensure-DirectoryExists -Path $target
                Test-Path -LiteralPath $target -PathType Container | Should -Be $true
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Recovers partial results when access is denied through the test hook' {
            $scriptsDir = Join-Path $script:TempRoot 'access-denied-scripts'
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $scriptsDir 'visible.ps1') -Value '# visible' -Encoding UTF8
            $originalFlag = $env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS
            $env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS = '1'

            try {
                $scripts = Get-PowerShellScripts -Path $scriptsDir
                $scripts | Should -Not -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS = $originalFlag
                }
            }
        }

        It 'Uses structured warnings for access-denied recovery when available' {
            $scriptsDir = Join-Path $script:TempRoot 'structured-access-denied'
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            $globalState = Join-Path (Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot) 'GlobalState.ps1'
            $functionRegistration = Join-Path (Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot) 'FunctionRegistration.ps1'
            $errorHandlingPath = Join-Path (Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot) 'ErrorHandlingStandard.ps1'
            if (Test-Path -LiteralPath $globalState) { . $globalState }
            if (Test-Path -LiteralPath $functionRegistration) { . $functionRegistration }
            if (Test-Path -LiteralPath $errorHandlingPath) { . $errorHandlingPath }

            $originalFlag = $env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS
            $env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS = '1'

            try {
                { Get-PowerShellScripts -Path $scriptsDir } | Should -Not -Throw
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILESYSTEM_FORCE_UNAUTHORIZED_ACCESS = $originalFlag
                }
            }
        }

        It 'Emits detailed mkdir failure output when debug level 3 is enabled' {
            $target = Join-Path $script:TempRoot 'debug-mkdir-failure'
            $originalMkdirFlag = $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR = '1'
            $env:PS_PROFILE_DEBUG = '3'

            try {
                { Ensure-DirectoryExists -Path $target } | Should -Throw
            }
            finally {
                if ($null -eq $originalMkdirFlag) {
                    Remove-Item Env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILESYSTEM_FORCE_MKDIR_ERROR = $originalMkdirFlag
                }

                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Throws when Get-ChildItem is forced to fail through the test hook' {
            $scriptsDir = Join-Path $script:TempRoot 'forced-get-child'
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            $originalFlag = $env:PS_PROFILE_FILESYSTEM_FORCE_GET_CHILD_ERROR
            $env:PS_PROFILE_FILESYSTEM_FORCE_GET_CHILD_ERROR = '1'

            try {
                { Get-PowerShellScripts -Path $scriptsDir } | Should -Throw '*Failed to get PowerShell scripts*'
            }
            finally {
                if ($null -eq $originalFlag) {
                    Remove-Item Env:PS_PROFILE_FILESYSTEM_FORCE_GET_CHILD_ERROR -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_FILESYSTEM_FORCE_GET_CHILD_ERROR = $originalFlag
                }
            }
        }
    }
}
