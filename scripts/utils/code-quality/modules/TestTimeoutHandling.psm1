<#
scripts/utils/code-quality/modules/TestTimeoutHandling.psm1

.SYNOPSIS
    Test timeout handling utilities.

.DESCRIPTION
    Provides functions for executing Pester tests with timeout handling.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Try to import JsonUtilities module from scripts/lib (optional)
$jsonUtilitiesModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'utilities' 'JsonUtilities.psm1'
if ($jsonUtilitiesModulePath -and -not [string]::IsNullOrWhiteSpace($jsonUtilitiesModulePath) -and (Test-Path -LiteralPath $jsonUtilitiesModulePath)) {
    Import-Module $jsonUtilitiesModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Executes Pester tests with optional timeout handling.

.DESCRIPTION
    Runs Pester tests using the provided configuration, with optional timeout
    handling using background jobs. Provides progress updates during long-running
    test executions.

.PARAMETER Config
    The Pester configuration object.

.PARAMETER TestPaths
    Array of test paths to execute (used when timeout is enabled).

.PARAMETER Timeout
    Maximum time in seconds to allow tests to run. If not specified, runs without timeout.

.PARAMETER RunNumber
    Current run number (for multi-run scenarios).

.PARAMETER TotalRuns
    Total number of runs (for multi-run scenarios).

.OUTPUTS
    Pester test result object
#>
function Invoke-PesterWithTimeout {
    param(
        [Parameter(Mandatory)]
        $Config,

        [string[]]$TestPaths,

        [int]$Timeout,

        [int]$RunNumber = 1,

        [int]$TotalRuns = 1
    )

    if ($TotalRuns -gt 1) {
        Write-ScriptMessage -Message "Starting test run $RunNumber of $TotalRuns"
    }

    try {
        if ($Timeout -and $Timeout -gt 0) {
            Write-ScriptMessage -Message "Starting test execution with $Timeout second timeout..."

            # Validate test paths before starting job
            if ($TestPaths) {
                $invalidPaths = $TestPaths | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) -and -not (Test-Path -LiteralPath $_) }
                if ($invalidPaths.Count -gt 0) {
                    throw "Invalid test paths detected: $($invalidPaths -join ', ')"
                }
            }

            # Use runspace for test execution (much faster than job)
            $runspacePool = $null
            $powershell = $null
            $handle = $null
            
            try {
                $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1)
                $runspacePool.Open()
                
                $powershell = [PowerShell]::Create()
                $powershell.RunspacePool = $runspacePool
                
                $scriptBlock = {
                    param($TestPaths, $ConfigPath)
                    try {
                        # Suppress all confirmations in runspace context
                        $ErrorActionPreference = 'Stop'
                        $ConfirmPreference = 'None'
                        $global:ConfirmPreference = 'None'
                        
                        # Set default parameter values to suppress prompts
                        if (-not $PSDefaultParameterValues) {
                            $PSDefaultParameterValues = @{}
                        }
                        $PSDefaultParameterValues['Remove-Item:Confirm'] = $false
                        $PSDefaultParameterValues['Remove-Item:Force'] = $true
                        $PSDefaultParameterValues['Remove-Item:Recurse'] = $true
                        $PSDefaultParameterValues['Clear-Item:Confirm'] = $false
                        $PSDefaultParameterValues['Clear-Item:Force'] = $true
                        
                        # Set globally as well
                        if (-not $global:PSDefaultParameterValues) {
                            $global:PSDefaultParameterValues = @{}
                        }
                        $global:PSDefaultParameterValues['Remove-Item:Confirm'] = $false
                        $global:PSDefaultParameterValues['Remove-Item:Force'] = $true
                        $global:PSDefaultParameterValues['Remove-Item:Recurse'] = $true
                        $global:PSDefaultParameterValues['Clear-Item:Confirm'] = $false
                        $global:PSDefaultParameterValues['Clear-Item:Force'] = $true
                        
                        # Set environment variables
                        $env:PS_PROFILE_SUPPRESS_CONFIRMATIONS = '1'
                        $env:PS_PROFILE_FORCE = '1'
                        
                        Write-Host "Test execution started, running Pester tests on $($TestPaths.Count) paths..."
                        Write-Host "Paths: $($TestPaths -join ', ')"

                        # Create Pester 5 configuration
                        $config = New-PesterConfiguration
                        $config.Run.PassThru = $true
                        $config.Run.Exit = $false
                        $config.Output.Verbosity = 'Minimal'
                        
                        # Set path in configuration
                        if ($TestPaths) {
                            $config.Run.Path = $TestPaths
                        }

                        # Load configuration if provided
                        if ($ConfigPath -and -not [string]::IsNullOrWhiteSpace($ConfigPath) -and (Test-Path -LiteralPath $ConfigPath)) {
                            Write-Host "Loading configuration from: $ConfigPath"
                            if (Get-Command Read-JsonFile -ErrorAction SilentlyContinue) {
                                $loadedConfig = Read-JsonFile -Path $ConfigPath -ErrorAction SilentlyContinue
                            }
                            else {
                                $loadedConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
                            }
                            if ($loadedConfig -is [PesterConfiguration]) {
                                $config = $loadedConfig
                                if ($TestPaths) {
                                    $config.Run.Path = $TestPaths
                                }
                            }
                        }

                        # Run Pester with Pester 5 syntax
                        $result = Invoke-Pester -Configuration $config
                        Write-Host "Pester execution completed successfully"
                        return @{
                            Success = $true
                            Result  = $result
                            Error   = $null
                        }
                    }
                    catch {
                        Write-Host "Error in test execution: $($_.Exception.Message)"
                        return @{
                            Success = $false
                            Result  = $null
                            Error   = @{
                                Message    = $_.Exception.Message
                                Type       = $_.Exception.GetType().Name
                                StackTrace = $_.ScriptStackTrace
                            }
                        }
                    }
                }
                
                $null = $powershell.AddScript($scriptBlock)
                $null = $powershell.AddArgument($TestPaths)
                $null = $powershell.AddArgument($null)
                $handle = $powershell.BeginInvoke()
            }
            catch {
                Write-ScriptMessage -Message "Failed to start test execution: $($_.Exception.Message)" -LogLevel 'Error'
                throw "Failed to start test execution: $($_.Exception.Message)"
            }

            if ($null -eq $handle) {
                throw "Failed to create test execution runspace"
            }

            # Wait for completion with timeout and progress indication using polling
            $startTime = Get-Date
            $completed = $false
            $lastProgressUpdate = Get-Date
            $timeoutMs = $Timeout * 1000
            $pollIntervalMs = 5000  # Check every 5 seconds
            $elapsedMs = 0

            while (-not $completed -and $elapsedMs -lt $timeoutMs) {
                if ($handle.IsCompleted) {
                    $completed = $true
                    break
                }

                # Provide progress updates every 30 seconds
                if (((Get-Date) - $lastProgressUpdate).TotalSeconds -gt 30) {
                    $elapsed = [Math]::Round(((Get-Date) - $startTime).TotalSeconds)
                    $remaining = [Math]::Max(0, $Timeout - $elapsed)
                    $elapsedStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                        Format-LocaleNumber $elapsed -Format 'N0'
                    }
                    else {
                        $elapsed.ToString("N0")
                    }
                    $remainingStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
                        Format-LocaleNumber $remaining -Format 'N0'
                    }
                    else {
                        $remaining.ToString("N0")
                    }
                    Write-ScriptMessage -Message "Test execution in progress... Elapsed: ${elapsedStr}s, Remaining: ${remainingStr}s"
                    $lastProgressUpdate = Get-Date
                }

                Start-Sleep -Milliseconds $pollIntervalMs
                $elapsedMs += $pollIntervalMs
            }

            if ($completed) {
                # Execution completed within timeout
                try {
                    $jobResult = $powershell.EndInvoke($handle)
                }
                catch {
                    throw "Failed to receive execution result: $($_.Exception.Message)"
                }
                finally {
                    # Clean up runspace
                    if ($powershell) {
                        $powershell.Dispose()
                    }
                    if ($runspacePool) {
                        $runspacePool.Close()
                        $runspacePool.Dispose()
                    }
                }

                if ($null -eq $jobResult) {
                    throw "Test execution completed but returned no result"
                }

                if ($jobResult.Success) {
                    $result = $jobResult.Result
                    Write-ScriptMessage -Message "Test execution completed within timeout"
                }
                else {
                    throw "Test execution failed: $($jobResult.Error.Message)"
                }
            }
            else {
                # Execution timed out - attempt graceful shutdown
                Write-ScriptMessage -Message "Test execution timed out after $Timeout seconds. Attempting graceful shutdown..." -LogLevel 'Warning'

                # Try to stop runspace gracefully
                if ($powershell) {
                    $powershell.Stop()
                }

                # Wait a bit for graceful shutdown
                Start-Sleep -Seconds 2

                # Clean up runspaces
                try {
                    if ($powershell) {
                        $powershell.Dispose()
                    }
                    if ($runspacePool) {
                        $runspacePool.Close()
                        $runspacePool.Dispose()
                    }
                }
                catch {
                    # Ignore errors when cleaning up runspaces
                }
                throw "Test execution timed out after $Timeout seconds"
            }
        }
        else {
            Write-ScriptMessage -Message "Starting test execution..."
            # Set path in configuration before invoking (cannot use both -Configuration and -Path together)
            if ($TestPaths) {
                $Config.Run.Path = $TestPaths
            }
            $result = Invoke-Pester -Configuration $Config
        }
    }
    catch {
        Write-ScriptMessage -Message "Test execution failed: $($_.Exception.Message)" -LogLevel 'Error'

        # Provide recovery suggestions based on error type
        $errorMessage = $_.Exception.Message.ToLower()
        if ($errorMessage -contains 'timeout') {
            Write-ScriptMessage -Message "Suggestion: Consider increasing timeout value or optimizing slow tests" -LogLevel 'Info'
        }
        elseif ($errorMessage -contains 'path' -or $errorMessage -contains 'not found') {
            Write-ScriptMessage -Message "Suggestion: Verify test file paths and ensure test files exist" -LogLevel 'Info'
        }
        elseif ($errorMessage -contains 'module' -or $errorMessage -contains 'import') {
            Write-ScriptMessage -Message "Suggestion: Check module dependencies and PowerShell module path" -LogLevel 'Info'
        }
        elseif ($errorMessage -contains 'permission' -or $errorMessage -contains 'access denied') {
            Write-ScriptMessage -Message "Suggestion: Run with appropriate permissions or check file access rights" -LogLevel 'Info'
        }

        throw
    }

    if ($TotalRuns -gt 1) {
        Write-ScriptMessage -Message "Completed test run $RunNumber of $TotalRuns - Passed: $($result.PassedCount), Failed: $($result.FailedCount)"
    }

    return $result
}

Export-ModuleMember -Function Invoke-PesterWithTimeout

