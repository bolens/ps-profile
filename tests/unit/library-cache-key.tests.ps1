<#
.SYNOPSIS
    Unit tests for CacheKey.psm1 module.

.DESCRIPTION
    Tests for cache key generation functions including New-CacheKey, New-FileCacheKey,
    and New-DirectoryCacheKey.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' '..' 'scripts' 'lib' 'utilities' 'CacheKey.psm1'
    Import-Module $modulePath -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module CacheKey -ErrorAction SilentlyContinue
}

Describe 'New-CacheKey' {
    It 'Generates a simple cache key with prefix and single component' {
        $key = New-CacheKey -Prefix 'Test' -Components 'Value'
        $key | Should -Be 'Test_Value'
    }

    It 'Generates a cache key with multiple components' {
        $key = New-CacheKey -Prefix 'LibPath' -Components 'scripts', 'lib', 'ModuleImport.psm1'
        $key | Should -Be 'LibPath_scripts_lib_ModuleImport_psm1'
    }

    It 'Handles path separators correctly' {
        $key = New-CacheKey -Prefix 'RepoRoot' -Components 'C:\Users\bolen\Documents\PowerShell'
        $key | Should -Be 'RepoRoot_C_Users_bolen_Documents_PowerShell'
    }

    It 'Sanitizes invalid characters' {
        $key = New-CacheKey -Prefix 'Test' -Components 'Value with spaces & special chars!'
        $key | Should -Match '^Test_Value'
        $key | Should -Not -Match '[^a-zA-Z0-9_]'
    }

    It 'Handles empty components' {
        $key = New-CacheKey -Prefix 'Test' -Components 'Value', '', 'Another'
        $key | Should -Be 'Test_Value_Another'
    }

    It 'Handles null components' {
        $key = New-CacheKey -Prefix 'Test' -Components 'Value', $null, 'Another'
        $key | Should -Be 'Test_Value_Another'
    }

    It 'Returns only prefix when no valid components provided' {
        $key = New-CacheKey -Prefix 'Test' -Components '', $null
        $key | Should -Be 'Test'
    }

    It 'Uses custom separator' {
        $key = New-CacheKey -Prefix 'Test' -Components 'Value', 'Another' -Separator '-'
        $key | Should -Be 'Test-Value-Another'
    }

    It 'Handles prefix with special characters' {
        $key = New-CacheKey -Prefix 'Test-Module' -Components 'Value'
        $key | Should -Match '^TestModule'
    }

    It 'Normalizes multiple consecutive separators' {
        $key = New-CacheKey -Prefix 'Test' -Components 'Value___Another'
        $key | Should -Not -Match '_{3,}'
    }
}

Describe 'New-FileCacheKey' {
    BeforeAll {
        $testFile = Join-Path $TestDrive 'test-file.txt'
        'Test content' | Out-File -FilePath $testFile -Encoding UTF8
    }

    It 'Generates a cache key from a file path' {
        $key = New-FileCacheKey -FilePath $testFile
        $key | Should -Match '^File_test_file_txt_\d+$'
    }

    It 'Uses custom prefix' {
        $key = New-FileCacheKey -FilePath $testFile -Prefix 'PowerShellDataFile'
        $key | Should -Match '^PowerShellDataFile_test_file_txt_\d+$'
    }

    It 'Includes file modification time in key' {
        $key1 = New-FileCacheKey -FilePath $testFile
        Start-Sleep -Milliseconds 10
        'Updated content' | Out-File -FilePath $testFile -Encoding UTF8
        $key2 = New-FileCacheKey -FilePath $testFile
        
        $key1 | Should -Not -Be $key2
    }

    It 'Generates different keys for different files' {
        $testFile2 = Join-Path $TestDrive 'test-file-2.txt'
        'Content' | Out-File -FilePath $testFile2 -Encoding UTF8
        
        $key1 = New-FileCacheKey -FilePath $testFile
        $key2 = New-FileCacheKey -FilePath $testFile2
        
        $key1 | Should -Not -Be $key2
    }

    It 'Throws error for non-existent file' {
        $nonExistentFile = Join-Path $TestDrive 'nonexistent.txt'
        { New-FileCacheKey -FilePath $nonExistentFile } | Should -Throw
    }

    It 'Throws error for empty file path' {
        { New-FileCacheKey -FilePath '' } | Should -Throw
    }

    It 'Uses hash when UseHash is specified' {
        $key = New-FileCacheKey -FilePath $testFile -UseHash
        $key | Should -Match '^File_.*_[a-f0-9]{64}$'
    }

    It 'Uses specified hash algorithm' {
        $key = New-FileCacheKey -FilePath $testFile -UseHash -HashAlgorithm 'MD5'
        $key | Should -Match '^File_.*_[a-f0-9]{32}$'
    }

    It 'Falls back to modification time if hash fails' {
        # This test verifies the fallback behavior
        # In practice, hash should work, but we test the error handling
        $key = New-FileCacheKey -FilePath $testFile -UseHash -HashAlgorithm 'InvalidAlgorithm'
        # Should still produce a valid key (fallback to ticks)
        $key | Should -Match '^File_.*_\d+$'
    }
}

