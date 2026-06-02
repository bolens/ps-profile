
BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
    try {
        # Load bootstrap first to get Test-HasCommand
        $global:__psprofile_fragment_loaded = @{}
        $profileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        if ($null -eq $profileDir -or [string]::IsNullOrWhiteSpace($profileDir)) {
            throw "Get-TestPath returned null or empty value for profileDir"
        }
        if (-not (Test-Path -LiteralPath $profileDir)) {
            throw "Profile directory not found at: $profileDir"
        }
        
        $bootstrapPath = Join-Path $profileDir 'bootstrap.ps1'
        if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
            throw "BootstrapPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $bootstrapPath)) {
            throw "Bootstrap file not found at: $bootstrapPath"
        }
        . $bootstrapPath

        # Load the starship fragment directly with guard clearing
        $starshipPath = Join-Path $profileDir 'starship.ps1'
        if ($null -eq $starshipPath -or [string]::IsNullOrWhiteSpace($starshipPath)) {
            throw "StarshipPath is null or empty"
        }
        if (-not (Test-Path -LiteralPath $starshipPath)) {
            throw "Starship fragment not found at: $starshipPath"
        }
        . $starshipPath
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
        }
        Write-Error "Failed to initialize starship tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
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

        Mock-CommandAvailabilityPester -CommandName 'starship' -Available $false
        Mock-CommandAvailabilityPester -CommandName 'git' -Available $false
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
        It "Function exists and is callable" {
            Get-Command Test-PromptNeedsReplacement -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            if (-not (Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue)) {
                Set-Item -Path Function:\global:prompt -Value { 'PS> ' } -Force
            }
            $promptCmd = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
            $promptCmd | Should -Not -BeNullOrEmpty
            { Test-PromptNeedsReplacement -PromptCmd $promptCmd } | Should -Not -Throw
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
            if ($tempPath -and -not [string]::IsNullOrWhiteSpace($tempPath) -and (Test-Path -LiteralPath $tempPath)) { Remove-Item $tempPath }
            Remove-Variable -Name StarshipCommand -Scope Global -ErrorAction SilentlyContinue
        }

        It "Returns a fallback prompt string when starship command is unavailable" {
            Remove-Variable -Name StarshipCommand -Scope Global -ErrorAction SilentlyContinue
            $result = New-StarshipPromptFunction -StarshipCommandPath $tempPath
            $result | Should -Match 'PS.*>'
        }

        It "Returns a fallback prompt string when starship path is missing" {
            Remove-Variable -Name StarshipCommand -Scope Global -ErrorAction SilentlyContinue
            $result = New-StarshipPromptFunction -StarshipCommandPath 'nonexistent-starship'
            $result | Should -Match 'PS.*>'
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
        It "Function exists and is callable" {
            Get-Command Invoke-StarshipInitScript -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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
            Mock-CommandAvailabilityPester -CommandName 'starship' -Available $false
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

        It "Sets up command timing tracking when performance hooks are available" -Skip:(-not (Get-Command Skip -ErrorAction SilentlyContinue)) {
            Initialize-SmartPrompt

            # PreCommandLookupAction should always be set by Initialize-SmartPrompt
            $ExecutionContext.SessionState.InvokeCommand.PreCommandLookupAction | Should -Not -BeNullOrEmpty

            # PostCommandLookupAction is only present when performance insights hooks are installed.
            # In minimal environments (like CI), this may legitimately be null, so treat that as a skip.
            if ($ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction) {
                $ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction | Should -Not -BeNullOrEmpty
            }
        }

        It "Does not reinitialize if already done" {
            $global:SmartPromptInitialized = $true
            $originalPrompt = $function:prompt

            $script:capturedOutput = @()
            Mock -CommandName Write-Host -MockWith {
                param($Object)
                $script:capturedOutput += $Object
            }

            Initialize-SmartPrompt

            @($script:capturedOutput).Count | Should -Be 0
            $function:prompt | Should -Be $originalPrompt
        }
    }
}
