

Describe 'Performance Insights Integration Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if ($null -eq $script:ProfileDir -or [string]::IsNullOrWhiteSpace($script:ProfileDir)) {
                throw "Get-TestPath returned null or empty value for ProfileDir"
            }
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize performance insights tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Performance insights functions' {
        BeforeAll {
            # Load the performance insights fragment directly to ensure functions are available
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $performanceInsightsFragment = Join-Path $script:ProfileDir 'performance-insights.ps1'
            # Clear the guard variable to allow loading
            Remove-Variable -Name 'PerformanceInsightsLoaded' -Scope Global -ErrorAction SilentlyContinue
            . $performanceInsightsFragment
        }

        It 'Show-PerformanceInsights function is available' {
            Get-Command Show-PerformanceInsights -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Show-PerformanceInsights executes without error' {
            try {
                { Show-PerformanceInsights } | Should -Not -Throw -Because "Show-PerformanceInsights should execute without errors"
            }
            catch {
                $errorDetails = @{
                    Message  = $_.Exception.Message
                    Category = $_.CategoryInfo.Category
                }
                Write-Error "Show-PerformanceInsights execution test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
                throw
            }
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

    Context 'Update-PerformanceInsightsPrompt function' {
        BeforeAll {
            # Load the performance insights fragment
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            $performanceInsightsFragment = Join-Path $script:ProfileDir 'performance-insights.ps1'
            Remove-Variable -Name 'PerformanceInsightsLoaded' -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name 'PSProfileOriginalPrompt' -Scope Global -ErrorAction SilentlyContinue
            . $performanceInsightsFragment
        }

        It 'Update-PerformanceInsightsPrompt function is available' {
            Get-Command Update-PerformanceInsightsPrompt -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Update-PerformanceInsightsPrompt wraps existing prompt' {
            # Store original prompt if it exists
            $originalPrompt = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
            
            # Create a simple test prompt function
            Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            function global:prompt { return "TEST> " }
            
            # Clear the stored prompt to force re-wrapping
            Remove-Variable -Name 'PSProfileOriginalPrompt' -Scope Global -ErrorAction SilentlyContinue
            
            # Call Update-PerformanceInsightsPrompt
            { Update-PerformanceInsightsPrompt } | Should -Not -Throw
            
            # Verify prompt was wrapped (should still exist but now wrapped)
            $promptCmd = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
            $promptCmd | Should -Not -Be $null
            
            # Verify the wrapped prompt references the original
            $promptScript = $promptCmd.ScriptBlock.ToString()
            $promptScript | Should -Match 'PSProfileOriginalPrompt'
        }

        It 'Update-PerformanceInsightsPrompt handles missing prompt gracefully' {
            # Remove any existing prompt
            Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            Remove-Variable -Name 'PSProfileOriginalPrompt' -Scope Global -ErrorAction SilentlyContinue
            
            # Should not throw
            { Update-PerformanceInsightsPrompt } | Should -Not -Throw
            
            # Should create a prompt function
            $promptCmd = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
            $promptCmd | Should -Not -Be $null
        }

        It 'Update-PerformanceInsightsPrompt can be called multiple times safely' {
            # Should not throw on repeated calls (idempotent)
            { Update-PerformanceInsightsPrompt } | Should -Not -Throw
            { Update-PerformanceInsightsPrompt } | Should -Not -Throw
            { Update-PerformanceInsightsPrompt } | Should -Not -Throw
        }

        It 'Update-PerformanceInsightsPrompt prevents double-wrapping' {
            # Create a prompt that's already wrapped
            Remove-Item Function:\global:prompt -ErrorAction SilentlyContinue
            function global:prompt {
                if ($global:PSProfileCommandTimer) { Stop-CommandTimer }
                "WRAPPED> "
                Start-CommandTimer -CommandName "prompt"
            }
            
            # Call Update-PerformanceInsightsPrompt - should detect it's already wrapped
            { Update-PerformanceInsightsPrompt } | Should -Not -Throw
            
            # Should still have a prompt
            $promptCmd = Get-Command prompt -CommandType Function -ErrorAction SilentlyContinue
            $promptCmd | Should -Not -Be $null
        }
    }
}