Describe 'New-DirectoryCacheKey' {
    BeforeAll {
        $testDir = Join-Path $TestDrive 'test-dir'
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }

    It 'Generates a cache key from a directory path' {
        $key = New-DirectoryCacheKey -DirectoryPath $testDir
        $key | Should -Match '^Directory_.*test_dir$'
    }

    It 'Uses custom prefix' {
        $key = New-DirectoryCacheKey -DirectoryPath $testDir -Prefix 'RepoRoot'
        $key | Should -Match '^RepoRoot_.*test_dir$'
    }

    It 'Resolves relative paths' {
        $relativePath = '..'
        $key = New-DirectoryCacheKey -DirectoryPath $relativePath
        $key | Should -Match '^Directory_'
    }

    It 'Handles absolute paths' {
        $key = New-DirectoryCacheKey -DirectoryPath $testDir
        $key | Should -Not -BeNullOrEmpty
    }

    It 'Throws error for empty directory path' {
        { New-DirectoryCacheKey -DirectoryPath '' } | Should -Throw
    }

    It 'Handles non-existent directory gracefully' {
        $nonExistentDir = Join-Path $TestDrive 'nonexistent-dir'
        # Should not throw, but may resolve to a path
        $key = New-DirectoryCacheKey -DirectoryPath $nonExistentDir
        $key | Should -Not -BeNullOrEmpty
    }
}

Describe 'CacheKey Integration' {
    It 'Generates consistent keys for same inputs' {
        $key1 = New-CacheKey -Prefix 'Test' -Components 'Value'
        $key2 = New-CacheKey -Prefix 'Test' -Components 'Value'
        $key1 | Should -Be $key2
    }

    It 'Generates different keys for different inputs' {
        $key1 = New-CacheKey -Prefix 'Test' -Components 'Value1'
        $key2 = New-CacheKey -Prefix 'Test' -Components 'Value2'
        $key1 | Should -Not -Be $key2
    }

    It 'Works with real-world cache key patterns' {
        # Simulate ModuleImport.psm1 pattern
        $key = New-CacheKey -Prefix 'LibPath' -Components 'scripts\lib\ModuleImport.psm1'
        $key | Should -Be 'LibPath_scripts_lib_ModuleImport_psm1'

        # Simulate Command.psm1 pattern
        $key = New-CacheKey -Prefix 'CommandAvailable' -Components 'git'
        $key | Should -Be 'CommandAvailable_git'

        # Simulate PathResolution.psm1 pattern
        $key = New-CacheKey -Prefix 'RepoRoot' -Components 'C:\Users\bolen\Documents\PowerShell'
        $key | Should -Match '^RepoRoot_'
    }
}

