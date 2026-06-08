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
}

Describe 'git-enhanced.ps1 - fallback module loader' {
    BeforeEach {
        Clear-FragmentLoaded -FragmentName 'git-enhanced' -ErrorAction SilentlyContinue
        foreach ($name in @(
                'New-GitChangelog', 'Invoke-GitTower', 'New-GitWorktree',
                'Sync-GitRepos', 'Format-GitCommit'
            )) {
            Remove-Item -Path "Function:\global:$name" -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Loads enhanced git modules when Import-FragmentModules is unavailable' {
        $importModules = Get-Command Import-FragmentModules -ErrorAction SilentlyContinue
        $importBody = if ($importModules) { $importModules.ScriptBlock } else { $null }
        Remove-Item -Path Function:\global:Import-FragmentModules -Force -ErrorAction SilentlyContinue

        try {
            { . (Join-Path $script:ProfileDir 'git-enhanced.ps1') } | Should -Not -Throw

            Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Get-Command New-GitWorktree -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Get-Command Sync-GitRepos -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true
        }
        finally {
            if ($importBody) {
                Set-Item -Path Function:\global:Import-FragmentModules -Value $importBody -Force
            }
        }
    }

    It 'Uses Import-FragmentModules when the bootstrap helper is available' {
        Get-Command Import-FragmentModules -ErrorAction Stop | Should -Not -BeNullOrEmpty

        { . (Join-Path $script:ProfileDir 'git-enhanced.ps1') } | Should -Not -Throw

        Get-Command Format-GitCommit -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true
    }
}

Describe 'git-enhanced.ps1 - fragment idempotency' {
    BeforeEach {
        Clear-FragmentLoaded -FragmentName 'git-enhanced' -ErrorAction SilentlyContinue
    }

    It 'Skips re-initialization when git-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true

        { . (Join-Path $script:ProfileDir 'git-enhanced.ps1') } | Should -Not -Throw
        Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
