<#
tests/unit/profile-prompt-base-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PromptBase framework initialization helpers.
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
            'InstallHintResolver.ps1'
            'FunctionRegistration.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }

    . (Join-Path $bootstrapDir 'PromptBase.ps1')
}

Describe 'PromptBase extended scenarios' {
    BeforeEach {
        $script:Suffix = Get-Random
        $script:CommandName = "prompt-cmd-$script:Suffix"
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    AfterEach {
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Initialize-PromptFramework' {
        It 'Skips initialization when CheckInitialized reports the framework is ready' {
            $script:InitRan = $false

            Initialize-PromptFramework `
                -FrameworkName 'ReadyPrompt' `
                -CommandName $script:CommandName `
                -InitScript { $script:InitRan = $true } `
                -CheckInitialized { $true } | Should -Be $true

            $script:InitRan | Should -Be $false
        }

        It 'Runs the fallback prompt when the command is unavailable' {
            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $false
            $script:FallbackRan = $false

            Initialize-PromptFramework `
                -FrameworkName 'MissingPrompt' `
                -CommandName $script:CommandName `
                -InitScript { throw 'init should not run' } `
                -FallbackPrompt { $script:FallbackRan = $true } | Should -Be $false

            $script:FallbackRan | Should -Be $true
        }

        It 'Executes the initialization script when the command is available' {
            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $true
            $script:InitRan = $false

            Initialize-PromptFramework `
                -FrameworkName 'AvailablePrompt' `
                -CommandName $script:CommandName `
                -InitScript { $script:InitRan = $true } | Should -Be $true

            $script:InitRan | Should -Be $true
        }

        It 'Collects missing-tool warnings when the command is unavailable' {
            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $false

            Initialize-PromptFramework `
                -FrameworkName 'WarnPrompt' `
                -CommandName $script:CommandName `
                -InitScript { 'unused' } | Should -Be $false

            $global:CollectedMissingToolWarnings.Count | Should -BeGreaterThan (0)
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be $script:CommandName
        }

        It 'Runs the fallback prompt when initialization throws' {
            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $true
            $script:FallbackRan = $false

            Initialize-PromptFramework `
                -FrameworkName 'FailedPrompt' `
                -CommandName $script:CommandName `
                -InitScript { throw 'init failed' } `
                -FallbackPrompt { $script:FallbackRan = $true } | Should -Be $false

            $script:FallbackRan | Should -Be $true
        }
    }

    Context 'Test-PromptCommandAvailable' {
        It 'Returns true when the prompt command is available' {
            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $true
            Test-PromptCommandAvailable -CommandName $script:CommandName | Should -Be $true
        }

        It 'Returns false and collects a warning when the command is missing' {
            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $false

            Test-PromptCommandAvailable -CommandName $script:CommandName | Should -Be $false
            $global:CollectedMissingToolWarnings.Count | Should -BeGreaterThan (0)
        }
    }
}