Describe 'New-CacheKey Edge Cases' {
    It 'Handles nested arrays' {
        $nestedArray = @('inner1', 'inner2')
        $key = New-CacheKey -Prefix 'Test' -Components $nestedArray
        $key | Should -Be 'Test_inner1_inner2'
    }

    It 'Handles arrays within arrays' {
        $outerArray = @(@('a', 'b'), 'c')
        $key = New-CacheKey -Prefix 'Test' -Components $outerArray
        $key | Should -Be 'Test_a_b_c'
    }

    It 'Handles primitive numeric types' {
        $key = New-CacheKey -Prefix 'Test' -Components 123, 456
        $key | Should -Be 'Test_123_456'
    }

    It 'Handles boolean values' {
        $key = New-CacheKey -Prefix 'Test' -Components $true, $false
        $key | Should -Be 'Test_True_False'
    }

    It 'Handles whitespace-only components' {
        $key = New-CacheKey -Prefix 'Test' -Components '   ', 'Value', '   '
        $key | Should -Be 'Test_Value'
    }

    It 'Handles components that sanitize to empty' {
        $key = New-CacheKey -Prefix 'Test' -Components '!!!', 'Value', '###'
        $key | Should -Be 'Test_Value'
    }

    It 'Handles very long component strings' {
        $longString = 'a' * 1000
        $key = New-CacheKey -Prefix 'Test' -Components $longString
        $key | Should -Match '^Test_a+$'
        $key.Length | Should -BeLessThan 1100
    }

    It 'Handles components with only special characters' {
        $key = New-CacheKey -Prefix 'Test' -Components '!!!', '###', '$$$'
        $key | Should -Be 'Test'
    }

    It 'Handles mixed types in components' {
        $key = New-CacheKey -Prefix 'Test' -Components 'String', 123, $true
        $key | Should -Be 'Test_String_123_True'
    }

    It 'Handles empty prefix after sanitization' {
        # Prefix with only special chars should still work (gets sanitized)
        $key = New-CacheKey -Prefix '!!!' -Components 'Value'
        $key | Should -Match '^_Value$'
    }

    It 'Handles null Components parameter' {
        # When Components is explicitly null, PowerShell may bind it differently
        # Test that it doesn't throw and returns a valid key
        $key = New-CacheKey -Prefix 'Test' -Components $null -ErrorAction Stop
        $key | Should -Not -BeNullOrEmpty
        $key | Should -Match '^Test'
    }

    It 'Handles empty Components array' {
        $key = New-CacheKey -Prefix 'Test' -Components @()
        $key | Should -Be 'Test'
    }

    It 'Handles components with unicode characters' {
        $key = New-CacheKey -Prefix 'Test' -Components 'café', 'naïve'
        $key | Should -Match '^Test_café_naïve$'
    }

    It 'Handles components with newlines and tabs' {
        $key = New-CacheKey -Prefix 'Test' -Components "line1`nline2", "tab`tseparated"
        $key | Should -Not -Match '[\r\n\t]'
    }

    It 'Handles different separator characters' {
        $key = New-CacheKey -Prefix 'Test' -Components 'A', 'B' -Separator '|'
        $key | Should -Be 'Test|A|B'
    }

    It 'Handles separator with special characters' {
        $key = New-CacheKey -Prefix 'Test' -Components 'A', 'B' -Separator '---'
        $key | Should -Be 'Test---A---B'
    }

    It 'Handles ArrayList collection type' {
        $list = [System.Collections.ArrayList]::new()
        $list.Add('item1') | Out-Null
        $list.Add('item2') | Out-Null
        $key = New-CacheKey -Prefix 'Test' -Components $list
        $key | Should -Be 'Test_item1_item2'
    }

    It 'Handles generic List collection type' {
        $list = [System.Collections.Generic.List[string]]::new()
        $list.Add('item1')
        $list.Add('item2')
        $key = New-CacheKey -Prefix 'Test' -Components $list
        $key | Should -Be 'Test_item1_item2'
    }
}

Describe 'New-CacheKey Error Handling' {
    It 'Throws error for null prefix' {
        { New-CacheKey -Prefix $null -Components 'Value' } | Should -Throw
    }

    It 'Throws error for empty prefix' {
        { New-CacheKey -Prefix '' -Components 'Value' } | Should -Throw
    }

    It 'Throws error for whitespace-only prefix' {
        { New-CacheKey -Prefix '   ' -Components 'Value' } | Should -Throw
    }
}

