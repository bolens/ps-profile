<#
tests/unit/library-command-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Command availability and install resolution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $cachePath = Join-Path $libPath 'utilities' 'Cache.psm1'

    if (Test-Path -LiteralPath $cachePath) {
        Import-Module $cachePath -DisableNameChecking -Force
    }

    Import-Module (Join-Path $libPath 'utilities' 'Command.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Command -ErrorAction SilentlyContinue -Force
    Remove-Module Cache -ErrorAction SilentlyContinue -Force
}

Describe 'Command extended scenarios' {
    Context 'Test-CommandAvailable' {
        It 'Returns false for null command names' {
            Test-CommandAvailable -CommandName $null | Should -Be $false
        }

        It 'Returns false for whitespace command names' {
            Test-CommandAvailable -CommandName '   ' | Should -Be $false
        }
    }

    Context 'Resolve-InstallCommand' {
        It 'Returns plain string install commands unchanged' {
            $command = 'apt-get install -y example-tool'

            Resolve-InstallCommand -InstallCommand $command | Should -Be $command
        }

        It 'Selects the Linux install command from a platform map' {
            $installMap = @{
                Windows = 'winget install Example'
                Linux   = 'apt-get install -y example'
                macOS   = 'brew install example'
            }

            Resolve-InstallCommand -InstallCommand $installMap | Should -Be 'apt-get install -y example'
        }
    }

    Context 'Invoke-CommandIfAvailable' {
        It 'Returns the fallback value when the command is unavailable' {
            $result = Invoke-CommandIfAvailable `
                -CommandName 'Definitely-Missing-Command-12345' `
                -FallbackValue 'fallback-result'

            $result | Should -Be 'fallback-result'
        }

        It 'Invokes available commands with hashtable arguments' {
            $result = Invoke-CommandIfAvailable `
                -CommandName 'Join-Path' `
                -Arguments @{ Path = 'a'; ChildPath = 'b.txt' }

            ($result -replace '\\', '/') | Should -Be 'a/b.txt'
        }
    }
}
