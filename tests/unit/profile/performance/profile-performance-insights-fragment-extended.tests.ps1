# ===============================================
# profile-performance-insights-fragment-extended.tests.ps1
# Execution tests for performance-insights.ps1 fragment behavior
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

function script:Reset-PerformanceInsightsFragmentState {
    if (Test-Path -Path Variable:global:PerformanceInsightsLoaded) {
        Remove-Variable -Name 'PerformanceInsightsLoaded' -Scope Global -Force
    }

    $global:PSProfileCommandTimings = $null
    $global:PSProfileCommandTrackingSetup = $false
}

Describe 'profile.d/performance-insights.ps1 extended scenarios' {
    BeforeEach {
        Reset-PerformanceInsightsFragmentState
    }

    It 'Loads performance insight commands from diagnostics-performance module' {
        . (Join-Path $script:ProfileDir 'performance-insights.ps1')

        Get-Command Show-PerformanceInsights -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-PerformanceHealth -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Variable -Name 'PerformanceInsightsLoaded' -Scope Global -ErrorAction Stop).Value | Should -Be $true
    }

    It 'Show-PerformanceInsights executes without throwing' {
        . (Join-Path $script:ProfileDir 'performance-insights.ps1')

        { Show-PerformanceInsights } | Should -Not -Throw
    }

    It 'Skips re-initialization when performance insights are already loaded' {
        . (Join-Path $script:ProfileDir 'performance-insights.ps1')
        $firstInsights = Get-Command Show-PerformanceInsights -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'performance-insights.ps1')

        (Get-Command Show-PerformanceInsights -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstInsights.ScriptBlock.ToString()
    }
}
