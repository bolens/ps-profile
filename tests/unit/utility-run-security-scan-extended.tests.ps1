<#
tests/unit/utility-run-security-scan-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for run-security-scan.ps1 security analysis script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SecurityScript = Join-Path $script:TestRepoRoot 'scripts/utils/security/run-security-scan.ps1'
}

Describe 'run-security-scan.ps1 extended scenarios' {
    Context 'Comment-based help' {
        It 'Documents Path and AllowlistFile parameters' {
            $content = Get-Content -LiteralPath $script:SecurityScript -Raw
            $content | Should -Match '\.PARAMETER Path'
            $content | Should -Match '\.PARAMETER AllowlistFile'
        }
    }

    Context 'Security analysis' {
        It 'Uses Invoke-SecurityScan with allowlist filtering' {
            $content = Get-Content -LiteralPath $script:SecurityScript -Raw
            $content | Should -Match 'Invoke-SecurityScan'
            $content | Should -Match 'Allowlist'
        }
    }

    Context 'Exit code handling' {
        It 'Exits with validation failure when security findings remain' {
            $content = Get-Content -LiteralPath $script:SecurityScript -Raw
            $content | Should -Match 'EXIT_VALIDATION_FAILURE'
        }

        It 'Defaults scan path to profile.d via Get-ProfileDirectory' {
            $content = Get-Content -LiteralPath $script:SecurityScript -Raw
            $content | Should -Match 'Get-ProfileDirectory'
        }
    }
}
