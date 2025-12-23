<#
.SYNOPSIS
    Integration tests for fzf fuzzy finder tool fragment.

.DESCRIPTION
    Tests fzf helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Fuzzy Finder Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if ($null -eq $bootstrapPath -or [string]::IsNullOrWhiteSpace($bootstrapPath)) {
                throw "BootstrapPath is null or empty"
            }
            if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                throw "Bootstrap file not found at: $bootstrapPath"
            }
            . $bootstrapPath
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize fuzzy finder tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'fzf helpers (fzf.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'fzf' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'fzf' } -MockWith { $null }
            # Mock fzf command before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'fzf' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'fzf' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'fzf.ps1')
        }

        It 'Creates Find-FileFuzzy function' {
            Get-Command Find-FileFuzzy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates ff alias for Find-FileFuzzy' {
            Get-Alias ff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ff).ResolvedCommandName | Should -Be 'Find-FileFuzzy'
        }

        It 'ff alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('fzf', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'fzf' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'fzf' } -MockWith { $false }
            $output = ff 2>&1 3>&1 | Out-String
            $output | Should -Match 'fzf not found'
            $output | Should -Match 'scoop install fzf'
        }

        It 'Creates Find-CommandFuzzy function' {
            Get-Command Find-CommandFuzzy -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates fcmd alias for Find-CommandFuzzy' {
            Get-Alias fcmd -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias fcmd).ResolvedCommandName | Should -Be 'Find-CommandFuzzy'
        }

        It 'fcmd alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('fzf', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'fzf' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'fzf' } -MockWith { $false }
            $output = fcmd 2>&1 3>&1 | Out-String
            $output | Should -Match 'fzf not found'
            $output | Should -Match 'scoop install fzf'
        }
    }
}

