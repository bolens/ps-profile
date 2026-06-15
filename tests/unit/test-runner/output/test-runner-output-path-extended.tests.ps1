<#
tests/unit/test-runner-output-path-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for OutputPathUtils and OutputSanitizer edge cases.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'OutputSanitizer.psm1') -Force -Global

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TempDir = New-TestTempDirectory -Prefix 'OutputPathExtended'
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'Output path utilities extended scenarios' {
    Context 'ConvertTo-RepoRelativePath' {
        It 'Returns whitespace input unchanged' {
            ConvertTo-RepoRelativePath -PathString '   ' | Should -Be '   '
            ConvertTo-RepoRelativePath -PathString '' | Should -Be ''
        }

        It 'Returns unresolved paths when repository root is not initialized' {
            try {
            Initialize-OutputUtils -RepoRoot $null
            $external = '/tmp/not-in-repo/example.txt'

                        ConvertTo-RepoRelativePath -PathString $external | Should -Be $external
            }
            finally {
                Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
            }
        }
    }

    Context 'Get-RepoRootPattern' {
        It 'Returns escaped repository root pattern after initialization' {
            $pattern = Get-RepoRootPattern
            $expected = [regex]::Escape($script:TestRepoRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar))

            $pattern | Should -Be $expected
        }
    }

    Context 'Convert-TestOutputLine' {
        It 'Returns whitespace-only lines unchanged' {
            Convert-TestOutputLine -Text '   ' | Should -Be '   '
            Convert-TestOutputLine -Text '' | Should -Be ''
        }

        It 'Rewrites nested quoted paths inside a log line' {
            $nested = Join-Path $script:TestRepoRoot 'tests/unit/nested.tests.ps1'
            $line = "Error at '$nested' in block"

            $sanitized = Convert-TestOutputLine -Text $line

            $sanitized | Should -Not -Match [regex]::Escape($script:TestRepoRoot)
            ($sanitized -replace '\\', '/') | Should -Match "'tests/unit/nested\.tests\.ps1'"
        }
    }
}
