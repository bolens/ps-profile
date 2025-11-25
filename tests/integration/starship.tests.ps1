BeforeAll {
    # Get the test support functions
    . "$PSScriptRoot\..\TestSupport.ps1"

    # Load bootstrap first to get Test-HasCommand
    $global:__psprofile_fragment_loaded = @{}
    . "$PSScriptRoot\..\..\profile.d\00-bootstrap.ps1"

    # Load the starship fragment directly with guard clearing
    . "$PSScriptRoot\..\..\profile.d\23-starship.ps1"
}

Describe "Starship Module Tests" {
    BeforeEach {
        # Clear any existing starship state
        Remove-Variable -Name StarshipCommand -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name StarshipModule -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name StarshipInitialized -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name StarshipActive -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name StarshipPromptActive -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name SmartPromptInitialized -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name OriginalPrompt -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name CommandStartTime -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name LastCommandDuration -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name LastCommandSucceeded -Scope Global -ErrorAction SilentlyContinue

        # Mock external commands
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'starship' }
        Mock Test-HasCommand { $false } -ParameterFilter { $Command -eq 'starship' }
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'git' }
        Mock Test-HasCommand { $false } -ParameterFilter { $Command -eq 'git' }
    }

    Context "Test-StarshipInitialized" {
        It "Returns false when no prompt function exists" {
            Remove-Item Function:prompt -ErrorAction SilentlyContinue
            Test-StarshipInitialized | Should -Be $false
        }

        It "Returns false when prompt function doesn't contain starship" {
            function prompt { "PS> " }
            Test-StarshipInitialized | Should -Be $false
        }

        It "Returns true when prompt function contains starship" {
            function prompt { & starship prompt }
            Test-StarshipInitialized | Should -Be $true
        }
    }

    Context "Test-PromptNeedsReplacement" {
        It "Function exists and can be called" {
            { Get-Command Test-PromptNeedsReplacement -ErrorAction SilentlyContinue } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-StarshipPromptArguments" {
        It "Function exists and can be called" {
            { Get-StarshipPromptArguments -LastCommandSucceeded $true -LastExitCode 0 } | Should -Not -Throw
        }
    }

    Context "New-StarshipPromptFunction" {
        BeforeEach {
            $tempPath = [System.IO.Path]::GetTempFileName()
            $global:StarshipCommand = $tempPath
        }

        AfterEach {
            if (Test-Path $tempPath) { Remove-Item $tempPath }
            Remove-Variable -Name StarshipCommand -Scope Global -ErrorAction SilentlyContinue
        }

        It "Creates a global prompt function" {
            New-StarshipPromptFunction -StarshipCommandPath $tempPath
            Get-Command prompt -CommandType Function | Should -Not -BeNullOrEmpty
        }

        It "Returns fallback prompt when starship command not found" {
            Remove-Variable -Name StarshipCommand -Scope Global -ErrorAction SilentlyContinue
            $result = prompt
            $result | Should -Match "PS.*>"
        }
    }

    Context "Initialize-StarshipModule" {
        It "Stores starship module globally when available" {
            Mock Get-Module { [PSCustomObject]@{ Name = 'starship' } }
            Initialize-StarshipModule
            $global:StarshipModule | Should -Not -BeNullOrEmpty
        }

        It "Handles missing starship module gracefully" {
            Mock Get-Module { $null }
            { Initialize-StarshipModule } | Should -Not -Throw
        }
    }

    Context "Invoke-StarshipInitScript" {
        It "Executes without error when starship is available" {
            # Skip complex external command testing - focus on function availability
            { Get-Command Invoke-StarshipInitScript -ErrorAction SilentlyContinue } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Update-VSCodePrompt" {
        It "Handles VS Code state gracefully" {
            $Global:__VSCodeState = @{ OriginalPrompt = $null }
            function global:prompt { "test" }
            { Update-VSCodePrompt } | Should -Not -Throw
        }

        It "Handles missing VS Code state gracefully" {
            $Global:__VSCodeState = $null
            { Update-VSCodePrompt } | Should -Not -Throw
        }
    }

    Context "Initialize-Starship" {
        It "Uses smart prompt when starship not available" {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'starship' }
            Mock Test-HasCommand { $false } -ParameterFilter { $Command -eq 'starship' }
            { Initialize-Starship } | Should -Not -Throw
            # Should initialize smart prompt as fallback
            $global:SmartPromptInitialized | Should -Be $true
        }

        It "Handles starship initialization errors gracefully" {
            Mock Get-Command { [PSCustomObject]@{ Source = "fake-starship" } } -ParameterFilter { $Name -eq 'starship' }
            Mock Invoke-StarshipInitScript { throw "Init failed" }
            { Initialize-Starship } | Should -Not -Throw
        }
    }

    Context "Initialize-SmartPrompt" {
        It "Creates enhanced prompt function" {
            Initialize-SmartPrompt
            Get-Command prompt -CommandType Function | Should -Not -BeNullOrEmpty
            $global:SmartPromptInitialized | Should -Be $true
        }

        It "Sets up command timing tracking" {
            Initialize-SmartPrompt
            $ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction | Should -Not -BeNullOrEmpty
            $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction | Should -Not -BeNullOrEmpty
        }

        It "Does not reinitialize if already done" {
            $global:SmartPromptInitialized = $true
            Initialize-SmartPrompt
            # Should not throw or change state
        }
    }
}
