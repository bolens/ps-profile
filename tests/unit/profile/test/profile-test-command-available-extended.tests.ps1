<#
tests/unit/profile-test-command-available-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Test-CommandAvailable package manager mapping.
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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'AssumedCommands.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'Test-CommandAvailable extended scenarios' {
    AfterEach {
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Package manager command mapping' {
        It 'Maps chocolatey to the choco executable name' {
            Set-TestCommandAvailabilityState -CommandName 'choco' -Available $true
            Test-CommandAvailable -CommandName 'chocolatey' | Should -Be $true
        }

        It 'Maps homebrew to the brew executable name' {
            if (Get-Command brew -ErrorAction SilentlyContinue) {
                Test-CommandAvailable -CommandName 'homebrew' | Should -Be $true
            }
            else {
                Set-TestCommandAvailabilityState -CommandName 'brew' -Available $true
                Test-CommandAvailable -CommandName 'homebrew' | Should -Be $true
            }
        }

        It 'Treats unknown command names literally' {
            Test-CommandAvailable -CommandName 'definitely-missing-command-xyz-abc' | Should -Be $false
        }
    }

    Context 'Assumed command integration' {
        It 'Treats assumed commands as available without probing providers' {
            $commandName = "assumed-available-$([Guid]::NewGuid().ToString('N'))"
                        Add-AssumedCommand -Name $commandName | Out-Null
            Test-CommandAvailable -CommandName $commandName | Should -Be $true
        }
        finally {
            Remove-AssumedCommand -Name $commandName | Out-Null
        }
    }
}
