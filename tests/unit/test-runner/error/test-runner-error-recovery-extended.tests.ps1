<#
tests/unit/test-runner-error-recovery-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-WithErrorRecovery retry behavior.
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
        if (@($matches).Count -eq 0) {
            return $null
        }

        return $matches[-1]
    }
}

Describe 'TestErrorRecovery extended scenarios' {
    Context 'Invoke-WithErrorRecovery' {
        It 'Fails immediately when MaxRecoveryAttempts is zero' {
            $result = Get-RecoveryExecutionResult -ScriptBlock {
                throw 'immediate failure'
            } -MaxRecoveryAttempts 0 -RecoveryActions @({ })

            $result.Success | Should -Be $false
            $result.Attempts | Should -Be 1
        }

        It 'Continues retrying when a recovery action throws' {
            $script:attemptCounter = 0

            $result = Get-RecoveryExecutionResult -ScriptBlock {
                $script:attemptCounter++
                if ($script:attemptCounter -lt 3) {
                    throw 'still failing'
                }

                return 'recovered-after-bad-action'
            } -MaxRecoveryAttempts 3 -RecoveryActions @(
                { throw 'recovery action failed' },
                { }
            )

            $result.Success | Should -Be $true
            $result.Result | Should -Be 'recovered-after-bad-action'
            $result.Attempts | Should -Be 3
        }

        It 'Records recovery history entries for each failed attempt' {
            $result = Get-RecoveryExecutionResult -ScriptBlock {
                throw 'always fails'
            } -MaxRecoveryAttempts 1 -RecoveryActions @({ })

            @($result.RecoveryHistory).Count | Should -Be 2
            $result.Attempts | Should -Be 2
            $result.RecoveryHistory[0].Attempt | Should -Be 1
            $result.RecoveryHistory[1].Attempt | Should -Be 2
        }

        It 'Returns complex result objects from the script block' {
            $payload = @{
                PassedCount = 4
                Tags        = @('Unit')
            }

            $result = Get-RecoveryExecutionResult -ScriptBlock { return $payload }

            $result.Success | Should -Be $true
            $result.Result.PassedCount | Should -Be 4
            $result.Result.Tags | Should -Contain 'Unit'
        }
    }
}
