#
# Required parameter and exit code helper tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
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
