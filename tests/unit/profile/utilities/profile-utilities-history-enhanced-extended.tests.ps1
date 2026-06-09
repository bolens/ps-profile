# ===============================================
# profile-utilities-history-enhanced-extended.tests.ps1
# Execution tests for utilities-modules/history/utilities-history-enhanced.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
}

function script:Reset-HistoryEnhancedModuleState {
    Microsoft.PowerShell.Utility\Remove-Variable -Name 'EnhancedHistoryLoaded' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/utilities-modules/history/utilities-history-enhanced.ps1 extended scenarios' {
    BeforeEach {
        Reset-HistoryEnhancedModuleState
    }

    It 'Registers enhanced history helpers through history-enhanced.ps1' {
        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')

        Get-Command Find-HistoryFuzzy -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-HistoryQuick -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Show-HistoryStats -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:EnhancedHistoryLoaded | Should -Be $true

        $alias = Get-Alias fh -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Find-HistoryQuick'
        }
    }

    It 'Find-HistoryFuzzy returns early when no search pattern is provided' {
        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')

        Register-TestGetHistoryStub -ReturnValue @(
            [PSCustomObject]@{
                Id                 = 1
                CommandLine        = 'Get-Process'
                StartExecutionTime = Get-Date
            }
        )

        Find-HistoryFuzzy -Pattern '' -WarningAction SilentlyContinue | Out-Null

        Assert-TestGetHistoryInvoked -Times 0
    }

    It 'Skips re-initialization when enhanced history is already loaded' {
        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')
        $firstFuzzy = Get-Command Find-HistoryFuzzy -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'history-enhanced.ps1')

        (Get-Command Find-HistoryFuzzy -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstFuzzy.ScriptBlock.ToString()
    }
}
