. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Performance Insights Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    }

    Context 'Performance insights functions' {
        BeforeAll {
            # Load the performance insights fragment directly to ensure functions are available
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $performanceInsightsFragment = Join-Path $script:ProfileDir '73-performance-insights.ps1'
            # Clear the guard variable to allow loading
            Remove-Variable -Name 'PerformanceInsightsLoaded' -Scope Global -ErrorAction SilentlyContinue
            . $performanceInsightsFragment
        }

        It 'Show-PerformanceInsights function is available' {
            Get-Command Show-PerformanceInsights -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-PerformanceInsights executes without error' {
            { Show-PerformanceInsights } | Should -Not -Throw
        }

        It 'Test-PerformanceHealth function is available' {
            Get-Command Test-PerformanceHealth -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Test-PerformanceHealth executes without error' {
            { Test-PerformanceHealth } | Should -Not -Throw
        }

        It 'Clear-PerformanceData function is available' {
            Get-Command Clear-PerformanceData -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Clear-PerformanceData executes without error' {
            { Clear-PerformanceData } | Should -Not -Throw
        }
    }
}
