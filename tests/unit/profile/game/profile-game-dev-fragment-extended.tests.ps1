# ===============================================
# profile-game-dev-fragment-extended.tests.ps1
# Execution tests for game-dev.ps1 fragment behavior
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

function script:Reset-GameDevFragmentState {
    Clear-FragmentLoaded -FragmentName 'game-dev' -ErrorAction SilentlyContinue
}

Describe 'profile.d/game-dev.ps1 extended scenarios' {
    BeforeEach {
        Reset-GameDevFragmentState
    }

    It 'Registers game editor helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'game-dev.ps1')

        Get-Command Launch-Blockbench -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Launch-Godot -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'game-dev' | Should -Be $true
    }

    It 'Launch-Blockbench warns when blockbench is unavailable' {
        . (Join-Path $script:ProfileDir 'game-dev.ps1')

        Set-TestCommandAvailabilityState -CommandName 'blockbench' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('blockbench', [ref]$null)
        }

        $output = & { Launch-Blockbench } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'blockbench not found'
    }

    It 'Skips re-initialization when game-dev is already loaded' {
        . (Join-Path $script:ProfileDir 'game-dev.ps1')
        $firstBlockbench = Get-Command Launch-Blockbench -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'game-dev.ps1')

        (Get-Command Launch-Blockbench -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstBlockbench.ScriptBlock.ToString()
    }
}
