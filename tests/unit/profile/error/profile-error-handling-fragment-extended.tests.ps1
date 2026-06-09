# ===============================================
# profile-error-handling-fragment-extended.tests.ps1
# Execution tests for error-handling.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-ErrorHandlingFragmentState {
    Remove-Variable -Name 'ErrorHandlingLoaded' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/error-handling.ps1 extended scenarios' {
    BeforeEach {
        Reset-ErrorHandlingFragmentState
    }

    It 'Loads enhanced error handling commands from diagnostics-error-handling module' {
        . (Join-Path $script:ProfileDir 'error-handling.ps1')

        Get-Command Write-ProfileError -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-SafeFragmentLoad -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-ProfileErrorHandler -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Variable -Name 'ErrorHandlingLoaded' -Scope Global -ErrorAction Stop).Value | Should -Be $true
    }

    It 'Skips re-initialization when error handling is already loaded' {
        . (Join-Path $script:ProfileDir 'error-handling.ps1')
        $firstHandler = Get-Command Write-ProfileError -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'error-handling.ps1')

        (Get-Command Write-ProfileError -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstHandler.ScriptBlock.ToString()
    }

    It 'Write-ProfileError accepts structured error records after fragment load' {
        $env:PS_PROFILE_DEBUG = '1'
        try {
            . (Join-Path $script:ProfileDir 'error-handling.ps1')

                        throw 'error-handling fragment test failure'
        }
        catch {
            { Write-ProfileError -ErrorRecord $_ -Context 'Fragment test' -Category 'Fragment' } |
                Should -Not -Throw
        }
        finally {
            $env:PS_PROFILE_DEBUG = $null
        }
    }
}
