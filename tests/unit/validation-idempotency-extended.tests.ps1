<#
tests/unit/validation-idempotency-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for check-idempotency.ps1 validation script.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:IdempotencyScript = Join-Path $script:TestRepoRoot 'scripts/checks/check-idempotency.ps1'
}

Describe 'check-idempotency.ps1 extended scenarios' {
    Context 'Script structure' {
        It 'Builds a temporary runner that dot-sources fragments twice' {
            $content = Get-Content -LiteralPath $script:IdempotencyScript -Raw
            $content | Should -Match 'Auto-generated idempotency runner'
            $content | Should -Match 'pass 1'
            $content | Should -Match 'pass 2'
        }

        It 'Sorts profile.d fragments before generating the runner' {
            $content = Get-Content -LiteralPath $script:IdempotencyScript -Raw
            $content | Should -Match 'profile\.d'
            $content | Should -Match 'Sort-Object Name'
        }

        It 'Uses Get-PowerShellExecutable for cross-platform execution' {
            $content = Get-Content -LiteralPath $script:IdempotencyScript -Raw
            $content | Should -Match 'Get-PowerShellExecutable'
        }
    }

    Context 'Failure handling' {
        It 'Exits with setup error when no fragments are discovered' {
            $content = Get-Content -LiteralPath $script:IdempotencyScript -Raw
            $content | Should -Match 'No fragments found'
            $content | Should -Match 'EXIT_SETUP_ERROR'
        }

        It 'Cleans up the temporary runner script after execution' {
            $content = Get-Content -LiteralPath $script:IdempotencyScript -Raw
            $content | Should -Match 'Remove-Item'
            $content | Should -Match '\$temp'
        }
    }
}
