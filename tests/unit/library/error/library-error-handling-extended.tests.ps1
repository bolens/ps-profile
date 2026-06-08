<#
tests/unit/library-error-handling-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ErrorHandling preference branches and rethrow behavior.
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
    Import-Module (Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/lib/core/ErrorHandling.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module ErrorHandling -ErrorAction SilentlyContinue -Force
}

Describe 'ErrorHandling extended scenarios' {
    Context 'Invoke-WithErrorHandling' {
        It 'Returns null when ErrorActionPreference is Ignore' {
            $result = Invoke-WithErrorHandling -ScriptBlock { throw 'ignored failure' } -ErrorActionPreference 'Ignore'

            $result | Should -BeNullOrEmpty
        }

        It 'Rethrows the original exception when no custom message is provided' {
            { Invoke-WithErrorHandling -ScriptBlock { throw 'original failure' } -ErrorActionPreference 'Stop' } |
                Should -Throw '*original failure*'
        }
    }

    Context 'Write-ErrorOrThrow' {
        It 'Does not throw when ErrorActionPreference is Ignore' {
            { Write-ErrorOrThrow -Message 'ignored message' -ErrorActionPreference 'Ignore' } | Should -Not -Throw
        }

        It 'Writes errors without throwing when ErrorActionPreference is Continue' {
            { Write-ErrorOrThrow -Message 'continued message' -ErrorActionPreference 'Continue' } | Should -Not -Throw
        }
    }

    Context 'Get-ErrorActionPreference' {
        It 'Returns SilentlyContinue when explicitly bound in PSBoundParameters' {
            $params = @{ ErrorAction = 'SilentlyContinue' }
            $result = Get-ErrorActionPreference -PSBoundParameters $params -Default 'Stop'

            $result | Should -Be 'SilentlyContinue'
        }
    }
}
