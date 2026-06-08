<#
tests/unit/test-runner-output-sanitizer-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for OutputSanitizer path rewriting.
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
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
}

Describe 'OutputSanitizer extended scenarios' {
    Context 'Convert-TestOutputLine' {
        It 'Rewrites absolute repository paths to relative paths' {
            $absolute = Join-Path $script:TestRepoRoot 'tests/unit/library/common/library-common.tests.ps1'
            $line = "Running test file $absolute"

            $converted = Convert-TestOutputLine -Text $line

            $converted | Should -Not -Match [regex]::Escape($script:TestRepoRoot)
            $converted | Should -Match 'tests/unit/library-common\.tests\.ps1'
        }

        It 'Rewrites quoted paths inside output lines' {
            $absolute = Join-Path $script:TestRepoRoot 'profile.d/11-git.ps1'
            $line = "Loaded fragment from '$absolute'"

            $converted = Convert-TestOutputLine -Text $line

            $converted | Should -Match "'profile\.d/11-git\.ps1'"
        }

        It 'Leaves null or whitespace lines unchanged' {
            Convert-TestOutputLine -Text $null | Should -BeNullOrEmpty
            Convert-TestOutputLine -Text '   ' | Should -Be '   '
        }

        It 'Leaves lines without repository paths unchanged' {
            $line = 'Tests completed: Passed=3, Failed=0, Skipped=0'
            Convert-TestOutputLine -Text $line | Should -Be $line
        }
    }
}
