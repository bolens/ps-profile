# ===============================================
# profile-git-enhanced-loader.tests.ps1
# Unit tests for git-enhanced.ps1 modular loader behavior
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
    $importCommand = Get-Command Import-FragmentModules -ErrorAction SilentlyContinue
    $global:TestImportFragmentModulesBody = if ($importCommand) { $importCommand.ScriptBlock } else { $null }
}

function script:Reset-GitEnhancedLoaderState {
    if ($global:TestImportFragmentModulesBody) {
        Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
    }

    foreach ($fragmentName in @('git-enhanced', 'git-changelog', 'git-gui', 'git-workflow')) {
        Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue
    }

    foreach ($name in @(
            'New-GitChangelog', 'Invoke-GitTower', 'New-GitWorktree',
            'Sync-GitRepos', 'Format-GitCommit'
        )) {
        Remove-Item -Path "Function:\$name" -Force -ErrorAction SilentlyContinue
    }
}

Describe 'git-enhanced.ps1 - fragment idempotency' {
    BeforeEach {
        Reset-GitEnhancedLoaderState
    }

    It 'Skips re-initialization when git-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true

        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
