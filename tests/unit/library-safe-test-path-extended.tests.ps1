<#
tests/unit/library-safe-test-path-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for SafeTestPath null-safe path helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap\SafeTestPath.ps1' -StartPath $PSScriptRoot -EnsureExists
    . $bootstrapPath

    $script:TempDir = New-TestTempDirectory -Prefix 'SafeTestPathExtended'
    $script:ExistingFile = Join-Path $script:TempDir 'exists.txt'
    Set-Content -LiteralPath $script:ExistingFile -Value 'exists' -Encoding UTF8
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_DEBUG_TESTPATH -ErrorAction SilentlyContinue

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'SafeTestPath extended scenarios' {
    Context 'Test-NullSafePath' {
        It 'Returns false when PathType Leaf is used on a directory path' {
            Test-NullSafePath -Path $script:TempDir -PathType Leaf | Should -Be $false
        }

        It 'Returns false for whitespace-only paths' {
            Test-NullSafePath -Path '   ' | Should -Be $false
        }

        It 'Returns true for existing literal file paths' {
            Test-NullSafePath -LiteralPath $script:ExistingFile -PathType Leaf | Should -Be $true
        }

        It 'Returns false for missing literal paths' {
            $missing = Join-Path $script:TempDir 'missing-file.txt'
            Test-NullSafePath -LiteralPath $missing | Should -Be $false
        }
    }

    Context 'Trace-TestPath' {
        It 'Returns false and logs when the path is whitespace' {
            $env:PS_PROFILE_DEBUG_TESTPATH = '1'

            try {
                Trace-TestPath -Path '   ' | Should -Be $false
            }
            finally {
                Remove-Item Env:\PS_PROFILE_DEBUG_TESTPATH -ErrorAction SilentlyContinue
            }
        }

        It 'Delegates to Test-Path for valid existing paths' {
            Trace-TestPath -Path $script:TempDir -PathType Container | Should -Be $true
        }
    }
}
