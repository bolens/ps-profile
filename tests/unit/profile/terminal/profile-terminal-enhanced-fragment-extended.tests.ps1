# ===============================================
# profile-terminal-enhanced-fragment-extended.tests.ps1
# Execution tests for terminal-enhanced.ps1 fragment behavior
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

function script:Reset-TerminalEnhancedFragmentState {
    Clear-FragmentLoaded -FragmentName 'terminal-enhanced' -ErrorAction SilentlyContinue
}

Describe 'profile.d/terminal-enhanced.ps1 extended scenarios' {
    BeforeEach {
        Reset-TerminalEnhancedFragmentState
    }

    It 'Registers terminal emulator helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')

        Get-Command Launch-Alacritty -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Launch-Kitty -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-TerminalInfo -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'terminal-enhanced' | Should -Be $true
    }

    It 'Launch-Alacritty warns when alacritty is unavailable' {
        . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')

        Set-TestCommandAvailabilityState -CommandName 'alacritty' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('alacritty', [ref]$null)
        }

        $output = & { Launch-Alacritty } 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'alacritty not found'
    }

    It 'Skips re-initialization when terminal-enhanced is already loaded' {
        . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')
        $firstLaunch = Get-Command Launch-Alacritty -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'terminal-enhanced.ps1')

        (Get-Command Launch-Alacritty -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstLaunch.ScriptBlock.ToString()
    }
}
