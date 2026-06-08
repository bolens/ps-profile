# ===============================================
# profile-git-enhanced-fragment-extended.tests.ps1
# Execution tests for git-enhanced.ps1 fragment behavior
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

function script:Reset-GitEnhancedFragmentState {
    if ($global:TestImportFragmentModulesBody) {
        Set-Item -Path Function:\Import-FragmentModules -Value $global:TestImportFragmentModulesBody -Force
    }

    foreach ($fragmentName in @('git-enhanced', 'git-changelog', 'git-gui', 'git-workflow')) {
        Clear-FragmentLoaded -FragmentName $fragmentName -ErrorAction SilentlyContinue
    }
}

Describe 'profile.d/git-enhanced.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitEnhancedFragmentState
    }

    It 'Loads enhanced git helper commands through Import-FragmentModules' {
        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')

        Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitTower -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command New-GitWorktree -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true
    }

    It 'Skips re-initialization when git-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        Test-FragmentLoaded -FragmentName 'git-enhanced' | Should -Be $true

        . (Join-Path $script:ProfileDir 'git-enhanced.ps1')
        Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
