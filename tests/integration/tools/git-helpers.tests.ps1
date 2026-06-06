<#
.SYNOPSIS
    Integration tests for Git helper fragments (git.ps1).

.DESCRIPTION
    Tests Git helper functions (Get-GitCurrentBranch, Get-GitStatusShort, Format-PromptGitSegment).
    These tests verify that functions are created correctly and aliases are set up properly.
    Note: This is different from git.ps1 which contains Git integration modules.
#>

Describe 'Git Helpers Integration Tests' {
    BeforeAll {
        try {
            . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')
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

            $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts\lib\fragment\FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
            Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize Git helpers tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Git helpers (git.ps1)' {
        BeforeAll {
            Clear-FragmentLoaded -FragmentName 'git' -ErrorAction SilentlyContinue
            . (Join-Path $script:ProfileDir 'git.ps1')
        }

        AfterAll {
            Clear-FragmentLoaded -FragmentName 'git' -ErrorAction SilentlyContinue
        }

        It 'Creates Get-GitCurrentBranch function' {
            Get-Command Get-GitCurrentBranch -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Git-CurrentBranch alias for Get-GitCurrentBranch' {
            Get-Alias Git-CurrentBranch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias Git-CurrentBranch).ResolvedCommandName | Should -Be 'Get-GitCurrentBranch'
        }

        It 'Creates Get-GitStatusShort function' {
            Get-Command Get-GitStatusShort -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Git-StatusShort alias for Get-GitStatusShort' {
            Get-Alias Git-StatusShort -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias Git-StatusShort).ResolvedCommandName | Should -Be 'Get-GitStatusShort'
        }

        It 'Creates Format-PromptGitSegment function' {
            Get-Command Format-PromptGitSegment -CommandType Function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Creates Prompt-GitSegment alias for Format-PromptGitSegment' {
            Get-Alias Prompt-GitSegment -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias Prompt-GitSegment).ResolvedCommandName | Should -Be 'Format-PromptGitSegment'
        }

        It 'Fragment is idempotent (can be loaded multiple times)' {
            if (-not (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'Test-FragmentLoaded is not available'
                return
            }

            . (Join-Path $script:ProfileDir 'git.ps1')
            $firstLoad = Test-FragmentLoaded -FragmentName 'git'

            . (Join-Path $script:ProfileDir 'git.ps1')
            $secondLoad = Test-FragmentLoaded -FragmentName 'git'

            $firstLoad | Should -Be $secondLoad
            $firstLoad | Should -Be $true
        }
    }
}

