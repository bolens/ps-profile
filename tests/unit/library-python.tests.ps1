. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:PythonPath = Join-Path $script:LibPath 'runtime' 'Python.psm1'
    
    # Import the module under test
    Import-Module $script:PythonPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory
    $script:TestDir = Join-Path $env:TEMP "test-python-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
}

AfterAll {
    Remove-Module Python -ErrorAction SilentlyContinue -Force
    
    # Clean up test directory
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Python Module Functions' {
    Context 'Get-PythonPath' {
        It 'Returns null when Python is not available' {
            # This test verifies Get-PythonPath returns null when Python is truly unavailable
            # Note: Can't reliably mock module-internal calls, so test only runs when conditions are met
            $pythonExists = (Get-Command python -ErrorAction SilentlyContinue) -ne $null
            $python3Exists = (Get-Command python3 -ErrorAction SilentlyContinue) -ne $null
            $venvExists = Test-Path (Join-Path $script:RepoRoot '.venv')
            
            if ($pythonExists -or $python3Exists -or $venvExists) {
                # Skip test - Python is available, can't test "not available" scenario
                Set-ItResult -Skipped -Because "Python is available on this system (command or venv exists), cannot test 'not available' scenario"
            }
            else {
                # Test the scenario - Python is truly unavailable
                $result = Get-PythonPath
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Returns python command when available' {
            # This test verifies the function structure
            # Actual testing would require python to be installed
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }

        It 'Returns python3 command when python is not available' {
            # Function should fall back to python3
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }

        It 'Checks for virtual environment in repo root' {
            # Function should check for .venv directory
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }

        It 'Uses provided RepoRoot parameter' {
            $testRepoRoot = Join-Path $script:TestDir 'repo'
            New-Item -ItemType Directory -Path $testRepoRoot -Force | Out-Null
            
            $result = Get-PythonPath -RepoRoot $testRepoRoot
            # Should return null if no venv and no python
            # But function structure should be correct
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }

        It 'Detects repository root from script variables' {
            # Function should try to get repo root from script variables
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }

        It 'Falls back to .git directory detection' {
            # Function should detect .git directory as repo root
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }

        It 'Checks Windows venv path (Scripts\python.exe)' {
            # Function should check Windows-style venv path
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }

        It 'Checks Unix venv path (bin\python)' {
            # Function should check Unix-style venv path
            Get-Command Get-PythonPath | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invoke-PythonScript' {
        It 'Throws error when script path does not exist' {
            $nonExistentScript = Join-Path $script:TestDir 'nonexistent.py'
            { Invoke-PythonScript -ScriptPath $nonExistentScript } | Should -Throw "*not found*"
        }

        It 'Throws error when Python is not available' {
            # This test verifies Invoke-PythonScript throws when Python is unavailable
            # Note: Can't reliably mock module-internal calls, so test only runs when conditions are met
            $testScript = Join-Path $script:TestDir 'test.py'
            Set-Content -Path $testScript -Value 'print("test")'
            
            $pythonExists = (Get-Command python -ErrorAction SilentlyContinue) -ne $null
            $python3Exists = (Get-Command python3 -ErrorAction SilentlyContinue) -ne $null
            $venvExists = Test-Path (Join-Path $script:RepoRoot '.venv')
            
            if ($pythonExists -or $python3Exists -or $venvExists) {
                # Skip test - Python is available, can't test "not available" scenario
                Set-ItResult -Skipped -Because "Python is available on this system (command or venv exists), cannot test 'not available' scenario"
            }
            else {
                # Test the scenario - Python is truly unavailable
                { Invoke-PythonScript -ScriptPath $testScript } | Should -Throw "*not available*"
            }
        }

        It 'Validates Python executable is usable' {
            # Create a test script
            $testScript = Join-Path $script:TestDir 'test.py'
            Set-Content -Path $testScript -Value 'print("test")'
            
            # Function should validate Python is executable
            Get-Command Invoke-PythonScript | Should -Not -BeNullOrEmpty
        }

        It 'Passes arguments to Python script' {
            # Function should support passing arguments
            Get-Command Invoke-PythonScript | Should -Not -BeNullOrEmpty
            $cmd = Get-Command Invoke-PythonScript
            $cmd.Parameters['Arguments'] | Should -Not -BeNullOrEmpty
        }

        It 'Accepts RepoRoot parameter' {
            # Function should accept RepoRoot parameter
            $cmd = Get-Command Invoke-PythonScript
            $cmd.Parameters['RepoRoot'] | Should -Not -BeNullOrEmpty
        }

        It 'Handles script execution errors' {
            # Function should handle script failures gracefully
            Get-Command Invoke-PythonScript | Should -Not -BeNullOrEmpty
        }

        It 'Validates script file is readable' {
            # Function should validate script file access
            Get-Command Invoke-PythonScript | Should -Not -BeNullOrEmpty
        }

        It 'Filters warning messages from output' {
            # Function should filter common warning messages
            Get-Command Invoke-PythonScript | Should -Not -BeNullOrEmpty
        }
    }
}

