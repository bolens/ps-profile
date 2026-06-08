<#
tests/unit/library-validation-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Validation path type and string edge cases.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'core' 'Validation.psm1') -DisableNameChecking -Force

    $script:TempRoot = New-TestTempDirectory -Prefix 'ValidationExtended'
}

AfterAll {
    Remove-Module Validation -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Validation extended scenarios' {
    Context 'Test-ValidPath' {
        It 'Accepts directories when PathType is Any' {
            $directory = Join-Path $script:TempRoot 'any-type-dir'
            New-Item -ItemType Directory -Path $directory -Force | Out-Null

            Test-ValidPath -Path $directory -PathType Any | Should -Be $true
        }

        It 'Rejects files when PathType is Directory' {
            $file = Join-Path $script:TempRoot 'file-only.txt'
            Set-Content -LiteralPath $file -Value 'data' -Encoding UTF8

            Test-ValidPath -Path $file -PathType Directory | Should -Be $false
        }

        It 'Rejects directories when PathType is File' {
            $directory = Join-Path $script:TempRoot 'not-a-file'
            New-Item -ItemType Directory -Path $directory -Force | Out-Null

            Test-ValidPath -Path $directory -PathType File | Should -Be $false
        }
    }

    Context 'Test-ValidString' {
        It 'Rejects strings that contain only whitespace' {
            Test-ValidString -Value "`t  `r`n" | Should -Be $false
        }

        It 'Accepts strings with internal whitespace' {
            Test-ValidString -Value 'hello world' | Should -Be $true
        }
    }

    Context 'Assert-ValidPath' {
        It 'Throws when validating a file as a directory' {
            $file = Join-Path $script:TempRoot 'assert-file.txt'
            Set-Content -LiteralPath $file -Value 'x' -Encoding UTF8

            { Assert-ValidPath -Path $file -PathType Directory } | Should -Throw '*Directory*'
        }
    }
}
