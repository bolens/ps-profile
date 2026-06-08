# ===============================================
# profile-history-enhanced-fragment-extended.tests.ps1
# Execution tests for history-enhanced.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-HistoryEnhancedFragmentState {
    Remove-Variable -Name 'EnhancedHistoryLoaded' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/history-enhanced.ps1 extended scenarios' {
    BeforeEach {
        Reset-HistoryEnhancedFragmentState
    }

    It 'Loads Find-HistoryQuick and the fh alias from the enhanced history module' {
        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')

        Get-Command Find-HistoryQuick -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command fh -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Variable -Name 'EnhancedHistoryLoaded' -Scope Global -ErrorAction Stop).Value | Should -Be $true
    }

    It 'Find-HistoryQuick executes without error for a search pattern' {
        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')

        { Find-HistoryQuick -Pattern 'history-enhanced' } | Should -Not -Throw
    }

    It 'Skips re-initialization when enhanced history is already loaded' {
        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')
        $firstQuick = Get-Command Find-HistoryQuick -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')

        (Get-Command Find-HistoryQuick -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstQuick.ScriptBlock.ToString()
    }
}
