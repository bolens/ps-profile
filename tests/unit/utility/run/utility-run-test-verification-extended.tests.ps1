<#
tests/unit/utility-run-test-verification-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-test-verification.ps1 verification orchestrator.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:VerificationScript = Join-Path $script:TestRepoRoot 'scripts/utils/test-verification/run-test-verification.ps1'
}

Describe 'run-test-verification.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Phase Suite Category and GenerateReport parameters' {
            $content = Get-Content -LiteralPath $script:VerificationScript -Raw
            $content | Should -Match '\.PARAMETER Phase'
            $content | Should -Match '\.PARAMETER Suite'
            $content | Should -Match '\.PARAMETER Category'
            $content | Should -Match 'GenerateReport'
        }
    }

    Context 'Verification phases' {
        It 'Defines phased verification workflow functions' {
            $content = Get-Content -LiteralPath $script:VerificationScript -Raw
            $content | Should -Match 'function Invoke-Phase1'
            $content | Should -Match 'Phase6'
        }

        It 'Uses TestPhase and TestSuite enums from CommonEnums' {
            $content = Get-Content -LiteralPath $script:VerificationScript -Raw
            $content | Should -Match '\[TestPhase\]'
            $content | Should -Match '\[TestSuite\]'
        }
    }

    Context 'Reporting' {
        It 'Supports optional verification report generation' {
            $content = Get-Content -LiteralPath $script:VerificationScript -Raw
            $content | Should -Match 'GenerateReport'
        }
    }
}
