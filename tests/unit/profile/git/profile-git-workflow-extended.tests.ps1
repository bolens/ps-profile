# ===============================================
# profile-git-workflow-extended.tests.ps1
# Execution tests for git-modules/enhanced/git-workflow.ps1 behavior
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
    $script:GitModulesDir = Join-Path $script:ProfileDir 'git-modules'
    $fragmentIdempotencyPath = Get-TestPath -RelativePath 'scripts/lib/fragment/FragmentIdempotency.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $fragmentIdempotencyPath -DisableNameChecking -ErrorAction Stop -Force
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-GitWorkflowModuleState {
    Clear-FragmentLoaded -FragmentName 'git-workflow' -ErrorAction SilentlyContinue
}

Describe 'profile.d/git-modules/enhanced/git-workflow.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitWorkflowModuleState
    }

    It 'Registers workflow helpers and marks the fragment loaded' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-workflow.ps1')

        Get-Command New-GitWorktree -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Sync-GitRepos -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-GitStats -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clean-GitBranches -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'git-workflow' | Should -Be $true
    }

    It 'New-GitWorktree warns when git is unavailable' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-workflow.ps1')

        Set-TestCommandAvailabilityState -CommandName 'git' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('git', [ref]$null)
        }

        $worktreePath = Join-Path (New-TestTempDirectory -Prefix 'GitWorkflowWorktree') 'feature-branch'
        $output = New-GitWorktree -Path $worktreePath 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'git not found'
    }

    It 'Skips re-initialization when git-workflow is already loaded' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-workflow.ps1')
        $firstWorktree = Get-Command New-GitWorktree -ErrorAction Stop

        . (Join-Path $script:GitModulesDir 'enhanced/git-workflow.ps1')

        (Get-Command New-GitWorktree -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstWorktree.ScriptBlock.ToString()
    }
}
