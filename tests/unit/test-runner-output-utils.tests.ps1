<#
tests/unit/OutputUtils.tests.ps1

.SYNOPSIS
    Tests for the OutputUtils module.
#>

BeforeAll {
    # Import test support
    . $PSScriptRoot/../TestSupport.ps1

    # Import the modules to test
    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterConfig.psm1') -Force
    # Import OutputUtils submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force
    Import-Module (Join-Path $modulePath 'OutputSanitizer.psm1') -Force
    Import-Module (Join-Path $modulePath 'OutputInterceptor.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -Force

    # Set up test repository root (two levels up from tests/unit)
    $script:TestRepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
}

Describe 'OutputUtils Module Tests' {
    Context 'ConvertTo-RepoRelativePath' {
        It 'Converts absolute paths to relative' {
            $absolutePath = Join-Path $script:TestRepoRoot 'tests/unit/library-common.tests.ps1'
            $relativePath = ConvertTo-RepoRelativePath -PathString $absolutePath

            $relativePath -replace '\\', '/' | Should -Be 'tests/unit/library-common.tests.ps1'
        }

        It 'Returns unchanged paths outside repository' {
            $externalPath = 'C:\external\path\file.txt'
            $result = ConvertTo-RepoRelativePath -PathString $externalPath

            $result | Should -Be $externalPath
        }
    }

    Context 'Convert-TestOutputLine' {
        It 'Sanitizes repository root paths' {
            $line = "Error in $script:TestRepoRoot\profile.d\function.ps1"
            $sanitized = Convert-TestOutputLine -Text $line

            $sanitized | Should -Not -Match [regex]::Escape($script:TestRepoRoot)
            $sanitized | Should -Match 'profile\.d\\function\.ps1'
        }

        It 'Sanitizes quoted paths' {
            $line = "File: '$script:TestRepoRoot\tests\unit\test.ps1'"
            $sanitized = Convert-TestOutputLine -Text $line

            $sanitized -replace '\\', '/' | Should -Match "'tests/unit/test\.ps1'"
        }
    }

    Context 'Output Interception' {
        It 'Start-TestOutputInterceptor and Stop-TestOutputInterceptor do not throw' {
            { Start-TestOutputInterceptor } | Should -Not -Throw
            { Stop-TestOutputInterceptor } | Should -Not -Throw
        }

        It 'Interceptor can wrap Write-Warning calls without throwing' {
            Start-TestOutputInterceptor

            try {
                { Write-Warning 'Duplicate warning message' } | Should -Not -Throw
                { Write-Warning 'Duplicate warning message' } | Should -Not -Throw
                { Write-Warning 'Unique warning message' } | Should -Not -Throw
            }
            finally {
                Stop-TestOutputInterceptor
            }
        }
    }
}
