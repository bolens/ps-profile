<#
tests/common.tests.ps1

Unit tests for Common.psm1 module functions.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import the Common module
    $commonModulePath = Get-TestPath -RelativePath 'scripts\lib\Common.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop
}

Describe 'Get-RepoRoot' {
    Context 'Valid script path handling' {
        It 'Returns repository root for scripts/utils/ location' {
            # Find an existing utility script dynamically to keep the test resilient
            $searchRoot = Get-TestPath -RelativePath 'scripts' -StartPath $PSScriptRoot -EnsureExists
            $candidate = Get-ChildItem -Path $searchRoot -Filter 'run-lint.ps1' -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1

            $candidate | Should -Not -BeNullOrEmpty -Because 'run-lint.ps1 should exist within scripts/utilities'

            $repoRoot = Get-RepoRoot -ScriptPath $candidate.FullName
            $repoRoot | Should -Exist
            # Verify it's actually the repo root by checking for common files/directories
            (Test-Path (Join-Path $repoRoot 'profile.d')) | Should -Be $true
            (Test-Path (Join-Path $repoRoot 'scripts')) | Should -Be $true
            (Test-Path (Join-Path $repoRoot 'README.md')) | Should -Be $true
        }

        It 'Returns repository root for scripts/checks/ location' {
            # Use an actual script path that exists - resolve it first
            $relativePath = Get-TestPath -RelativePath 'scripts\checks\check-script-standards.ps1' -StartPath $PSScriptRoot
            $actualScriptPath = if (Test-Path $relativePath) {
                (Resolve-Path $relativePath).Path
            }
            else {
                # Try constructing absolute path
                $scriptsChecksDir = Get-TestPath -RelativePath 'scripts\checks' -StartPath $PSScriptRoot -EnsureExists
                Join-Path $scriptsChecksDir 'check-script-standards.ps1'
            }

            if (Test-Path $actualScriptPath) {
                $repoRoot = Get-RepoRoot -ScriptPath $actualScriptPath
                $repoRoot | Should -Exist
                # Verify it's actually the repo root by checking for common files/directories
                (Test-Path (Join-Path $repoRoot 'profile.d')) | Should -Be $true
                (Test-Path (Join-Path $repoRoot 'scripts')) | Should -Be $true
                (Test-Path (Join-Path $repoRoot 'README.md')) | Should -Be $true
            }
            else {
                Set-ItResult -Skipped -Because "Test script not found at $actualScriptPath"
            }
        }
    }

    Context 'Error handling' {
        It 'Throws error for invalid script path' {
            { Get-RepoRoot -ScriptPath 'C:\Invalid\Path\script.ps1' } | Should -Throw
        }
    }
}

Describe 'Get-ProfileDirectory' {
    Context 'General behavior' {
        It 'Returns profile.d directory path' {
            $testScriptPath = Get-TestPath -RelativePath 'scripts\utils\test.ps1' -StartPath $PSScriptRoot
            $profileDir = Get-ProfileDirectory -ScriptPath $testScriptPath
            $profileDir | Should -Be (Join-Path (Get-RepoRoot -ScriptPath $testScriptPath) 'profile.d')
        }
    }
}

Describe 'Get-PowerShellScripts' {
    Context 'Listing scripts' {
        It 'Returns PowerShell script files' {
            $testDir = Get-TestPath -RelativePath 'scripts\utils' -StartPath $PSScriptRoot -EnsureExists
            $scripts = Get-PowerShellScripts -Path $testDir
            $scripts | Should -Not -BeNullOrEmpty
            $scripts | ForEach-Object { $_.Extension | Should -Be '.ps1' }
        }

        It 'Sorts by name when SortByName is specified' {
            $testDir = Get-TestPath -RelativePath 'scripts\utils' -StartPath $PSScriptRoot -EnsureExists
            $scripts = Get-PowerShellScripts -Path $testDir -SortByName
            $scriptNames = $scripts | ForEach-Object { $_.Name }
            $sortedNames = $scriptNames | Sort-Object
            $scriptNames | Should -Be $sortedNames
        }
    }

    Context 'Error handling' {
        It 'Throws error for non-existent path' {
            { Get-PowerShellScripts -Path 'C:\Invalid\Path' } | Should -Throw
        }
    }
}

Describe 'Resolve-DefaultPath' {
    Context 'Default resolution' {
        It 'Returns default path when Path is null' {
            $defaultPath = 'C:\Default\Path'
            $result = Resolve-DefaultPath -Path $null -DefaultPath $defaultPath
            $result | Should -Be $defaultPath
        }

        It 'Returns default path when Path is empty' {
            $defaultPath = 'C:\Default\Path'
            $result = Resolve-DefaultPath -Path '' -DefaultPath $defaultPath
            $result | Should -Be $defaultPath
        }

        It 'Returns provided path when Path is specified' {
            $testPath = $PSScriptRoot
            $defaultPath = 'C:\Default\Path'
            $result = Resolve-DefaultPath -Path $testPath -DefaultPath $defaultPath
            # Resolve-DefaultPath validates and returns the path
            $result | Should -Be $testPath
            $result | Should -Exist
        }
    }

    Context 'Error handling' {
        It 'Throws error when provided path does not exist' {
            $defaultPath = 'C:\Default\Path'
            { Resolve-DefaultPath -Path 'C:\Invalid\Path' -DefaultPath $defaultPath } | Should -Throw
        }
    }
}

Describe 'Test-PathExists' {
    Context 'Valid inputs' {
        It 'Returns true for existing file' {
            $testFile = Join-Path $PSScriptRoot 'common.tests.ps1'
            $result = Test-PathExists -Path $testFile -PathType 'File'
            $result | Should -Be $true
        }

        It 'Returns true for existing directory' {
            $result = Test-PathExists -Path $PSScriptRoot -PathType 'Directory'
            $result | Should -Be $true
        }
    }

    Context 'Error handling' {
        It 'Throws error for non-existent path' {
            { Test-PathExists -Path 'C:\Invalid\Path' } | Should -Throw
        }

        It 'Throws error when path exists but wrong type (file vs directory)' {
            $testFile = Join-Path $PSScriptRoot 'common.tests.ps1'
            { Test-PathExists -Path $testFile -PathType 'Directory' } | Should -Throw
        }
    }
}

Describe 'Test-CommandAvailable' {
    Context 'Command availability checks' {
        It 'Returns true for available command' {
            $result = Test-CommandAvailable -CommandName 'Get-Command'
            $result | Should -Be $true
        }

        It 'Returns false for unavailable command' {
            $result = Test-CommandAvailable -CommandName 'NonExistentCommand12345'
            $result | Should -Be $false
        }
    }
}

Describe 'Get-PowerShellExecutable' {
    Context 'General behavior' {
        It 'Returns executable name' {
            $result = Get-PowerShellExecutable
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeIn @('pwsh', 'powershell')
        }
    }
}

Describe 'Exit Code Constants' {
    Context 'Exports constants' {
        It 'Exports EXIT_SUCCESS constant' {
            $EXIT_SUCCESS | Should -Be 0
        }

        It 'Exports EXIT_VALIDATION_FAILURE constant' {
            $EXIT_VALIDATION_FAILURE | Should -Be 1
        }

        It 'Exports EXIT_SETUP_ERROR constant' {
            $EXIT_SETUP_ERROR | Should -Be 2
        }

        It 'Exports EXIT_OTHER_ERROR constant' {
            $EXIT_OTHER_ERROR | Should -Be 3
        }
    }
}


