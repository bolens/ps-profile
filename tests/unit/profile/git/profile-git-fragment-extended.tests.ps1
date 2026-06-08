# ===============================================
# profile-git-fragment-extended.tests.ps1
# Execution tests for git.ps1 fragment behavior
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

function script:Reset-GitFragmentState {
    Clear-FragmentLoaded -FragmentName 'git' -ErrorAction SilentlyContinue
    Set-Variable -Name 'GitInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/git.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitFragmentState
    }

    It 'Registers lightweight git stubs and lazy shortcuts when the fragment loads' {
        . (Join-Path $script:ProfileDir 'git.ps1')

        Get-Command Get-GitCurrentBranch -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Format-PromptGitSegment -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitStatus -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command gs -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'git' | Should -Be $true
    }

    It 'Loads git module helpers through Ensure-Git deferred initialization' {
        . (Join-Path $script:ProfileDir 'git.ps1')

        Ensure-Git

        Get-Command Invoke-GitCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-GitRepositoryContext -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips re-initialization when git fragment is already loaded' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        $firstBranch = Get-Command Get-GitCurrentBranch -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'git.ps1')

        (Get-Command Get-GitCurrentBranch -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstBranch.ScriptBlock.ToString()
    }
}
