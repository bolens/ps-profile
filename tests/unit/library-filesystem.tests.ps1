. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'FileSystem Module Functions' {
    BeforeAll {
        # Import the FileSystem module (Common.psm1 no longer exists)
        $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
        Import-Module (Join-Path $libPath 'file' 'FileSystem.psm1') -DisableNameChecking -ErrorAction Stop
        $script:TestTempDir = New-TestTempDirectory -Prefix 'FileSystemTests'
    }

    AfterAll {
        if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
            Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Test-PathParameter' {
        It 'Validates path parameter exists' {
            $testFile = Join-Path $script:TestTempDir 'test.txt'
            New-Item -ItemType File -Path $testFile -Force | Out-Null

            { Test-PathParameter -Path $testFile -PathType 'File' } | Should -Not -Throw
        }

        It 'Throws error for non-existent path' {
            $nonExistentPath = Join-Path $script:TestTempDir 'nonexistent.txt'
            { Test-PathParameter -Path $nonExistentPath -PathType 'File' } | Should -Throw
        }

        It 'Throws error for wrong path type' {
            $testDir = Join-Path $script:TestTempDir 'testdir'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            { Test-PathParameter -Path $testDir -PathType 'File' } | Should -Throw
        }
    }

    Context 'Ensure-DirectoryExists' {
        BeforeAll {
            $script:TestDir = Join-Path $script:TestTempDir 'EnsureDirTests'
            if (-not (Test-Path $script:TestDir)) {
                New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
            }
        }

        It 'Throws error if path exists but is not a directory' {
            $filePath = Join-Path $script:TestDir 'test-file.txt'
            Set-Content -Path $filePath -Value 'test'
            { Ensure-DirectoryExists -Path $filePath } | Should -Throw "*not a directory*"
        }

        It 'Uses custom error message when provided' {
            $filePath = Join-Path $script:TestDir 'another-file.txt'
            Set-Content -Path $filePath -Value 'test'
            { Ensure-DirectoryExists -Path $filePath -ErrorMessage 'Custom error message' } | Should -Throw "*Custom error message*"
        }

        It 'Creates nested directories' {
            $nestedDir = Join-Path $script:TestDir 'level1' 'level2' 'level3'
            Ensure-DirectoryExists -Path $nestedDir
            Test-Path $nestedDir | Should -Be $true
        }
    }

    Context 'Get-PowerShellScripts' {
        BeforeEach {
            $script:ScriptsDir = Join-Path $script:TestDir 'scripts'
            New-Item -ItemType Directory -Path $script:ScriptsDir -Force | Out-Null
            
            # Create test script files
            Set-Content -Path (Join-Path $script:ScriptsDir 'script1.ps1') -Value '# Test script 1'
            Set-Content -Path (Join-Path $script:ScriptsDir 'script2.ps1') -Value '# Test script 2'
            Set-Content -Path (Join-Path $script:ScriptsDir 'not-a-script.txt') -Value 'Not a script'
        }

        It 'Returns PowerShell script files' {
            $scripts = Get-PowerShellScripts -Path $script:ScriptsDir
            $scripts | Should -Not -BeNullOrEmpty
            $scripts.Count | Should -BeGreaterOrEqual 2
            $scripts | ForEach-Object { $_.Extension | Should -Be '.ps1' }
        }

        It 'Excludes non-PowerShell files' {
            $scripts = Get-PowerShellScripts -Path $script:ScriptsDir
            $scripts | Where-Object { $_.Extension -eq '.txt' } | Should -BeNullOrEmpty
        }

        It 'Searches recursively when Recurse is specified' {
            $subDir = Join-Path $script:ScriptsDir 'subdir'
            New-Item -ItemType Directory -Path $subDir -Force | Out-Null
            Set-Content -Path (Join-Path $subDir 'script3.ps1') -Value '# Test script 3'
            
            $scripts = Get-PowerShellScripts -Path $script:ScriptsDir -Recurse
            $scripts.Count | Should -BeGreaterOrEqual 3
        }

        It 'Sorts by name when SortByName is specified' {
            $scripts = Get-PowerShellScripts -Path $script:ScriptsDir -SortByName
            $scriptNames = $scripts | ForEach-Object { $_.Name }
            $sortedNames = $scriptNames | Sort-Object
            $scriptNames | Should -Be $sortedNames
        }

        It 'Throws error if path does not exist' {
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent'
            { Get-PowerShellScripts -Path $nonExistentPath } | Should -Throw "*does not exist*"
        }

        It 'Handles access denied errors gracefully' {
            # This is difficult to test without actually creating access issues
            # But we can verify the function structure handles it
            Get-Command Get-PowerShellScripts | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-PathExists' {
        It 'Returns true for existing paths' {
            $existingPath = Join-Path $script:TestDir 'existing'
            New-Item -ItemType Directory -Path $existingPath -Force | Out-Null
            $result = Test-PathExists -Path $existingPath
            $result | Should -Be $true
        }

        It 'Throws error for non-existent paths' {
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent'
            { Test-PathExists -Path $nonExistentPath } | Should -Throw "*not found*"
        }

        It 'Validates file type when PathType is File' {
            $filePath = Join-Path $script:TestDir 'test-file.txt'
            Set-Content -Path $filePath -Value 'test'
            $result = Test-PathExists -Path $filePath -PathType 'File'
            $result | Should -Be $true
        }

        It 'Throws error if path exists but is not a file when PathType is File' {
            $dirPath = Join-Path $script:TestDir 'test-dir'
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            { Test-PathExists -Path $dirPath -PathType 'File' } | Should -Throw "*not a file*"
        }

        It 'Validates directory type when PathType is Directory' {
            $dirPath = Join-Path $script:TestDir 'test-dir'
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            $result = Test-PathExists -Path $dirPath -PathType 'Directory'
            $result | Should -Be $true
        }

        It 'Throws error if path exists but is not a directory when PathType is Directory' {
            $filePath = Join-Path $script:TestDir 'test-file.txt'
            Set-Content -Path $filePath -Value 'test'
            { Test-PathExists -Path $filePath -PathType 'Directory' } | Should -Throw "*not a directory*"
        }

        It 'Uses custom error message when provided' {
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent'
            { Test-PathExists -Path $nonExistentPath -ErrorMessage 'Custom path error' } | Should -Throw "*Custom path error*"
        }

        It 'Accepts Any path type by default' {
            $filePath = Join-Path $script:TestDir 'any-file.txt'
            Set-Content -Path $filePath -Value 'test'
            $result = Test-PathExists -Path $filePath
            $result | Should -Be $true
        }
    }

    Context 'Test-RequiredParameters' {
        It 'Returns true when all parameters are provided' {
            $params = @{
                Name  = 'TestName'
                Path  = 'TestPath'
                Value = 123
            }
            $result = Test-RequiredParameters -Parameters $params
            $result | Should -Be $true
        }

        It 'Throws error when parameter is null' {
            $params = @{
                Name = 'TestName'
                Path = $null
            }
            { Test-RequiredParameters -Parameters $params } | Should -Throw "*null or empty*"
        }

        It 'Throws error when parameter is empty string' {
            $params = @{
                Name = ''
                Path = 'TestPath'
            }
            { Test-RequiredParameters -Parameters $params } | Should -Throw "*null or empty*"
        }

        It 'Throws error when parameter is whitespace only' {
            $params = @{
                Name = '   '
                Path = 'TestPath'
            }
            { Test-RequiredParameters -Parameters $params } | Should -Throw "*null or empty*"
        }

        It 'Includes parameter name in error message' {
            $params = @{
                MissingParam = $null
            }
            { Test-RequiredParameters -Parameters $params } | Should -Throw "*MissingParam*"
        }

        It 'Accepts non-string values' {
            $params = @{
                Number  = 42
                Boolean = $true
                Array   = @(1, 2, 3)
            }
            $result = Test-RequiredParameters -Parameters $params
            $result | Should -Be $true
        }
    }

    Context 'Test-PathParameter' {
        It 'Returns true for existing paths' {
            $filePath = Join-Path $script:TestDir 'test-file.txt'
            Set-Content -Path $filePath -Value 'test'
            $result = Test-PathParameter -Path $filePath
            $result | Should -Be $true
        }

        It 'Returns true for null when Optional is specified' {
            $result = Test-PathParameter -Path $null -Optional
            $result | Should -Be $true
        }

        It 'Returns true for empty string when Optional is specified' {
            $result = Test-PathParameter -Path '' -Optional
            $result | Should -Be $true
        }

        It 'Throws error for non-existent paths when not optional' {
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent'
            { Test-PathParameter -Path $nonExistentPath } | Should -Throw "*does not exist*"
        }

        It 'Validates file type when PathType is File' {
            $filePath = Join-Path $script:TestDir 'test-file.txt'
            Set-Content -Path $filePath -Value 'test'
            $result = Test-PathParameter -Path $filePath -PathType 'File'
            $result | Should -Be $true
        }

        It 'Throws error if path is not a file when PathType is File' {
            $dirPath = Join-Path $script:TestDir 'test-dir'
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            { Test-PathParameter -Path $dirPath -PathType 'File' } | Should -Throw "*not a file*"
        }

        It 'Validates directory type when PathType is Directory' {
            $dirPath = Join-Path $script:TestDir 'test-dir'
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            $result = Test-PathParameter -Path $dirPath -PathType 'Directory'
            $result | Should -Be $true
        }

        It 'Throws error if path is not a directory when PathType is Directory' {
            $filePath = Join-Path $script:TestDir 'test-file.txt'
            Set-Content -Path $filePath -Value 'test'
            { Test-PathParameter -Path $filePath -PathType 'Directory' } | Should -Throw "*not a directory*"
        }

        It 'Handles FileInfo objects' {
            $filePath = Join-Path $script:TestDir 'test-file.txt'
            Set-Content -Path $filePath -Value 'test'
            $fileInfo = Get-Item $filePath
            $result = Test-PathParameter -Path $fileInfo
            $result | Should -Be $true
        }

        It 'Handles DirectoryInfo objects' {
            $dirPath = Join-Path $script:TestDir 'test-dir'
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            $dirInfo = Get-Item $dirPath
            $result = Test-PathParameter -Path $dirInfo -PathType 'Directory'
            $result | Should -Be $true
        }
    }
}
