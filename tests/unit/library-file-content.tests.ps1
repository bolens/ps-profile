. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:FileContentPath = Join-Path $script:LibPath 'file' 'FileContent.psm1'
    
    # Import the module under test
    Import-Module $script:FileContentPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory and files
    $script:TestDir = Join-Path $env:TEMP "test-file-content-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    # Create test file
    $script:TestFile = Join-Path $script:TestDir 'test.txt'
    $testContent = @'
Line 1
Line 2
Line 3
'@
    Set-Content -Path $script:TestFile -Value $testContent -Encoding UTF8
    
    # Create empty file
    $script:EmptyFile = Join-Path $script:TestDir 'empty.txt'
    Set-Content -Path $script:EmptyFile -Value '' -Encoding UTF8
}

AfterAll {
    Remove-Module FileContent -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FileContent Module Functions' {
    Context 'Read-FileContent' {
        It 'Reads file content successfully' {
            $result = Read-FileContent -Path $script:TestFile
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Line 1'
            $result | Should -Match 'Line 2'
        }

        It 'Returns empty string for non-existent file by default' {
            $nonExistentFile = Join-Path $script:TestDir 'nonexistent.txt'
            $result = Read-FileContent -Path $nonExistentFile
            $result | Should -Be ''
        }

        It 'Throws error for non-existent file when ErrorAction is Stop' {
            $nonExistentFile = Join-Path $script:TestDir 'nonexistent.txt'
            { Read-FileContent -Path $nonExistentFile -ErrorAction Stop } | Should -Throw "*not found*"
        }

        It 'Reads empty file successfully' {
            $result = Read-FileContent -Path $script:EmptyFile
            $result | Should -Be ''
        }

        It 'Returns empty string on read error by default' {
            # Create a file that might cause read issues (directory instead of file)
            $testDir = Join-Path $script:TestDir 'subdir'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            # Try to read directory as file (should fail gracefully)
            $result = Read-FileContent -Path $testDir
            $result | Should -Be ''
        }

        It 'Throws error on read error when ErrorAction is Stop' {
            $testDir = Join-Path $script:TestDir 'subdir2'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            { Read-FileContent -Path $testDir -ErrorAction Stop } | Should -Throw
        }

        It 'Reads file with special characters' {
            $specialFile = Join-Path $script:TestDir 'special.txt'
            $specialContent = "Test with special chars: @#$%^&*()"
            Set-Content -Path $specialFile -Value $specialContent -Encoding UTF8
            
            $result = Read-FileContent -Path $specialFile
            $result | Should -Match '@#\$%'
        }

        It 'Reads file with newlines' {
            $result = Read-FileContent -Path $script:TestFile
            $result | Should -Match "`n"
        }

        It 'Uses SilentlyContinue by default' {
            $nonExistentFile = Join-Path $script:TestDir 'nonexistent2.txt'
            $result = Read-FileContent -Path $nonExistentFile
            # Should not throw, should return empty string
            $result | Should -Be ''
        }
    }

    Context 'Read-FileContentOrNull' {
        It 'Reads file content successfully' {
            $result = Read-FileContentOrNull -Path $script:TestFile
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'Line 1'
        }

        It 'Returns null for non-existent file' {
            $nonExistentFile = Join-Path $script:TestDir 'nonexistent.txt'
            $result = Read-FileContentOrNull -Path $nonExistentFile
            $result | Should -BeNullOrEmpty
        }

        It 'Returns null for empty file' {
            $result = Read-FileContentOrNull -Path $script:EmptyFile
            $result | Should -BeNullOrEmpty
        }

        It 'Returns null for whitespace-only file' {
            $whitespaceFile = Join-Path $script:TestDir 'whitespace.txt'
            Set-Content -Path $whitespaceFile -Value '   ' -Encoding UTF8
            
            $result = Read-FileContentOrNull -Path $whitespaceFile
            $result | Should -BeNullOrEmpty
        }

        It 'Returns content for file with content' {
            $result = Read-FileContentOrNull -Path $script:TestFile
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }

        It 'Handles read errors gracefully' {
            $testDir = Join-Path $script:TestDir 'subdir3'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            
            $result = Read-FileContentOrNull -Path $testDir
            $result | Should -BeNullOrEmpty
        }
    }
}

