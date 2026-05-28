#
# Required parameter and exit code helper tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    # Test-RequiredParameters lives in FileSystem.psm1
    $fileSystemModulePath = Join-Path $repoRoot 'scripts' 'lib' 'file' 'FileSystem.psm1'
    if (Test-Path $fileSystemModulePath) {
        Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction Stop -Force
    }
    # Exit-WithCode lives in ExitCodes.psm1
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

        It 'Returns true when all parameters are valid' {
            $result = Test-RequiredParameters -Parameters @{ Name = 'ValidName'; Path = 'ValidPath' }
            $result | Should -Be $true
        }

        It 'Includes the parameter name in the error message' {
            { Test-RequiredParameters -Parameters @{ MyMissingParam = $null } } | Should -Throw '*MyMissingParam*'
        }
    }
}

Describe 'Exit-WithCode' {
    Context 'General behavior' {
        It 'Is exposed for scripts that rely on standardized exit handling' {
            Get-Command Exit-WithCode -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It 'Accepts an integer ExitCode parameter' {
            $cmd = Get-Command Exit-WithCode
            $cmd.Parameters['ExitCode'] | Should -Not -BeNullOrEmpty
        }

        It 'Accepts an optional Message parameter' {
            $cmd = Get-Command Exit-WithCode
            $cmd.Parameters['Message'] | Should -Not -BeNullOrEmpty
        }
    }
}
