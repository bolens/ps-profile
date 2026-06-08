<#
tests/unit/test-runner-recovery.tests.ps1

.SYNOPSIS
    Unit tests for TestRecovery module.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -DisableNameChecking -Force -Global
    Import-Module (Join-Path $modulePath 'TestRecovery.psm1') -Force -Global

    function script:Get-RecoveryActionResult {
        param([Exception]$Exception)
        $output = @(Invoke-TestExecutionRecovery -Exception $Exception)
        $matches = @($output | Where-Object { $_ -is [hashtable] -and $_.ContainsKey('Action') })
        if ($matches.Count -eq 0) {
            return $null
        }

        return $matches[0]
    }
}

Describe 'TestRecovery Module' {
    Context 'Invoke-TestExecutionRecovery' {
        It 'Suggests retry for file lock errors' {
            $ex = [Exception]::new('Cannot access the file because it is being used by another process')
            $result = Get-RecoveryActionResult -Exception $ex

            $result.Action | Should -Be 'Retry'
            $result.Message | Should -Match 'file lock'
        }

        It 'Suggests retry for network errors' {
            $ex = [Exception]::new('Network connection failed unexpectedly')
            $result = Get-RecoveryActionResult -Exception $ex

            $result.Action | Should -Be 'Retry'
            $result.Message | Should -Match 'network'
        }

        It 'Suggests retry after memory pressure' {
            $ex = [Exception]::new('Out of memory while allocating buffer')
            $result = Get-RecoveryActionResult -Exception $ex

            $result.Action | Should -Be 'Retry'
            $result.Message | Should -Match 'garbage collection'
        }

        It 'Fails fast on permission errors' {
            $ex = [Exception]::new('Access denied to protected resource')
            $result = Get-RecoveryActionResult -Exception $ex

            $result.Action | Should -Be 'Fail'
            $result.Message | Should -Match 'Permission'
        }

        It 'Returns null for unrecognized errors' {
            $ex = [Exception]::new('Some completely unknown failure mode')
            Get-RecoveryActionResult -Exception $ex | Should -BeNullOrEmpty
        }
    }
}
