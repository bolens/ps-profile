<#
.SYNOPSIS
    Performance tests for security-tools.ps1 fragment.

.DESCRIPTION
    Tests that the security-tools fragment loads within acceptable time limits
    and that function registration is performant.
#>

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
}

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

            $script:SecurityToolAliases = [ordered]@{
                'gitleaks-scan'      = 'Invoke-GitLeaksScan'
                'trufflehog-scan'    = 'Invoke-TruffleHogScan'
                'osv-scan'           = 'Invoke-OSVScan'
                'yara-scan'          = 'Invoke-YaraScan'
                'clamav-scan'        = 'Invoke-ClamAVScan'
                'dangerzone-convert' = 'Invoke-DangerzoneConvert'
            }
            $script:OriginalSecurityToolsMarker = Get-Variable -Name 'security-toolsLoaded' -Scope Global -ErrorAction SilentlyContinue
            $script:OriginalSecurityToolsFunctions = @{}
            $script:OriginalSecurityToolsAliases = @{}
            foreach ($entry in $script:SecurityToolAliases.GetEnumerator()) {
                $script:OriginalSecurityToolsFunctions[$entry.Value] = Get-Command $entry.Value -CommandType Function -ErrorAction SilentlyContinue
                $script:OriginalSecurityToolsAliases[$entry.Key] = Get-Alias $entry.Key -Scope Global -ErrorAction SilentlyContinue
            }

            # Use the real state helpers locally instead of depending on earlier test imports.
            $moduleImportPath = Join-Path (Split-Path -Parent $script:ProfileDir) 'scripts/lib/ModuleImport.psm1'
            Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
            $idempotencyModule = Import-LibModule -ModuleName FragmentIdempotency -ScriptPath $PSScriptRoot -DisableNameChecking
            Import-Module -ModuleInfo $idempotencyModule -Scope Local -DisableNameChecking -ErrorAction Stop

            function Reset-SecurityToolsPerformanceState {
                Clear-FragmentLoaded -FragmentName 'security-tools' -ErrorAction Stop
                foreach ($entry in $script:SecurityToolAliases.GetEnumerator()) {
                    # The fragment defines a local function and publishes a global wrapper.
                    $functionPath = "Function:\$($entry.Value)"
                    Remove-Item -LiteralPath $functionPath -Force -ErrorAction SilentlyContinue
                    Remove-Item -LiteralPath $functionPath -Force -ErrorAction SilentlyContinue
                    Remove-Alias -Name $entry.Key -Scope Global -Force -ErrorAction SilentlyContinue
                }
            }

            . (Join-Path $script:ProfileDir 'bootstrap.ps1') -ErrorAction Stop

            # Baseline performance metrics (in milliseconds)
            Initialize-FragmentPerformanceThresholds -Prefix 'SECURITY_TOOLS' -LoadMs 10000 -FunctionMs 4000 -IdempotencyMs 4000
            $script:MaxFunctionRegistrationTimeMs = $script:MaxFunctionExecTimeMs
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

    BeforeEach {
        . Reset-SecurityToolsPerformanceState
    }

    AfterAll {
        . Reset-SecurityToolsPerformanceState
        foreach ($entry in $script:SecurityToolAliases.GetEnumerator()) {
            $command = $script:OriginalSecurityToolsFunctions[$entry.Value]
            if ($null -ne $command) {
                Set-Item -LiteralPath "Function:\global:$($entry.Value)" -Value $command.ScriptBlock -Options $command.Options -Force
            }
            $alias = $script:OriginalSecurityToolsAliases[$entry.Key]
            if ($null -ne $alias) {
                Set-Alias -Name $alias.Name -Value $alias.Definition -Option $alias.Options -Description $alias.Description -Scope Global -Force
            }
        }
        if ($null -ne $script:OriginalSecurityToolsMarker) {
            Set-Variable -Name 'security-toolsLoaded' -Scope Global -Value $script:OriginalSecurityToolsMarker.Value -Force
        }
    }

    Context 'Fragment Load Performance' {
        It 'security-tools fragment loads within acceptable time limit' {
            try {
                # Measure fragment load time
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                . $script:SecurityToolsPath -ErrorAction Stop
            }
            finally {
                $stopwatch.Stop()

                $loadTimeMs = $stopwatch.Elapsed.TotalMilliseconds
                Write-Verbose "Security tools fragment loaded in $([Math]::Round($loadTimeMs, 2)) ms" -Verbose

                $loadTimeMs | Should -BeLessThan $script:MaxFragmentLoadTimeMs
            }
            Test-FragmentLoaded -FragmentName 'security-tools' | Should -BeTrue
            foreach ($functionName in $script:SecurityToolAliases.Values) {
                Get-Command -Name $functionName -CommandType Function -ErrorAction Stop | Should -Not -BeNullOrEmpty
            }
        }

        It 'fresh fragment loads register every command within the load budget' {
            $loadTimes = @()
            for ($i = 0; $i -lt 3; $i++) {
                . Reset-SecurityToolsPerformanceState
                Test-FragmentLoaded -FragmentName 'security-tools' | Should -BeFalse
                foreach ($entry in $script:SecurityToolAliases.GetEnumerator()) {
                    Get-Command $entry.Value -CommandType Function -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                    Get-Alias $entry.Key -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                }

                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    . $script:SecurityToolsPath -ErrorAction Stop
                }
                finally {
                    $stopwatch.Stop()
                    $loadTimes += $stopwatch.Elapsed.TotalMilliseconds
                }
                $loadTimes[-1] | Should -BeLessThan $script:MaxFragmentLoadTimeMs
                Test-FragmentLoaded -FragmentName 'security-tools' | Should -BeTrue
                foreach ($entry in $script:SecurityToolAliases.GetEnumerator()) {
                    Get-Command -Name $entry.Value -CommandType Function -ErrorAction Stop | Should -Not -BeNullOrEmpty
                    (Get-Alias -Name $entry.Key -ErrorAction Stop).Definition | Should -Be $entry.Value
                }
            }

            $avgLoadTime = ($loadTimes | Measure-Object -Average).Average
            $maxLoadTime = ($loadTimes | Measure-Object -Maximum).Maximum
            $minLoadTime = ($loadTimes | Measure-Object -Minimum).Minimum
            $variance = $maxLoadTime - $minLoadTime

            Write-Verbose "Load times: min=$([Math]::Round($minLoadTime, 2))ms, max=$([Math]::Round($maxLoadTime, 2))ms, avg=$([Math]::Round($avgLoadTime, 2))ms, variance=$([Math]::Round($variance, 2))ms" -Verbose

            # Scheduler variation is diagnostic; every fresh load retains the configured budget.
            $variancePercent = if ($avgLoadTime -gt 0) { ($variance / $avgLoadTime) * 100 } else { 0 }
            Write-Verbose "Load sample variation: $([Math]::Round($variancePercent, 2))%" -Verbose
        }
    }

    Context 'Function Registration Performance' {
        It 'function registration does not cause performance regression' {
            . $script:SecurityToolsPath -ErrorAction Stop
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
            $registeredCommands = foreach ($func in $functions) {
                Get-Command $func -CommandType Function -ErrorAction Stop
            }
            $stopwatch.Stop()

            $registeredCommands.Count | Should -Be $functions.Count
            foreach ($command in $registeredCommands) {
                $command | Should -Not -BeNullOrEmpty
            }

            $lookupTimeMs = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Function lookup for $($functions.Count) functions took $([Math]::Round($lookupTimeMs, 2)) ms" -Verbose

            $lookupTimeMs | Should -BeLessThan $script:MaxFunctionRegistrationTimeMs
        }

        It 'alias resolution is performant' {
            . $script:SecurityToolsPath -ErrorAction Stop
            $aliases = @(
                'gitleaks-scan',
                'trufflehog-scan',
                'osv-scan',
                'yara-scan',
                'clamav-scan',
                'dangerzone-convert'
            )

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $registeredAliases = foreach ($alias in $aliases) {
                Get-Alias $alias -ErrorAction Stop
            }
            $stopwatch.Stop()

            $registeredAliases.Count | Should -Be $aliases.Count
            foreach ($alias in $registeredAliases) {
                $alias.Definition | Should -Be $script:SecurityToolAliases[$alias.Name]
            }

            $lookupTimeMs = $stopwatch.Elapsed.TotalMilliseconds
            Write-Verbose "Alias lookup for $($aliases.Count) aliases took $([Math]::Round($lookupTimeMs, 2)) ms" -Verbose

            $lookupTimeMs | Should -BeLessThan $script:MaxFunctionRegistrationTimeMs
        }
    }

    Context 'Idempotency Performance' {
        It 'repeated fragment loads are fast (idempotency check overhead is minimal)' {
            $firstLoadTime = 0
            $secondLoadTime = 0

            # First load
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:SecurityToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            $firstLoadTime = $stopwatch.Elapsed.TotalMilliseconds

            Test-FragmentLoaded -FragmentName 'security-tools' | Should -BeTrue
            $registeredFunctions = @{}
            foreach ($functionName in $script:SecurityToolAliases.Values) {
                $registeredFunctions[$functionName] = (Get-Command $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
            }

            # Second load (should be fast due to idempotency check)
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $script:SecurityToolsPath -ErrorAction SilentlyContinue
            $stopwatch.Stop()
            $secondLoadTime = $stopwatch.Elapsed.TotalMilliseconds

            Write-Verbose "First load: $([Math]::Round($firstLoadTime, 2))ms, Second load: $([Math]::Round($secondLoadTime, 2))ms" -Verbose

            # Second load should be fast due to the idempotency early-exit.
            $secondLoadTime | Should -BeLessThan $script:MaxIdempotencyTimeMs
            foreach ($entry in $script:SecurityToolAliases.GetEnumerator()) {
                $command = Get-Command $entry.Value -CommandType Function -ErrorAction Stop
                [object]::ReferenceEquals($registeredFunctions[$entry.Value], $command.ScriptBlock) | Should -BeTrue
                (Get-Alias $entry.Key -ErrorAction Stop).Definition | Should -Be $entry.Value
            }
        }
    }
}
