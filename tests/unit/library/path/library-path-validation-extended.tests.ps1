<#
tests/unit/library-path-validation-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Resolve-DefaultPath enum and whitespace edge cases.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'path' 'PathValidation.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'PathValidationExtended'
    $script:TestFile = Join-Path $script:TempDir 'sample.txt'
    $script:TestSubDir = Join-Path $script:TempDir 'nested'

    New-Item -ItemType Directory -Path $script:TestSubDir -Force | Out-Null
    Set-Content -LiteralPath $script:TestFile -Value 'sample' -Encoding UTF8
}

AfterAll {
    Remove-Module PathValidation, FileSystem -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PathValidation extended scenarios' {
    Context 'Resolve-DefaultPath' {
        It 'Validates files using the FileSystemPathType enum' {
            $result = Resolve-DefaultPath -Path $script:TestFile -DefaultPath $script:TempDir -PathType ([FileSystemPathType]::File)

            $result | Should -Be $script:TestFile
        }

        It 'Validates directories using the FileSystemPathType enum' {
            $result = Resolve-DefaultPath -Path $script:TestSubDir -DefaultPath $script:TestFile -PathType ([FileSystemPathType]::Directory)

            $result | Should -Be $script:TestSubDir
        }

        It 'Returns the default path for tab-only input' {
            $result = Resolve-DefaultPath -Path "`t" -DefaultPath $script:TempDir

            $result | Should -Be $script:TempDir
        }

        It 'Prefers the provided path when it exists alongside a valid default' {
            $result = Resolve-DefaultPath -Path $script:TestFile -DefaultPath $script:TestSubDir

            $result | Should -Be $script:TestFile
        }

        It 'Throws when the provided path is missing even if the default exists' {
            $missingPath = Join-Path $script:TempDir 'missing.txt'

            { Resolve-DefaultPath -Path $missingPath -DefaultPath $script:TempDir } | Should -Throw '*does not exist*'
        }
    }
}
