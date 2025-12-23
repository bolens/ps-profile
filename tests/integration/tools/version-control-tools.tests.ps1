<#
.SYNOPSIS
    Integration tests for version control tool fragments (gh).

.DESCRIPTION
    Tests GitHub CLI helper functions.
    These tests verify that functions are created correctly and handle
    missing tools gracefully.
#>

Describe 'Version Control Tools Integration Tests' {
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
            Write-Error "Failed to initialize version control tools tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'GitHub CLI helpers (gh.ps1)' {
        BeforeAll {
            # Mock Get-Command to return null for 'gh' so Set-AgentModeAlias creates the aliases
            Mock -CommandName Get-Command -ParameterFilter { $Name -eq 'gh' } -MockWith { $null }
            # Mock gh command before loading fragment
            Mock-CommandAvailabilityPester -CommandName 'gh' -Available $false -Scope Context
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gh' } -MockWith { $false }
            . (Join-Path $script:ProfileDir 'gh.ps1')
        }

        It 'Creates Open-GitHubRepository function' {
            Get-Command Open-GitHubRepository -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gh-open alias for Open-GitHubRepository' {
            Get-Alias gh-open -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gh-open).ResolvedCommandName | Should -Be 'Open-GitHubRepository'
        }

        It 'gh-open alias handles missing tool gracefully and recommends installation' {
            if ($global:MissingToolWarnings) {
                $null = $global:MissingToolWarnings.TryRemove('gh', [ref]$null)
            }
            Mock-CommandAvailabilityPester -CommandName 'gh' -Available $false -Scope It
            Mock -CommandName Test-HasCommand -ParameterFilter { $Name -eq 'gh' } -MockWith { $false }
            $output = gh-open 2>&1 3>&1 | Out-String
            $output | Should -Match 'gh not found'
            $output | Should -Match 'scoop install gh'
        }

        It 'Creates Invoke-GitHubPullRequest function' {
            Get-Command Invoke-GitHubPullRequest -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates gh-pr alias for Invoke-GitHubPullRequest' {
            Get-Alias gh-pr -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias gh-pr).ResolvedCommandName | Should -Be 'Invoke-GitHubPullRequest'
        }
    }
}

