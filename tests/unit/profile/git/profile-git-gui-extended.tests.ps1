# ===============================================
# profile-git-gui-extended.tests.ps1
# Execution tests for git-modules/enhanced/git-gui.ps1 behavior
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

function script:Reset-GitGuiModuleState {
    Clear-FragmentLoaded -FragmentName 'git-gui' -ErrorAction SilentlyContinue
}

Describe 'profile.d/git-modules/enhanced/git-gui.ps1 extended scenarios' {
    BeforeEach {
        Reset-GitGuiModuleState
    }

    It 'Registers GUI launch helpers and marks the fragment loaded' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-gui.ps1')

        Get-Command Invoke-GitTower -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitKraken -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-GitButler -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $towerAlias = Get-Alias 'git-tower' -ErrorAction SilentlyContinue
        if ($towerAlias) {
            $towerAlias.ResolvedCommandName | Should -Be 'Invoke-GitTower'
        }

        $krakenAlias = Get-Alias gitkraken -ErrorAction SilentlyContinue
        if ($krakenAlias) {
            $krakenAlias.ResolvedCommandName | Should -Be 'Invoke-GitKraken'
        }

        Test-FragmentLoaded -FragmentName 'git-gui' | Should -Be $true
    }

    It 'Invoke-GitTower warns when git-tower is unavailable' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-gui.ps1')

        Set-TestCommandAvailabilityState -CommandName 'git-tower' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('git-tower', [ref]$null)
        }

        $output = Invoke-GitTower 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'git-tower not found'
    }

    It 'Skips re-initialization when git-gui is already loaded' {
        . (Join-Path $script:GitModulesDir 'enhanced/git-gui.ps1')
        $firstTower = Get-Command Invoke-GitTower -ErrorAction Stop

        . (Join-Path $script:GitModulesDir 'enhanced/git-gui.ps1')

        (Get-Command Invoke-GitTower -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstTower.ScriptBlock.ToString()
    }
}
