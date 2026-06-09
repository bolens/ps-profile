# ===============================================
# profile-git-helpers-extended.tests.ps1
# Execution tests for git-modules/core/git-helpers.ps1 behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
}

function script:Reset-GitHelpersTestState {
    Clear-FragmentLoaded -FragmentName 'git' -ErrorAction SilentlyContinue
    Set-Variable -Name 'GitInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/git-modules/core/git-helpers.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitHelpersTestState
    }

    It 'Registers repository context and command wrapper helpers through Ensure-Git' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Get-Command Test-GitRepositoryContext -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-GitRepositoryHasCommits -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Test-GitRepositoryContext returns false when git is unavailable' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Set-TestCommandAvailabilityState -CommandName 'git' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Test-GitRepositoryContext -CommandName 'Invoke-GitStatus' | Should -Be $false
    }

    It 'Invoke-GitCommand skips execution outside a repository context' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Set-TestCommandAvailabilityState -CommandName 'git' -Available $true
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        Push-Location (New-TestTempDirectory -Prefix 'GitHelpersOutsideRepo')
        try {
            { Invoke-GitCommand -Subcommand 'status' -CommandName 'git status' | Out-Null } | Should -Not -Throw
        }
        finally {
            Pop-Location
        }
    }
}
