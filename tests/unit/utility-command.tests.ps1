#
# Command availability helper tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import the Command module
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'utilities' 'Command.psm1') -DisableNameChecking -ErrorAction Stop -Global
}

Describe 'Test-CommandAvailable' {
    Context 'General behavior' {
        It 'Returns false for commands that do not exist' {
            $commandName = 'NonExistentCommand_{0}' -f ([System.Guid]::NewGuid().ToString())
            $result = Test-CommandAvailable -CommandName $commandName
            $result | Should -Be $false
        }

        It 'Caches command availability results between calls' {
            $commandName = 'TestCommand_{0}' -f ([System.Guid]::NewGuid().ToString())

            $first = Test-CommandAvailable -CommandName $commandName
            $second = Test-CommandAvailable -CommandName $commandName

            $first | Should -Be $second
        }
    }
}