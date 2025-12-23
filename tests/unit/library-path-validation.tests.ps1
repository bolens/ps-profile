. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:PathValidationPath = Join-Path $script:LibPath 'path' 'PathValidation.psm1'
    
    # Import FileSystem module first (dependency for Test-PathExists)
    $fileSystemPath = Join-Path $script:LibPath 'file' 'FileSystem.psm1'
    if (Test-Path $fileSystemPath) {
        Import-Module $fileSystemPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    Import-Module $script:PathValidationPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory and files
    $script:TestDir = Join-Path $env:TEMP "test-path-validation-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    $script:TestFile = Join-Path $script:TestDir 'test-file.txt'
    Set-Content -Path $script:TestFile -Value 'test content'
    
    $script:TestSubDir = Join-Path $script:TestDir 'subdir'
    New-Item -ItemType Directory -Path $script:TestSubDir -Force | Out-Null
}

AfterAll {
    Remove-Module PathValidation -ErrorAction SilentlyContinue -Force
    Remove-Module FileSystem -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PathValidation Module Functions' {
    Context 'Resolve-DefaultPath' {
        It 'Returns default path when Path is null' {
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path $null -DefaultPath $defaultPath
            $result | Should -Be $defaultPath
        }

        It 'Returns default path when Path is empty string' {
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path '' -DefaultPath $defaultPath
            $result | Should -Be $defaultPath
        }

        It 'Returns default path when Path is whitespace' {
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path '   ' -DefaultPath $defaultPath
            $result | Should -Be $defaultPath
        }

        It 'Returns provided path when it exists' {
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path $script:TestFile -DefaultPath $defaultPath
            $result | Should -Be $script:TestFile
        }

        It 'Validates provided path exists' {
            $defaultPath = $script:TestDir
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent.txt'
            { Resolve-DefaultPath -Path $nonExistentPath -DefaultPath $defaultPath } | Should -Throw "*not exist*"
        }

        It 'Validates file type when PathType is File' {
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path $script:TestFile -DefaultPath $defaultPath -PathType 'File'
            $result | Should -Be $script:TestFile
        }

        It 'Throws error if path is not a file when PathType is File' {
            $defaultPath = $script:TestDir
            { Resolve-DefaultPath -Path $script:TestSubDir -DefaultPath $defaultPath -PathType 'File' } | Should -Throw "*not a file*"
        }

        It 'Validates directory type when PathType is Directory' {
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path $script:TestSubDir -DefaultPath $defaultPath -PathType 'Directory'
            $result | Should -Be $script:TestSubDir
        }

        It 'Throws error if path is not a directory when PathType is Directory' {
            $defaultPath = $script:TestDir
            { Resolve-DefaultPath -Path $script:TestFile -DefaultPath $defaultPath -PathType 'Directory' } | Should -Throw "*not a directory*"
        }

        It 'Accepts Any path type by default' {
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path $script:TestFile -DefaultPath $defaultPath
            $result | Should -Be $script:TestFile
        }

        It 'Uses Test-PathExists when available' {
            # This test verifies the function uses Test-PathExists if available
            $defaultPath = $script:TestDir
            $result = Resolve-DefaultPath -Path $script:TestFile -DefaultPath $defaultPath
            $result | Should -Be $script:TestFile
        }

        It 'Falls back to Test-Path when Test-PathExists is not available' {
            # Temporarily remove Test-PathExists
            $originalTestPathExists = Get-Command Test-PathExists -ErrorAction SilentlyContinue
            if ($originalTestPathExists) {
                Remove-Item -Path Function:\Test-PathExists -Force -ErrorAction SilentlyContinue
            }
            
            try {
                $defaultPath = $script:TestDir
                $result = Resolve-DefaultPath -Path $script:TestFile -DefaultPath $defaultPath
                $result | Should -Be $script:TestFile
            }
            finally {
                if ($originalTestPathExists) {
                    Import-Module (Join-Path $script:LibPath 'file' 'FileSystem.psm1') -DisableNameChecking -ErrorAction SilentlyContinue -Force
                }
            }
        }
    }
}

