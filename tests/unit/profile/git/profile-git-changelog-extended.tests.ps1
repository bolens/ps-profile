# ===============================================
# profile-git-changelog-extended.tests.ps1
# Execution tests for git-modules/enhanced/git-changelog.ps1 behavior
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

function script:Reset-GitChangelogModuleState {
    Clear-FragmentLoaded -FragmentName 'git-changelog' -ErrorAction SilentlyContinue
}

Describe 'profile.d/git-modules/enhanced/git-changelog.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitChangelogModuleState
    }

    It 'Registers changelog helpers and marks the fragment loaded' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-changelog.ps1')

        Get-Command New-GitChangelog -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $gitCliffAlias = Get-Alias 'git-cliff' -ErrorAction SilentlyContinue
        if ($gitCliffAlias) {
            $gitCliffAlias.ResolvedCommandName | Should -Be 'New-GitChangelog'
        }

        Test-FragmentLoaded -FragmentName 'git-changelog' | Should -Be $true
    }

    It 'New-GitChangelog warns when git-cliff is unavailable' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-changelog.ps1')

        Set-TestCommandAvailabilityState -CommandName 'git-cliff' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('git-cliff', [ref]$null)
        }

        $output = New-GitChangelog 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'git-cliff not found'
    }

    It 'Skips re-initialization when git-changelog is already loaded' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-changelog.ps1')
        $firstChangelog = Get-Command New-GitChangelog -ErrorAction Stop

        . (Join-Path $script:GitModulesDir 'enhanced/git-changelog.ps1')

        (Get-Command New-GitChangelog -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstChangelog.ScriptBlock.ToString()
    }
}
