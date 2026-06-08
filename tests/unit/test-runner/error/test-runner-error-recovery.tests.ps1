<#
tests/unit/test-runner-error-recovery.tests.ps1

.SYNOPSIS
    Unit tests for TestErrorRecovery module.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestErrorRecovery.psm1') -Force -Global

    function script:Get-RecoveryExecutionResult {
        param(
            [scriptblock]$ScriptBlock,
            [int]$MaxRecoveryAttempts = 3,
            [scriptblock[]]$RecoveryActions
        )

        $output = @(Invoke-WithErrorRecovery -ScriptBlock $ScriptBlock -MaxRecoveryAttempts $MaxRecoveryAttempts -RecoveryActions $RecoveryActions)
        $matches = @($output | Where-Object { $_ -is [hashtable] -and $_.ContainsKey('Success') })
        if ($matches.Count -eq 0) {
            return $null
        }

        return $matches[-1]
    }
}

Describe 'TestErrorRecovery Module' {
    Context 'Invoke-WithErrorRecovery' {
        It 'Returns success on first attempt' {
            $result = Get-RecoveryExecutionResult -ScriptBlock { 'ok' }

            $result.Success | Should -Be $true
            $result.Result | Should -Be 'ok'
            $result.Attempts | Should -Be 1
        }

        It 'Retries after recovery actions succeed' {
            $script:attemptCounter = 0

            $result = Get-RecoveryExecutionResult -ScriptBlock {
                $script:attemptCounter++
                if ($script:attemptCounter -lt 2) {
                    throw 'transient failure'
                }

                return 'recovered'
            } -MaxRecoveryAttempts 2 -RecoveryActions @({ })

            $result.Success | Should -Be $true
            $result.Result | Should -Be 'recovered'
            $result.Attempts | Should -Be 2
            @($result.RecoveryHistory).Count | Should -Be 1
        }

        It 'Returns failure details when recovery is exhausted' {
            $result = Get-RecoveryExecutionResult -ScriptBlock {
                throw 'persistent failure'
            } -MaxRecoveryAttempts 1 -RecoveryActions @({ })

            $result.Success | Should -Be $false
            $result.Result | Should -BeNullOrEmpty
            $result.LastException | Should -Not -BeNullOrEmpty
            @($result.RecoveryHistory).Count | Should -BeGreaterThan 0
        }
    }
}
