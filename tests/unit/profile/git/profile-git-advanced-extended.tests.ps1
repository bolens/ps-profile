# ===============================================
# profile-git-advanced-extended.tests.ps1
# Execution tests for git-modules/core/git-advanced.ps1 behavior
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

function script:Reset-GitAdvancedTestState {
    Clear-FragmentLoaded -FragmentName 'git' -ErrorAction SilentlyContinue
    Set-Variable -Name 'GitInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/git-modules/core/git-advanced.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitAdvancedTestState
    }

    It 'Registers lazy advanced git helpers and aliases through Ensure-Git' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Get-Command Invoke-GitClone -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Sync-GitRepository -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $gclAlias = Get-Alias gcl -ErrorAction SilentlyContinue
        if ($gclAlias) {
            $gclAlias.ResolvedCommandName | Should -Be 'Invoke-GitClone'
        }

        $gsyncAlias = Get-Alias gsync -ErrorAction SilentlyContinue
        if ($gsyncAlias) {
            $gsyncAlias.ResolvedCommandName | Should -Be 'Sync-GitRepository'
        }
    }

    It 'Ensure-GitHelper materializes advanced git command wrappers' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Invoke-GitClone -ErrorAction SilentlyContinue | Out-Null

        Get-Command Undo-GitCommit -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-GitDefaultBranch -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Skips re-initialization when Ensure-GitHelper already ran' {
        . (Join-Path $script:ProfileDir 'git.ps1')
        Ensure-Git

        Invoke-GitClone -ErrorAction SilentlyContinue | Out-Null
        $firstUndo = Get-Command Undo-GitCommit -ErrorAction Stop

        Invoke-GitClone -ErrorAction SilentlyContinue | Out-Null

        (Get-Command Undo-GitCommit -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstUndo.ScriptBlock.ToString()
    }
}