Describe 'New-FileCacheKey Edge Cases' {
    BeforeAll {
        $testFile = Join-Path $TestDrive 'test-file.txt'
        'Test content' | Out-File -FilePath $testFile -Encoding UTF8
    }

    It 'Handles file with special characters in name' {
        $specialFile = Join-Path $TestDrive 'test-file (1).txt'
        'Content' | Out-File -FilePath $specialFile -Encoding UTF8
        $key = New-FileCacheKey -FilePath $specialFile
        # Parentheses are removed during sanitization, so we get test_file1_txt
        $key | Should -Match '^File_test_file1_txt_\d+$'
    }

    It 'Handles file with unicode characters in name' {
        $unicodeFile = Join-Path $TestDrive 'café-file.txt'
        'Content' | Out-File -FilePath $unicodeFile -Encoding UTF8
        $key = New-FileCacheKey -FilePath $unicodeFile
        $key | Should -Match '^File_café_file_txt_\d+$'
    }

    It 'Handles very long file names' {
        $longName = 'a' * 200 + '.txt'
        $longFile = Join-Path $TestDrive $longName
        'Content' | Out-File -FilePath $longFile -Encoding UTF8
        $key = New-FileCacheKey -FilePath $longFile
        $key | Should -Match '^File_.*_\d+$'
    }

    It 'Handles file with no extension' {
        $noExtFile = Join-Path $TestDrive 'testfile'
        'Content' | Out-File -FilePath $noExtFile -Encoding UTF8
        $key = New-FileCacheKey -FilePath $noExtFile
        $key | Should -Match '^File_testfile_\d+$'
    }

    It 'Handles file with multiple extensions' {
        $multiExtFile = Join-Path $TestDrive 'test.tar.gz'
        'Content' | Out-File -FilePath $multiExtFile -Encoding UTF8
        $key = New-FileCacheKey -FilePath $multiExtFile
        $key | Should -Match '^File_test_tar_gz_\d+$'
    }

    It 'Handles hash algorithm case insensitivity' {
        $key1 = New-FileCacheKey -FilePath $testFile -UseHash -HashAlgorithm 'sha256'
        $key2 = New-FileCacheKey -FilePath $testFile -UseHash -HashAlgorithm 'SHA256'
        $key1 | Should -Be $key2
    }

    It 'Handles different hash algorithms' {
        $key1 = New-FileCacheKey -FilePath $testFile -UseHash -HashAlgorithm 'MD5'
        $key2 = New-FileCacheKey -FilePath $testFile -UseHash -HashAlgorithm 'SHA256'
        $key1 | Should -Not -Be $key2
    }
}

Describe 'New-DirectoryCacheKey Edge Cases' {
    BeforeAll {
        $testDir = Join-Path $TestDrive 'test-dir'
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }

    It 'Handles directory with special characters in name' {
        $specialDir = Join-Path $TestDrive 'test-dir (1)'
        New-Item -ItemType Directory -Path $specialDir -Force | Out-Null
        $key = New-DirectoryCacheKey -DirectoryPath $specialDir
        # Parentheses are removed during sanitization, so we get test_dir1
        $key | Should -Match '^Directory_test_dir1$'
    }

    It 'Handles directory with unicode characters' {
        $unicodeDir = Join-Path $TestDrive 'café-dir'
        New-Item -ItemType Directory -Path $unicodeDir -Force | Out-Null
        $key = New-DirectoryCacheKey -DirectoryPath $unicodeDir
        $key | Should -Match '^Directory_café_dir$'
    }

    It 'Handles root directory path' {
        if ($IsWindows) {
            $key = New-DirectoryCacheKey -DirectoryPath 'C:\'
            $key | Should -Match '^Directory_'
        }
        else {
            $key = New-DirectoryCacheKey -DirectoryPath '/'
            $key | Should -Match '^Directory_'
        }
    }

    It 'Handles current directory' {
        $key = New-DirectoryCacheKey -DirectoryPath '.'
        $key | Should -Match '^Directory_'
        $key | Should -Not -BeNullOrEmpty
    }

    It 'Handles parent directory' {
        $key = New-DirectoryCacheKey -DirectoryPath '..'
        $key | Should -Match '^Directory_'
        $key | Should -Not -BeNullOrEmpty
    }

    It 'Handles very long directory names' {
        $longName = 'a' * 200
        $longDir = Join-Path $TestDrive $longName
        New-Item -ItemType Directory -Path $longDir -Force | Out-Null
        $key = New-DirectoryCacheKey -DirectoryPath $longDir
        $key | Should -Match '^Directory_.*a+$'
    }
}

