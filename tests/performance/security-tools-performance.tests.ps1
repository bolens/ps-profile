<#
.SYNOPSIS
    Performance tests for security-tools.ps1 fragment.

.DESCRIPTION
    Tests that the security-tools fragment loads within acceptable time limits
    and that function registration is performant.
#>

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Security Tools Fragment Performance Tests' {
    BeforeAll {
        try {
            $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
            if (-not (Test-Path -LiteralPath $script:ProfileDir)) {
                throw "Profile directory not found at: $script:ProfileDir"
            }
            
            $script:SecurityToolsPath = Join-Path $script:ProfileDir 'security-tools.ps1'
            if (-not (Test-Path -LiteralPath $script:SecurityToolsPath)) {
                throw "Security tools fragment not found at: $script:SecurityToolsPath"
            }

            # Baseline performance metrics (in milliseconds)
            # Based on typical fragment load times with 3x safety margin
            $script:MaxFragmentLoadTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_SECURITY_TOOLS_MAX_LOAD_MS' -Default 500
            $script:MaxFunctionRegistrationTimeMs = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_SECURITY_TOOLS_MAX_FUNCTION_MS' -Default 100
        }
        catch {
            $errorDetails = @{
                Message  = $_.Exception.Message
                Type     = $_.Exception.GetType().FullName
                Location = $_.InvocationInfo.ScriptLineNumber
            }
            Write-Error "Failed to initialize security tools performance tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
            throw
        }
    }

    Context 'Fragment Load Performance' {
        It 'security-tools fragment loads within acceptable time limit' {
            # Load bootstrap first
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if (Test-Path -LiteralPath $bootstrapPath) {
                . $bootstrapPath -ErrorAction SilentlyContinue
            }

            # Measure fragment load time
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                . $script:SecurityToolsPath -ErrorAction Stop
            }
            finally {
                $stopwatch.Stop()
            }

            $loadTimeMs = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Security tools fragment loaded in $([Math]::Round($loadTimeMs, 2)) ms" -Verbose

            $loadTimeMs | Should -BeLessThan $script:MaxFragmentLoadTimeMs
        }

        It 'fragment load time is consistent across multiple loads' {
            # Load bootstrap first
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if (Test-Path -LiteralPath $bootstrapPath) {
                . $bootstrapPath -ErrorAction SilentlyContinue
            }

            $loadTimes = @()
            for ($i = 0; $i -lt 3; $i++) {
                # Remove functions to simulate fresh load
                Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-TruffleHogScan -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-OSVScan -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-YaraScan -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-ClamAVScan -ErrorAction SilentlyContinue
                Remove-Item Function:\Invoke-DangerzoneConvert -ErrorAction SilentlyContinue

                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    . $script:SecurityToolsPath -ErrorAction Stop
                }
                finally {
                    $stopwatch.Stop()
                }
                $loadTimes += $stopwatch.Elapsed.TotalMilliseconds
            }

            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $maxLoadTime = ($loadTimes | Measure-Object -Maximum).Maximum
            $minLoadTime = ($loadTimes | Measure-Object -Minimum).Minimum
            $variance = $maxLoadTime - $minLoadTime

            Write-Verbose "Load times: min=$([Math]::Round($minLoadTime, 2))ms, max=$([Math]::Round($maxLoadTime, 2))ms, avg=$([Math]::Round($avgLoadTime, 2))ms, variance=$([Math]::Round($variance, 2))ms" -Verbose

            # Variance should be reasonable (less than 50% of average)
            $variancePercent = if ($avgLoadTime -gt 0) { ($variance / $avgLoadTime) * 100 } else { 0 }
            $variancePercent | Should -BeLessThan 50
        }
    }

    Context 'Function Registration Performance' {
        BeforeAll {
            # Load bootstrap and fragment once
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if (Test-Path -LiteralPath $bootstrapPath) {
                . $bootstrapPath -ErrorAction SilentlyContinue
            }
            . $script:SecurityToolsPath -ErrorAction SilentlyContinue
        }

        It 'function registration does not cause performance regression' {
            # Measure time to check if functions exist (simulating function lookup)
            $functions = @(
                'Invoke-GitLeaksScan',
                'Invoke-TruffleHogScan',
                'Invoke-OSVScan',
                'Invoke-YaraScan',
                'Invoke-ClamAVScan',
                'Invoke-DangerzoneConvert'
            )

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            foreach ($func in $functions) {
                $null = Get-Command $func -ErrorAction SilentlyContinue
            }
            $stopwatch.Stop()

            $lookupTimeMs = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Function lookup for $($functions.Count) functions took $([Math]::Round($lookupTimeMs, 2)) ms" -Verbose

            $lookupTimeMs | Should -BeLessThan $script:MaxFunctionRegistrationTimeMs
        }

        It 'alias resolution is performant' {
            $aliases = @(
                'gitleaks-scan',
                'trufflehog-scan',
                'osv-scan',
                'yara-scan',
                'clamav-scan',
                'dangerzone'
            )

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            foreach ($alias in $aliases) {
                $null = Get-Alias $alias -ErrorAction SilentlyContinue
            }
            $stopwatch.Stop()

            $lookupTimeMs = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Alias lookup for $($aliases.Count) aliases took $([Math]::Round($lookupTimeMs, 2)) ms" -Verbose

            $lookupTimeMs | Should -BeLessThan $script:MaxFunctionRegistrationTimeMs
        }
    }

    Context 'Idempotency Performance' {
        BeforeAll {
            # Load bootstrap and fragment once
            $bootstrapPath = Join-Path $script:ProfileDir 'bootstrap.ps1'
            if (Test-Path -LiteralPath $bootstrapPath) {
                . $bootstrapPath -ErrorAction SilentlyContinue
            }
            . $script:SecurityToolsPath -ErrorAction SilentlyContinue
        }

        It 'repeated fragment loads are fast (idempotency check overhead is minimal)' {
            $firstLoadTime = 0
            $secondLoadTime = 0

            # Remove functions to simulate fresh load
            Remove-Item Function:\Invoke-GitLeaksScan -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-TruffleHogScan -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-OSVScan -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-YaraScan -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-ClamAVScan -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-DangerzoneConvert -ErrorAction SilentlyContinue

            # First load
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:SecurityToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            $firstLoadTime = $stopwatch.Elapsed.TotalMilliseconds

            # Second load (should be fast due to idempotency check)
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:SecurityToolsPath -ErrorAction SilentlyContinue
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

