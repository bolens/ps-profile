<#
tests/unit/test-runner-validate-function-naming-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for validate-function-naming.ps1 validation workflow.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:NamingScript = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/validate-function-naming.ps1'
    $script:TempRoot = New-TestTempDirectory -Prefix 'ValidateNamingExtended'
}

Describe 'validate-function-naming.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Path and OutputPath parameters' {
            $content = Get-Content -LiteralPath $script:NamingScript -Raw
            $content | Should -Match '\.PARAMETER Path'
            $content | Should -Match '\.PARAMETER OutputPath'
            $content | Should -Match '\.PARAMETER ExceptionsFile'
        }

        It 'Imports FunctionNamingValidator and ValidationReporter modules' {
            $content = Get-Content -LiteralPath $script:NamingScript -Raw
            $content | Should -Match 'FunctionNamingValidator\.psm1'
            $content | Should -Match 'ValidationReporter\.psm1'
        }
    }

    Context 'Validation execution' {
        It 'Exits successfully when scanning an empty temporary directory' {
            $emptyDir = Join-Path $script:TempRoot 'empty-scan'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            & pwsh -NoProfile -NonInteractive -File $script:NamingScript -Path $emptyDir 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Writes JSON output when OutputPath is specified' {
            $scanDir = Join-Path $script:TempRoot 'report-scan'
            $reportPath = Join-Path $script:TempRoot 'naming-report.json'
            New-Item -ItemType Directory -Path $scanDir -Force | Out-Null
            $sampleFile = Join-Path $scanDir 'Sample.ps1'
            Set-Content -LiteralPath $sampleFile -Value @'
function Get-SampleNamingTest {
    return $true
}
'@

            & pwsh -NoProfile -NonInteractive -File $script:NamingScript -Path $scanDir -OutputPath $reportPath 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
            Test-Path -LiteralPath $reportPath | Should -Be $true
        }

        It 'Uses EXIT_VALIDATION_FAILURE when validation issues are found' {
            $content = Get-Content -LiteralPath $script:NamingScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
            $content | Should -Match 'results\.Issues\.Count'
        }
    }
}
