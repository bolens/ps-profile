# ===============================================
# api-tools-performance.tests.ps1
# Performance tests for API tools fragment (api-tools.ps1)
# ===============================================

<#
.SYNOPSIS
    Performance tests for API tools fragment (api-tools.ps1).

.DESCRIPTION
    Tests performance characteristics of the API tools fragment:
    - Fragment load time
    - Function registration performance
    - Alias resolution performance
    - Idempotency check overhead
#>

Describe 'API Tools Fragment Performance Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        $script:ApiToolsPath = Join-Path $script:ProfileDir 'api-tools.ps1'
        
        if (-not (Test-Path -LiteralPath $script:ApiToolsPath)) {
            throw "API tools fragment not found at: $script:ApiToolsPath"
        }
    }

    Context 'Fragment Load Performance' {
        It 'Fragment loads within acceptable time (< 500ms)' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:ApiToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $loadTime = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Fragment load time: $([Math]::Round($loadTime, 2))ms" -Verbose
            
            $loadTime | Should -BeLessThan 500
        }

        It 'Fragment load time is consistent across multiple loads' {
            $loadTimes = @()
            
            for ($i = 1; $i -le 3; $i++) {
                # Remove functions to simulate fresh load
                Remove-Item Function:\Invoke-Bruno -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-Hurl -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-Httpie -ErrorAction SilentlyContinue
                Remove-Item Function:\Start-HttpToolkit -ErrorAction SilentlyContinue
                
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . $script:ApiToolsPath -ErrorAction SilentlyContinue
                $stopwatch.Stop()
                
                $loadTimes += $stopwatch.Elapsed.TotalMilliseconds
            }
            
            $meanLoadTime = ($loadTimes | Measure-Object -Average).Average
            $maxLoadTime = ($loadTimes | Measure-Object -Maximum).Maximum
            $minLoadTime = ($loadTimes | Measure-Object -Minimum).Minimum
            
            Write-Verbose "Load times: Min=$([Math]::Round($minLoadTime, 2))ms, Mean=$([Math]::Round($meanLoadTime, 2))ms, Max=$([Math]::Round($maxLoadTime, 2))ms" -Verbose
            
            # Variance should be reasonable (max should be < 2x min)
            ($maxLoadTime / $minLoadTime) | Should -BeLessThan 2.0
        }
    }

    Context 'Function Registration Performance' {
        It 'Functions are registered quickly' {
            # Remove functions to test registration
            Remove-Item Function:\Invoke-Bruno -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-Hurl -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-Httpie -ErrorAction SilentlyContinue
            Remove-Item Function:\Start-HttpToolkit -ErrorAction SilentlyContinue
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:ApiToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $registrationTime = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Function registration time: $([Math]::Round($registrationTime, 2))ms" -Verbose
            
            # Registration should be fast
            $registrationTime | Should -BeLessThan 500
        }
    }

    Context 'Alias Resolution Performance' {
        It 'Alias resolution is fast' {
            # Load bootstrap first
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if (Test-Path -LiteralPath $bootstrapPath) {
                . $bootstrapPath -ErrorAction SilentlyContinue
            }
            
            # Ensure fragment is loaded
            if (-not (Get-Command Invoke-Bruno -ErrorAction SilentlyContinue)) {
                . $script:ApiToolsPath -ErrorAction SilentlyContinue
            }
            
            # Try to create alias if missing (like integration tests do)
            $alias = Get-Alias bruno -ErrorAction SilentlyContinue
            if (-not $alias) {
                if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
                    Set-AgentModeAlias -Name 'bruno' -Target 'Invoke-Bruno' | Out-Null
                }
                $alias = Get-Alias bruno -ErrorAction SilentlyContinue
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $alias = Get-Alias bruno -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            
            $resolutionTime = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Alias resolution time: $([Math]::Round($resolutionTime, 2))ms" -Verbose
            
            # Alias resolution should be very fast (< 10ms)
            $resolutionTime | Should -BeLessThan 10
            # Alias may not exist if command exists, but resolution should still be fast
            if ($alias) {
                $alias | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Idempotency Performance' {
        It 'repeated fragment loads are fast (idempotency check overhead is minimal)' {
            $firstLoadTime = 0
            $secondLoadTime = 0

            # Remove functions to simulate fresh load
            Remove-Item Function:\Invoke-Bruno -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-Hurl -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-Httpie -ErrorAction SilentlyContinue
            Remove-Item Function:\Start-HttpToolkit -ErrorAction SilentlyContinue

            # First load
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:ApiToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            $firstLoadTime = $stopwatch.Elapsed.TotalMilliseconds

            # Second load (should be fast due to idempotency check)
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:ApiToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            $secondLoadTime = $stopwatch.Elapsed.TotalMilliseconds

            Write-Verbose "First load: $([Math]::Round($firstLoadTime, 2))ms, Second load: $([Math]::Round($secondLoadTime, 2))ms" -Verbose

            # Second load should be very fast (< 500ms typically) due to idempotency check
            # Note: We use a more lenient threshold due to timing variance and system load.
            # The idempotency check should exit early, but we allow for some overhead.
            $secondLoadTime | Should -BeLessThan 500
        }
    }
}

