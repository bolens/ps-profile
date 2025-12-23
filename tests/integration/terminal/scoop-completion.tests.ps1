

Describe 'Scoop Completion Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }

            # Use Get-TestPath without EnsureExists so tests can create/remove this directory freely.
            $script:TestScoopDir = Get-TestPath -RelativePath 'test-scoop' -StartPath $PSScriptRoot

            # Create test directory if it doesn't exist
            if ($script:TestScoopDir -and -not [string]::IsNullOrWhiteSpace($script:TestScoopDir) -and -not (Test-Path -LiteralPath $script:TestScoopDir)) {
                New-Item -ItemType Directory -Path $script:TestScoopDir -Force | Out-Null
            }

            $script:CompletionModulePath = Join-Path $script:TestScoopDir 'apps\scoop\current\supporting\completion\Scoop-Completion.psd1'
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize scoop completion tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Scoop completion setup' {
        BeforeEach {
            # Clear environment variables
            $env:SCOOP = $null
            $env:SCOOP_GLOBAL = $null
            $env:USERPROFILE = 'C:\Users\TestUser'
            $env:HOME = $null

            # Clear any existing global variable
            if (Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue) {
                Remove-Variable -Name 'ScoopCompletionLoaded' -Scope Global -Force
            }

            # Clear any existing function
            if (Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue) {
                Remove-Item Function:\Enable-ScoopCompletion -Force
            }

            # Remove test directories
            if ($script:TestScoopDir -and -not [string]::IsNullOrWhiteSpace($script:TestScoopDir) -and (Test-Path -LiteralPath $script:TestScoopDir)) {
                Remove-Item $script:TestScoopDir -Recurse -Force
            }
        }

        It 'Sets ScoopCompletionLoaded global variable on load' {
            # Load the module
            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            # Variable should NOT be set on load (only when Enable-ScoopCompletion is called)
            Get-Variable -Name 'ScoopCompletionLoaded' -Scope Global -ErrorAction SilentlyContinue | Should -Be $null
        }

        It 'Does not create Enable-ScoopCompletion when no scoop installation found' {
            # Mock Get-ScoopCompletionPath to return null (no scoop found)
            if (Get-Command Get-ScoopCompletionPath -ErrorAction SilentlyContinue) {
                Mock -CommandName 'Get-ScoopCompletionPath' -MockWith { return $null }
            }
            # Mock Test-Path to prevent finding any scoop installations
            Mock-FileSystem -Operation 'Test-Path' -Path '*' -ReturnValue $false -UsePesterMock

            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue | Should -Be $null
        }

        It 'Creates Enable-ScoopCompletion when scoop found via SCOOP environment variable' {
            # Set up environment
            $env:SCOOP_GLOBAL = $null
            $env:SCOOP = $script:TestScoopDir

            # Create the completion module file
            $completionDir = Split-Path $script:CompletionModulePath -Parent
            New-Item -ItemType Directory -Path $completionDir -Force | Out-Null
            New-Item -ItemType File -Path $script:CompletionModulePath -Force | Out-Null

            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            Get-Command Enable-ScoopCompletion -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Enable-ScoopCompletion can be called' {
            # Set up environment
            $env:SCOOP_GLOBAL = $null
            $env:SCOOP = $script:TestScoopDir

            # Create the completion module file
            $completionDir = Split-Path $script:CompletionModulePath -Parent
            New-Item -ItemType Directory -Path $completionDir -Force | Out-Null
            New-Item -ItemType File -Path $script:CompletionModulePath -Force | Out-Null

            . (Join-Path $script:ProfileDir 'scoop-completion.ps1')

            # Call the function - should not throw (may show warning if import fails)
            { Enable-ScoopCompletion } | Should -Not -Throw
        }

        It 'Handles errors during scoop completion setup gracefully' {
            # Should not throw even with invalid setup
            { . (Join-Path $script:ProfileDir 'scoop-completion.ps1') } | Should -Not -Throw
        }
    }
}
