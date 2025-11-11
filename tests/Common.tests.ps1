<#
tests/Common.tests.ps1

Unit tests for Common.psm1 module functions.
#>

BeforeAll {
    # Import the Common module
    $commonModulePath = Join-Path $PSScriptRoot '..' 'scripts' 'lib' 'Common.psm1'
    Import-Module $commonModulePath -ErrorAction Stop
}

Describe 'Get-RepoRoot' {
    It 'Returns repository root for scripts/utils/ location' {
        # Use an actual script path that exists - resolve it first
        $relativePath = Join-Path $PSScriptRoot '..' 'scripts' 'utils' 'run-lint.ps1'
        $actualScriptPath = if (Test-Path $relativePath) {
            (Resolve-Path $relativePath).Path
        }
        else {
            # Try constructing absolute path
            $scriptsUtilsDir = (Resolve-Path (Join-Path $PSScriptRoot '..' 'scripts' 'utils')).Path
            Join-Path $scriptsUtilsDir 'run-lint.ps1'
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

    It 'Returns repository root for scripts/checks/ location' {
        # Use an actual script path that exists - resolve it first
        $relativePath = Join-Path $PSScriptRoot '..' 'scripts' 'checks' 'check-script-standards.ps1'
        $actualScriptPath = if (Test-Path $relativePath) {
            (Resolve-Path $relativePath).Path
        }
        else {
            # Try constructing absolute path
            $scriptsChecksDir = (Resolve-Path (Join-Path $PSScriptRoot '..' 'scripts' 'checks')).Path
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

    It 'Throws error for invalid script path' {
        { Get-RepoRoot -ScriptPath 'C:\Invalid\Path\script.ps1' } | Should -Throw
    }
}

Describe 'Get-ProfileDirectory' {
    It 'Returns profile.d directory path' {
        $testScriptPath = Join-Path $PSScriptRoot '..' 'scripts' 'utils' 'test.ps1'
        $profileDir = Get-ProfileDirectory -ScriptPath $testScriptPath
        $profileDir | Should -Be (Join-Path (Get-RepoRoot -ScriptPath $testScriptPath) 'profile.d')
    }
}

Describe 'Get-PowerShellScripts' {
    It 'Returns PowerShell script files' {
        $testDir = Join-Path $PSScriptRoot '..' 'scripts' 'utils'
        $scripts = Get-PowerShellScripts -Path $testDir
        $scripts | Should -Not -BeNullOrEmpty
        $scripts | ForEach-Object { $_.Extension | Should -Be '.ps1' }
    }

    It 'Sorts by name when SortByName is specified' {
        $testDir = Join-Path $PSScriptRoot '..' 'scripts' 'utils'
        $scripts = Get-PowerShellScripts -Path $testDir -SortByName
        $scriptNames = $scripts | ForEach-Object { $_.Name }
        $sortedNames = $scriptNames | Sort-Object
        $scriptNames | Should -Be $sortedNames
    }

    It 'Throws error for non-existent path' {
        { Get-PowerShellScripts -Path 'C:\Invalid\Path' } | Should -Throw
    }
}

Describe 'Resolve-DefaultPath' {
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

    It 'Throws error when provided path does not exist' {
        $defaultPath = 'C:\Default\Path'
        { Resolve-DefaultPath -Path 'C:\Invalid\Path' -DefaultPath $defaultPath } | Should -Throw
    }
}

Describe 'Test-PathExists' {
    It 'Returns true for existing file' {
        $testFile = Join-Path $PSScriptRoot 'Common.tests.ps1'
        $result = Test-PathExists -Path $testFile -PathType 'File'
        $result | Should -Be $true
    }

    It 'Returns true for existing directory' {
        $result = Test-PathExists -Path $PSScriptRoot -PathType 'Directory'
        $result | Should -Be $true
    }

    It 'Throws error for non-existent path' {
        { Test-PathExists -Path 'C:\Invalid\Path' } | Should -Throw
    }

    It 'Throws error when path exists but wrong type (file vs directory)' {
        $testFile = Join-Path $PSScriptRoot 'Common.tests.ps1'
        { Test-PathExists -Path $testFile -PathType 'Directory' } | Should -Throw
    }
}

Describe 'Test-CommandAvailable' {
    It 'Returns true for available command' {
        $result = Test-CommandAvailable -CommandName 'Get-Command'
        $result | Should -Be $true
    }

    It 'Returns false for unavailable command' {
        $result = Test-CommandAvailable -CommandName 'NonExistentCommand12345'
        $result | Should -Be $false
    }
}

Describe 'Get-PowerShellExecutable' {
    It 'Returns executable name' {
        $result = Get-PowerShellExecutable
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeIn @('pwsh', 'powershell')
    }
}

Describe 'Exit Code Constants' {
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

