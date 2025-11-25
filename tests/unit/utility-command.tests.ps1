#
# Command availability helper tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
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