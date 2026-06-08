<#
tests/unit/test-runner-output-utils-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for OutputPathUtils and OutputSanitizer helpers.
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

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    Initialize-OutputUtils -RepoRoot $script:RepoRoot
}

Describe 'OutputUtils extended scenarios' {
    Context 'Initialize-OutputUtils and Get-RepoRootPattern' {
        It 'Exposes an escaped repository root pattern' {
            $pattern = Get-RepoRootPattern

            $pattern | Should -Not -BeNullOrEmpty
            $pattern | Should -Be ([regex]::Escape($script:RepoRoot.TrimEnd('/', '\')))
        }
    }

    Context 'ConvertTo-RepoRelativePath' {
        It 'Returns whitespace input unchanged' {
            ConvertTo-RepoRelativePath -PathString '   ' | Should -Be '   '
        }

        It 'Returns the original path when repository root is not initialized' {
            Initialize-OutputUtils -RepoRoot $null
            $external = '/tmp/outside-repo/sample.txt'

            try {
                ConvertTo-RepoRelativePath -PathString $external | Should -Be $external
            }
            finally {
                Initialize-OutputUtils -RepoRoot $script:RepoRoot
            }
        }
    }

    Context 'Convert-TestOutputLine' {
        It 'Returns empty and whitespace lines unchanged' {
            Convert-TestOutputLine -Text '' | Should -Be ''
            Convert-TestOutputLine -Text '   ' | Should -Be '   '
        }

        It 'Sanitizes forward-slash repository paths' {
            $unixPath = "$($script:RepoRoot -replace '\\', '/')/tests/unit/sample.tests.ps1"
            $sanitized = Convert-TestOutputLine -Text "Failed in $unixPath"

            $sanitized | Should -Not -Match [regex]::Escape($script:RepoRoot)
            ($sanitized -replace '\\', '/') | Should -Match 'tests/unit/sample\.tests\.ps1'
        }
    }
}
