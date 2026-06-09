# ===============================================
# profile-bootstrap-error-handling-standard-extended.tests.ps1
# Execution tests for bootstrap/ErrorHandlingStandard.ps1 behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:BootstrapDir = Join-Path $script:ProfileDir 'bootstrap'
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

Describe 'profile.d/bootstrap/ErrorHandlingStandard.ps1 extended scenarios' {
    It 'Registers wide event and structured error helpers' {
        Get-Command Write-WideEvent -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-WithWideEvent -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-StructuredError -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Invoke-WithWideEvent executes the supplied script block' {
        $result = Invoke-WithWideEvent -OperationName 'test.bootstrap.wide-event' -ScriptBlock {
            return 'wide-event-ok'
        }

        $result | Should -Be 'wide-event-ok'
    }

    It 'Skips re-initialization when error-handling-standard is already loaded' {
        $firstInvoke = Get-Command Invoke-WithWideEvent -ErrorAction Stop

        . (Join-Path $script:BootstrapDir 'ErrorHandlingStandard.ps1')

        (Get-Command Invoke-WithWideEvent -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInvoke.ScriptBlock.ToString()
    }
}
