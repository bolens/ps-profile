<#
tests/unit/test-runner-recovery-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for TestRecovery edge cases.
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

Describe 'TestRecovery extended scenarios' {
    Context 'Invoke-TestExecutionRecovery' {
        It 'Retries generic network connection failures' {
            $ex = [Exception]::new('Connection reset by peer during remote call')
            $result = Get-RecoveryActionResult -Exception $ex

            $result.Action | Should -Be 'Retry'
            $result.Message | Should -Match 'network'
        }

        It 'Does not treat Pester test timeout messages as network failures' {
            $ex = [Exception]::new('Test timeout of 120 seconds exceeded for Describe block')
            Get-RecoveryActionResult -Exception $ex | Should -BeNullOrEmpty
        }

        It 'Fails fast for unauthorized access errors' {
            $ex = [Exception]::new('Unauthorized access to protected resource')
            $result = Get-RecoveryActionResult -Exception $ex

            $result.Action | Should -Be 'Fail'
            $result.Message | Should -Match 'Permission'
        }
    }
}
