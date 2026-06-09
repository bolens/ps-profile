# ===============================================
# profile-git-ensure-extended.tests.ps1
# Execution tests for git.ps1 Ensure-Git deferred loading behavior
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

function script:Reset-GitEnsureState {
    Clear-FragmentLoaded -FragmentName 'git' -ErrorAction SilentlyContinue
    Set-Variable -Name 'GitInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/git.ps1 Ensure-Git extended scenarios' {
    BeforeEach {
        Reset-GitEnsureState
    }

    It 'Registers Ensure-Git and lazy git shortcuts before full module load' {
        . (Join-Path $script:ProfileDir 'git.ps1')

        Get-Command Ensure-Git -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitStatus -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $gsAlias = Get-Alias gs -ErrorAction SilentlyContinue
        if ($gsAlias) {
            $gsAlias.ResolvedCommandName | Should -Be 'Invoke-GitStatus'
        }

        $global:GitInitialized | Should -Be $false
    }

    It 'Ensure-Git loads registry-backed git modules and marks initialization complete' {
        . (Join-Path $script:ProfileDir 'git.ps1')

        Ensure-Git

        $global:GitInitialized | Should -Be $true
        Get-Command Invoke-GitCommand -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-GitRepositoryContext -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Ensure-Git is idempotent on repeated calls' {
        . (Join-Path $script:ProfileDir 'git.ps1')

        Ensure-Git
        $firstCommand = Get-Command Invoke-GitCommand -ErrorAction Stop

        Ensure-Git

        $global:GitInitialized | Should -Be $true
        (Get-Command Invoke-GitCommand -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstCommand.ScriptBlock.ToString()
    }
}
