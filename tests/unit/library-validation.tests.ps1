. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:ValidationPath = Join-Path $script:LibPath 'core' 'Validation.psm1'
    
    # Import the module under test
    Import-Module $script:ValidationPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module Validation -ErrorAction SilentlyContinue -Force
}

Describe 'Validation Module Functions' {
    Context 'Test-ValidString' {
        It 'Returns true for valid strings' {
            Test-ValidString -Value 'test' | Should -Be $true
            Test-ValidString -Value 'hello world' | Should -Be $true
            Test-ValidString -Value '123' | Should -Be $true
        }

        It 'Returns false for null values' {
            Test-ValidString -Value $null | Should -Be $false
        }

        It 'Returns false for empty strings' {
            Test-ValidString -Value '' | Should -Be $false
        }

        It 'Returns false for whitespace-only strings' {
            Test-ValidString -Value '   ' | Should -Be $false
            Test-ValidString -Value "`t`n`r" | Should -Be $false
        }

        It 'Converts non-string objects to string' {
            Test-ValidString -Value 123 | Should -Be $true
            Test-ValidString -Value (Get-Date) | Should -Be $true
        }

        It 'Handles empty string conversion' {
            $emptyObj = [string]::Empty
            Test-ValidString -Value $emptyObj | Should -Be $false
        }
    }

    Context 'Test-ValidPath' {
        BeforeEach {
            $script:TestDir = Join-Path $TestDrive 'TestValidation'
            $script:TestFile = Join-Path $script:TestDir 'test.txt'
            New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
            New-Item -ItemType File -Path $script:TestFile -Force | Out-Null
        }

        AfterEach {
            Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Returns true for existing file paths' {
            Test-ValidPath -Path $script:TestFile -PathType File | Should -Be $true
        }

        It 'Returns true for existing directory paths' {
            Test-ValidPath -Path $script:TestDir -PathType Directory | Should -Be $true
        }

        It 'Returns false for non-existent paths' {
            Test-ValidPath -Path (Join-Path $script:TestDir 'nonexistent.txt') | Should -Be $false
        }

        It 'Returns false for null paths' {
            Test-ValidPath -Path $null | Should -Be $false
        }

        It 'Returns false for empty string paths' {
            Test-ValidPath -Path '' | Should -Be $false
        }

        It 'Returns false for whitespace-only paths' {
            Test-ValidPath -Path '   ' | Should -Be $false
        }

        It 'Validates path type correctly' {
            Test-ValidPath -Path $script:TestFile -PathType File | Should -Be $true
            Test-ValidPath -Path $script:TestFile -PathType Directory | Should -Be $false
            Test-ValidPath -Path $script:TestDir -PathType Directory | Should -Be $true
            Test-ValidPath -Path $script:TestDir -PathType File | Should -Be $false
        }

        It 'Returns true for valid path strings without checking existence when MustExist is false' {
            $validPath = 'C:\temp\file.txt'
            Test-ValidPath -Path $validPath -MustExist:$false | Should -Be $true
        }

        It 'Accepts FileInfo and DirectoryInfo objects' {
            $fileInfo = Get-Item $script:TestFile
            $dirInfo = Get-Item $script:TestDir
            
            Test-ValidPath -Path $fileInfo -PathType File | Should -Be $true
            Test-ValidPath -Path $dirInfo -PathType Directory | Should -Be $true
        }
    }

    Context 'Assert-ValidPath' {
        BeforeEach {
            $script:TestDir = Join-Path $TestDrive 'TestAssert'
            $script:TestFile = Join-Path $script:TestDir 'test.txt'
            New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
            New-Item -ItemType File -Path $script:TestFile -Force | Out-Null
        }

        AfterEach {
            Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'Does not throw for valid paths' {
            { Assert-ValidPath -Path $script:TestFile } | Should -Not -Throw
            { Assert-ValidPath -Path $script:TestDir -PathType Directory } | Should -Not -Throw
        }

        It 'Throws for invalid paths' {
            { Assert-ValidPath -Path (Join-Path $script:TestDir 'nonexistent.txt') } | Should -Throw
        }

        It 'Throws for null paths' {
            { Assert-ValidPath -Path $null } | Should -Throw
        }

        It 'Includes parameter name in error message' {
            try {
                Assert-ValidPath -Path $null -ParameterName 'ConfigFile'
            }
            catch {
                $_.Exception.Message | Should -Match 'Parameter.*ConfigFile'
            }
        }

        It 'Uses custom error message when provided' {
            $customMessage = 'Custom error message'
            try {
                Assert-ValidPath -Path $null -ErrorMessage $customMessage
            }
            catch {
                $_.Exception.Message | Should -Be $customMessage
            }
        }

        It 'Includes path type in error message' {
            try {
                Assert-ValidPath -Path $script:TestFile -PathType Directory
            }
            catch {
                $_.Exception.Message | Should -Match 'Directory'
            }
        }
    }

    Context 'Assert-ValidString' {
        It 'Does not throw for valid strings' {
            { Assert-ValidString -Value 'test' } | Should -Not -Throw
            { Assert-ValidString -Value 'hello world' } | Should -Not -Throw
        }

        It 'Throws for null values' {
            { Assert-ValidString -Value $null } | Should -Throw
        }

        It 'Throws for empty strings' {
            { Assert-ValidString -Value '' } | Should -Throw
        }

        It 'Throws for whitespace-only strings' {
            { Assert-ValidString -Value '   ' } | Should -Throw
        }

        It 'Includes parameter name in error message' {
            try {
                Assert-ValidString -Value $null -ParameterName 'Name'
            }
            catch {
                $_.Exception.Message | Should -Match 'Parameter.*Name'
            }
        }

        It 'Uses custom error message when provided' {
            $customMessage = 'Custom validation error'
            try {
                Assert-ValidString -Value $null -ErrorMessage $customMessage
            }
            catch {
                $_.Exception.Message | Should -Be $customMessage
            }
        }
    }
}

