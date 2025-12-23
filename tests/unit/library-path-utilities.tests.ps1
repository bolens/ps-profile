. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:PathUtilitiesPath = Join-Path $script:LibPath 'path' 'PathUtilities.psm1'
    
    # Import the module under test
    Import-Module $script:PathUtilitiesPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory structure
    $script:TestDir = Join-Path $env:TEMP "test-path-utilities-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    $script:BaseDir = Join-Path $script:TestDir 'base'
    $script:TargetDir = Join-Path $script:TestDir 'target'
    $script:SubDir = Join-Path $script:BaseDir 'subdir'
    $script:TargetFile = Join-Path $script:TargetDir 'file.txt'
    
    New-Item -ItemType Directory -Path $script:BaseDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:TargetDir -Force | Out-Null
    New-Item -ItemType Directory -Path $script:SubDir -Force | Out-Null
    Set-Content -Path $script:TargetFile -Value 'test' -Force
}

AfterAll {
    Remove-Module PathUtilities -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PathUtilities Module Functions' {
    Context 'Get-RelativePath' {
        It 'Calculates relative path for file in subdirectory' {
            $relative = Get-RelativePath -From $script:BaseDir -To $script:TargetFile
            $relative | Should -Not -BeNullOrEmpty
            $relative | Should -BeOfType [string]
        }

        It 'Calculates relative path for directory' {
            $relative = Get-RelativePath -From $script:TestDir -To $script:TargetDir
            $relative | Should -Not -BeNullOrEmpty
        }

        It 'Handles same directory' {
            $relative = Get-RelativePath -From $script:BaseDir -To $script:BaseDir
            $relative | Should -Match '^\.'
        }

        It 'Handles paths with trailing separators' {
            $fromPath = "$script:BaseDir\"
            $toPath = "$script:TargetFile"
            $relative = Get-RelativePath -From $fromPath -To $toPath
            $relative | Should -Not -BeNullOrEmpty
        }

        It 'Handles non-existent paths' {
            $nonExistentFrom = Join-Path $script:TestDir 'nonexistent-from'
            $nonExistentTo = Join-Path $script:TestDir 'nonexistent-to'
            $relative = Get-RelativePath -From $nonExistentFrom -To $nonExistentTo
            $relative | Should -Not -BeNullOrEmpty
        }

        It 'Handles paths outside base directory' {
            $outsidePath = Join-Path $env:TEMP "outside-$(Get-Random)"
            $relative = Get-RelativePath -From $script:BaseDir -To $outsidePath
            $relative | Should -Not -BeNullOrEmpty
        }

        It 'Normalizes paths correctly' {
            $relative = Get-RelativePath -From $script:BaseDir -To $script:SubDir
            $relative | Should -Not -BeNullOrEmpty
        }
    }

    Context 'ConvertTo-RepoRelativePath' {
        It 'Converts absolute path to repository-relative path' {
            $targetPath = Join-Path $script:TestDir 'target' 'file.txt'
            $relative = ConvertTo-RepoRelativePath -Path $targetPath -RepoRoot $script:TestDir
            $relative | Should -Not -BeNullOrEmpty
            $relative | Should -Not -Match '^[A-Z]:\\'
        }

        It 'Returns original path when outside repository' {
            $outsidePath = Join-Path $env:TEMP "outside-$(Get-Random).txt"
            $relative = ConvertTo-RepoRelativePath -Path $outsidePath -RepoRoot $script:TestDir
            $relative | Should -Be $outsidePath
        }

        It 'Handles empty path' {
            $relative = ConvertTo-RepoRelativePath -Path '' -RepoRoot $script:TestDir
            $relative | Should -Be ''
        }

        It 'Handles whitespace path' {
            $relative = ConvertTo-RepoRelativePath -Path '   ' -RepoRoot $script:TestDir
            $relative | Should -Be '   '
        }

        It 'Handles null path' {
            $relative = ConvertTo-RepoRelativePath -Path $null -RepoRoot $script:TestDir
            $relative | Should -BeNullOrEmpty
        }

        It 'Normalizes trailing separators' {
            $targetPath = "$script:TestDir\target\file.txt"
            $repoRoot = "$script:TestDir\"
            $relative = ConvertTo-RepoRelativePath -Path $targetPath -RepoRoot $repoRoot
            $relative | Should -Not -BeNullOrEmpty
        }

        It 'Handles non-existent paths' {
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent.txt'
            $relative = ConvertTo-RepoRelativePath -Path $nonExistentPath -RepoRoot $script:TestDir
            $relative | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Normalize-Path' {
        It 'Normalizes path without RepoRoot' {
            $targetPath = Join-Path $script:TestDir 'target' 'file.txt'
            $normalized = Normalize-Path -Path $targetPath
            $normalized | Should -Not -BeNullOrEmpty
            $normalized | Should -BeOfType [string]
        }

        It 'Converts to repository-relative path when RepoRoot provided' {
            $targetPath = Join-Path $script:TestDir 'target' 'file.txt'
            $normalized = Normalize-Path -Path $targetPath -RepoRoot $script:TestDir
            $normalized | Should -Not -BeNullOrEmpty
            $normalized | Should -Not -Match '^[A-Z]:\\'
        }

        It 'Returns original path when RepoRoot not provided and path does not exist' {
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent.txt'
            $normalized = Normalize-Path -Path $nonExistentPath
            $normalized | Should -Be $nonExistentPath
        }

        It 'Handles empty path' {
            $normalized = Normalize-Path -Path ''
            $normalized | Should -Be ''
        }

        It 'Handles null path' {
            $normalized = Normalize-Path -Path $null
            $normalized | Should -BeNullOrEmpty
        }

        It 'Returns original path when outside repository' {
            $outsidePath = Join-Path $env:TEMP "outside-$(Get-Random).txt"
            $normalized = Normalize-Path -Path $outsidePath -RepoRoot $script:TestDir
            $normalized | Should -Be $outsidePath
        }

        It 'Resolves existing paths' {
            $targetPath = Join-Path $script:TestDir 'target' 'file.txt'
            $normalized = Normalize-Path -Path $targetPath
            $normalized | Should -Not -BeNullOrEmpty
            Test-Path $normalized | Should -Be $true
        }

        It 'Handles RepoRoot that does not exist' {
            $nonExistentRepoRoot = Join-Path $env:TEMP "nonexistent-repo-$(Get-Random)"
            $targetPath = Join-Path $script:TestDir 'target' 'file.txt'
            $normalized = Normalize-Path -Path $targetPath -RepoRoot $nonExistentRepoRoot
            # Should resolve path but not convert to relative
            $normalized | Should -Not -BeNullOrEmpty
        }
    }
}

