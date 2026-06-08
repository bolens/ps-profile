<#
tests/unit/test-runner-performance-monitoring-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-TestExecutionWithPerformance fallback behavior.
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
    Import-Module (Join-Path $modulePath 'TestPerformanceMonitoring.psm1') -Force -Global
}

Describe 'TestPerformanceMonitoring extended scenarios' {
    Context 'Invoke-TestExecutionWithPerformance' {
        It 'Returns wrapped performance result for successful execution blocks' {
            $config = [pscustomobject]@{ Label = 'test-config' }
            $result = Invoke-TestExecutionWithPerformance -ExecutionScriptBlock {
                param($Cfg, $RunNumber, $TotalRuns)
                return @{
                    PassedCount = 3
                    FailedCount = 0
                    ConfigLabel = $Cfg.Label
                    RunNumber   = $RunNumber
                }
            } -Config $config -RunNumber 2 -TotalRuns 4

            $result.Result.PassedCount | Should -Be 3
            $result.Result.ConfigLabel | Should -Be 'test-config'
            $result.Result.RunNumber | Should -Be 2
            $result.Performance.Duration | Should -Not -BeNullOrEmpty
        }

        It 'Falls back to direct execution when performance wrapper returns invalid shape' {
            $config = [pscustomobject]@{ Label = 'fallback-config' }
            $script:fallbackAttempt = 0

            $result = Invoke-TestExecutionWithPerformance -ExecutionScriptBlock {
                param($Cfg, $RunNumber, $TotalRuns)
                $script:fallbackAttempt++
                if ($script:fallbackAttempt -eq 1) {
                    return $null
                }

                return @{ PassedCount = 2; FailedCount = 0 }
            } -Config $config

            $script:fallbackAttempt | Should -Be 2
            $result.PassedCount | Should -Be 2
        }

        It 'Rethrows when fallback execution also fails' {
            $config = [pscustomobject]@{ Label = 'error-config' }
            {
                Invoke-TestExecutionWithPerformance -ExecutionScriptBlock {
                    throw 'execution failed'
                } -Config $config
            } | Should -Throw '*execution failed*'
        }
    }
}
