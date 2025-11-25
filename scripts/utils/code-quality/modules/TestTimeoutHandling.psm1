<#
scripts/utils/code-quality/modules/TestTimeoutHandling.psm1

.SYNOPSIS
    Test timeout handling utilities.

.DESCRIPTION
    Provides functions for executing Pester tests with timeout handling.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'Logging.psm1'
if (Test-Path $loggingModulePath) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Try to import JsonUtilities module from scripts/lib (optional)
$jsonUtilitiesModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'JsonUtilities.psm1'
if (Test-Path $jsonUtilitiesModulePath) {
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
                $invalidPaths = $TestPaths | Where-Object { -not (Test-Path $_) }
                if ($invalidPaths.Count -gt 0) {
                    throw "Invalid test paths detected: $($invalidPaths -join ', ')"
                }
            }

            # Start job with error handling
            $job = $null
            try {
                $job = Start-Job -ScriptBlock {
                    param($TestPaths, $ConfigPath)
                    try {
                        Write-Host "Job started, running Pester tests on $($TestPaths.Count) paths..."
                        Write-Host "Paths: $($TestPaths -join ', ')"

                        # Create Pester 5 configuration
                        $config = New-PesterConfiguration
                        $config.Run.PassThru = $true
                        $config.Run.Exit = $false
                        $config.Output.Verbosity = 'Minimal'
                        $config.Run.Path = $TestPaths

                        # Load configuration in job if provided (override defaults)
                        if ($ConfigPath -and (Test-Path $ConfigPath)) {
                            Write-Host "Loading configuration from: $ConfigPath"
                            if (Get-Command Read-JsonFile -ErrorAction SilentlyContinue) {
                                $loadedConfig = Read-JsonFile -Path $ConfigPath -ErrorAction SilentlyContinue
                            }
                            else {
                                $loadedConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
                            }
                            # If loaded config is a PesterConfiguration, use it; otherwise merge properties
                            if ($loadedConfig -is [PesterConfiguration]) {
                                $config = $loadedConfig
                                $config.Run.Path = $TestPaths
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
                        Write-Host "Error in job: $($_.Exception.Message)"
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
                } -ArgumentList $TestPaths, $null -ErrorAction Stop
            }
            catch {
                Write-ScriptMessage -Message "Failed to start test job: $($_.Exception.Message)" -LogLevel 'Error'
                throw "Failed to start test execution job: $($_.Exception.Message)"
            }

            if ($null -eq $job) {
                throw "Failed to create test execution job"
            }

            # Wait for job completion with timeout and progress indication
            $startTime = Get-Date
            $completed = $false
            $lastProgressUpdate = Get-Date

            while (-not $completed -and ((Get-Date) - $startTime).TotalSeconds -lt $Timeout) {
                $completed = Wait-Job -Job $job -Timeout 5  # Check every 5 seconds

                # Provide progress updates every 30 seconds
                if (((Get-Date) - $lastProgressUpdate).TotalSeconds -gt 30) {
                    $elapsed = [Math]::Round(((Get-Date) - $startTime).TotalSeconds)
                    $remaining = [Math]::Max(0, $Timeout - $elapsed)
                    Write-ScriptMessage -Message "Test execution in progress... Elapsed: ${elapsed}s, Remaining: ${remaining}s"
                    $lastProgressUpdate = Get-Date
                }

                # Check if job is still running
                if (-not $completed) {
                    $jobState = $job.State
                    if ($jobState -eq 'Failed') {
                        throw "Job failed before timeout"
                    }
                }
            }

            if ($completed) {
                # Job completed within timeout
                try {
                    $jobResult = Receive-Job -Job $job -ErrorAction Stop
                }
                catch {
                    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
                    throw "Failed to receive job results: $($_.Exception.Message)"
                }
                finally {
                    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
                }

                if ($null -eq $jobResult) {
                    throw "Job completed but returned no result"
                }

                if ($jobResult.Success) {
                    $result = $jobResult.Result
                    Write-ScriptMessage -Message "Test execution completed within timeout"
                }
                else {
                    throw "Test execution failed in job: $($jobResult.Error.Message)"
                }
            }
            else {
                # Job timed out - attempt graceful shutdown
                Write-ScriptMessage -Message "Test execution timed out after $Timeout seconds. Attempting graceful shutdown..." -LogLevel 'Warning'

                # Try to stop job gracefully first
                Stop-Job -Job $job -Confirm:$false -ErrorAction SilentlyContinue

                # Wait a bit for graceful shutdown
                Start-Sleep -Seconds 5

                # Force stop if still running
                if ($job.State -eq 'Running') {
                    Write-ScriptMessage -Message "Force stopping timed out job..." -LogLevel 'Warning'
                    Stop-Job -Job $job -Confirm:$false
                }

                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
                throw "Test execution timed out after $Timeout seconds"
            }
        }
        else {
            Write-ScriptMessage -Message "Starting test execution..."
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

