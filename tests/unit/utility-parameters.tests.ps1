#
# Required parameter and exit code helper tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import ExitCodes module for Exit-WithCode
    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $exitCodesModulePath = Join-Path $repoRoot 'scripts' 'lib' 'core' 'ExitCodes.psm1'
    if (Test-Path $exitCodesModulePath) {
        Import-Module $exitCodesModulePath -DisableNameChecking -ErrorAction Stop
    }
}

Describe 'Test-RequiredParameters' {
    Context 'General behavior' {
        It 'Throws when parameter values are null' {
            { Test-RequiredParameters -Parameters @{ Name = $null } } | Should -Throw
        }

        It 'Throws when parameter values are empty strings' {
            { Test-RequiredParameters -Parameters @{ Name = '' } } | Should -Throw
        }

        It 'Throws when parameter values are whitespace' {
            { Test-RequiredParameters -Parameters @{ Name = '   ' } } | Should -Throw
        }

        It 'Succeeds when all parameters are valid' {
            { Test-RequiredParameters -Parameters @{ Name = 'ValidName'; Path = 'ValidPath' } } | Should -Not -Throw
        }
    }
}

Describe 'Exit-WithCode' {
    Context 'General behavior' {
        It 'Is exposed for scripts that rely on standardized exit handling' {
            Get-Command Exit-WithCode -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }
    }
}
