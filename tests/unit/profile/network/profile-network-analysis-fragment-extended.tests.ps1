# ===============================================
# profile-network-analysis-fragment-extended.tests.ps1
# Execution tests for network-analysis.ps1 fragment behavior
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

function script:Reset-NetworkAnalysisFragmentState {
    Clear-FragmentLoaded -FragmentName 'network-analysis' -ErrorAction SilentlyContinue
}

Describe 'profile.d/network-analysis.ps1 extended scenarios' {
    BeforeEach {
        Reset-NetworkAnalysisFragmentState
    }

    It 'Registers network analysis helpers and marks the fragment loaded' {
        . (Join-Path $script:ProfileDir 'network-analysis.ps1')

        Get-Command Start-Wireshark -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Test-FragmentLoaded -FragmentName 'network-analysis' | Should -Be $true
    }

    It 'Start-Wireshark warns when wireshark is unavailable' {
        . (Join-Path $script:ProfileDir 'network-analysis.ps1')

        Mark-TestCommandsUnavailable -CommandNames @('wireshark')
        Set-TestCommandAvailabilityState -CommandName 'wireshark' -Available $false
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }
        if ($global:MissingToolWarnings) {
            $null = $global:MissingToolWarnings.TryRemove('wireshark', [ref]$null)
        }

        $output = Start-Wireshark 2>&1 3>&1 | Out-String
        Assert-TestMissingToolWarning -Output $output -Pattern 'wireshark not found'
    }

    It 'Skips re-initialization when network-analysis is already loaded' {
        . (Join-Path $script:ProfileDir 'network-analysis.ps1')
        $firstWireshark = Get-Command Start-Wireshark -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'network-analysis.ps1')

        (Get-Command Start-Wireshark -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstWireshark.ScriptBlock.ToString()
    }
}
