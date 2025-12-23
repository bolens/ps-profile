<#
scripts/lib/fragment/FragmentParallelLoading.psm1

.SYNOPSIS
    EXPERIMENTAL: Parallel fragment loading utilities using PowerShell runspaces.

.DESCRIPTION
    Provides functions for loading profile fragments in parallel using PowerShell runspaces.
    Uses a hybrid approach: attempts parallel execution, then falls back to sequential
    loading if parallel execution fails or encounters issues.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 5.1+ (requires runspaces)
    
    WARNING: This is an experimental feature. Enable via PS_PROFILE_PARALLEL_LOADING=1
#>

<#
.SYNOPSIS
    EXPERIMENTAL: Hybrid parallel fragment loading with sequential fallback.

.DESCRIPTION
    Attempts to load fragments at the same dependency level in parallel using runspaces.
    If parallel loading fails or encounters issues, automatically falls back to sequential loading.
    This hybrid approach provides speed benefits when possible while maintaining reliability.
    
    The hybrid approach works by:
    1. Executing fragments in parallel runspaces to validate they can load
    2. If all succeed, re-executing them sequentially to properly merge into main session
    3. If any fail or timeout, falling back to full sequential loading
    
    WARNING: This is an experimental feature. Fragments that modify session state extensively
    may not work correctly in parallel mode and will fall back to sequential loading.

.PARAMETER FragmentFiles
    Array of fragment FileInfo objects to load in parallel. These should be fragments
    at the same dependency level (no dependencies on each other).

.PARAMETER ProfileFragmentRoot
    The root directory for profile fragments. Used to set $global:ProfileFragmentRoot
    in each runspace.

.PARAMETER BootstrapFragmentPath
    Optional path to the bootstrap fragment. If provided, bootstrap functions will be
    loaded into each runspace before executing fragments, allowing fragments to use
    bootstrap functions like Test-CachedCommand.

.PARAMETER ThrottleLimit
    Maximum number of parallel runspaces. Defaults to CPU count (capped at 8).

.OUTPUTS
    System.Collections.Hashtable. Hashtable with:
    - SuccessCount: Number of fragments loaded successfully
    - FailureCount: Number of fragments that failed to load
    - Errors: Array of error records for failed fragments
    - UsedParallel: Whether parallel execution was successfully used

.EXAMPLE
    $levels = Get-FragmentDependencyLevels -FragmentFiles $fragments
    foreach ($level in $levels.Keys | Sort-Object) {
        $fragmentsAtLevel = $levels[$level]
        if ($fragmentsAtLevel.Count -gt 1 -and $env:PS_PROFILE_PARALLEL_LOADING -eq '1') {
            # Load in parallel if multiple fragments at this level
            $result = Invoke-FragmentsInParallel -FragmentFiles $fragmentsAtLevel -ProfileFragmentRoot $profileDir
            if (-not $result.UsedParallel) {
                # Fall back to sequential if parallel failed
                foreach ($fragment in $fragmentsAtLevel) {
                    . $fragment.FullName
                }
            }
        }
        else {
            # Load sequentially for single fragments or when parallel disabled
            foreach ($fragment in $fragmentsAtLevel) {
                . $fragment.FullName
            }
        }
    }
#>
function Invoke-FragmentsInParallel {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles,

        [string]$ProfileFragmentRoot,

        [string]$BootstrapFragmentPath,

        [int]$ThrottleLimit = [Math]::Min(8, [System.Environment]::ProcessorCount)
    )

    if ($FragmentFiles.Count -eq 0) {
        return @{
            SuccessCount       = 0
            FailureCount       = 0
            Errors             = @()
            UsedParallel       = $false
            SucceededFragments = @()
            FailedFragments    = @()
        }
    }

    # If only one fragment, load it sequentially (no benefit from parallelization)
    if ($FragmentFiles.Count -eq 1) {
        try {
            $fragment = $FragmentFiles[0]
            if ($ProfileFragmentRoot -and $fragment.DirectoryName) {
                $global:ProfileFragmentRoot = $fragment.DirectoryName
            }
            $null = . $fragment.FullName
            return @{
                SuccessCount       = 1
                FailureCount       = 0
                Errors             = @()
                UsedParallel       = $false
                SucceededFragments = @($fragment.BaseName)
                FailedFragments    = @()
            }
        }
        catch {
            return @{
                SuccessCount       = 0
                FailureCount       = 1
                Errors             = @($_)
                UsedParallel       = $false
                SucceededFragments = @()
                FailedFragments    = @(@{
                        Name  = $fragment.BaseName
                        Error = $_.Exception.Message
                    })
            }
        }
    }

    # Hybrid approach: Try parallel loading, fall back to sequential on any failure
    $runspacePool = $null
    $runspaces = @()
    $successCount = 0
    $failureCount = 0
    $errors = [System.Collections.Generic.List[System.Management.Automation.ErrorRecord]]::new()
    $succeededFragments = [System.Collections.Generic.List[string]]::new()
    $failedFragments = [System.Collections.Generic.List[hashtable]]::new()  # List of @{Name=string; Error=string}
    $parallelSucceeded = $false

    try {
        # Create runspace pool
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
        $runspacePool.Open()

        # Scriptblock to execute fragment in isolated runspace
        $scriptBlock = {
            param(
                [string]$FragmentPath,
                [string]$FragmentName,
                [string]$ProfileFragmentRootValue,
                [string]$BootstrapPath
            )

            try {
                # Set ProfileFragmentRoot if provided
                if ($ProfileFragmentRootValue) {
                    $global:ProfileFragmentRoot = $ProfileFragmentRootValue
                }

                # Load bootstrap fragment first if provided (to make bootstrap functions available)
                if ($BootstrapPath -and (Test-Path -LiteralPath $BootstrapPath)) {
                    try {
                        $null = . $BootstrapPath
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Bootstrap loaded successfully in runspace for fragment '$FragmentName'"
                        }
                    }
                    catch {
                        # Bootstrap loading failure is non-fatal - fragments might not need it
                        # But log it for debugging
                        if ($env:PS_PROFILE_DEBUG) {
                            Write-Verbose "Failed to load bootstrap in runspace for fragment '$FragmentName': $($_.Exception.Message)"
                        }
                    }
                }
                elseif ($env:PS_PROFILE_DEBUG) {
                    if (-not $BootstrapPath) {
                        Write-Verbose "No bootstrap path provided for fragment '$FragmentName'"
                    }
                    elseif (-not (Test-Path -LiteralPath $BootstrapPath)) {
                        Write-Verbose "Bootstrap path does not exist: $BootstrapPath"
                    }
                }

                # Execute fragment in runspace
                $null = . $FragmentPath

                return @{
                    FragmentName = $FragmentName
                    Success      = $true
                    Error        = $null
                }
            }
            catch {
                return @{
                    FragmentName = $FragmentName
                    Success      = $false
                    Error        = $_
                }
            }
        }

        # Start all fragments in parallel
        foreach ($fragment in $FragmentFiles) {
            $powershell = [PowerShell]::Create()
            $powershell.RunspacePool = $runspacePool
            $null = $powershell.AddScript($scriptBlock)
            $null = $powershell.AddArgument($fragment.FullName)
            $null = $powershell.AddArgument($fragment.BaseName)
            $null = $powershell.AddArgument($ProfileFragmentRoot)
            $null = $powershell.AddArgument($BootstrapFragmentPath)
            $handle = $powershell.BeginInvoke()
            $runspaces += @{
                PowerShell = $powershell
                Handle     = $handle
                Fragment   = $fragment
            }
        }

        # Wait for all to complete with timeout
        # Increase timeout for larger batches (30 seconds base + 5 seconds per fragment beyond 10)
        $baseTimeout = 30
        $additionalTimeout = [Math]::Max(0, ($FragmentFiles.Count - 10) * 5)
        $totalTimeoutSeconds = $baseTimeout + $additionalTimeout
        $totalTimeoutMs = $totalTimeoutSeconds * 1000  # Convert to milliseconds
        
        # Record start time for timeout calculation
        $startTime = Get-Date
        
        $allCompleted = $true
        $completedCount = 0
        $timedOutFragments = [System.Collections.Generic.List[string]]::new()
        
        # Wait for all fragments with a single timeout period
        # Use polling approach (STA-compatible) instead of WaitHandle.WaitAll which doesn't work on STA threads
        $pollIntervalMs = 100  # Check every 100ms
        $elapsedMs = 0
        
        while ($elapsedMs -lt $totalTimeoutMs) {
            $completedCount = 0
            foreach ($rs in $runspaces) {
                if ($rs.Handle.IsCompleted) {
                    $completedCount++
                }
            }
            
            # All fragments completed
            if ($completedCount -eq $runspaces.Count) {
                $allCompleted = $true
                break
            }
            
            # Sleep and check again
            Start-Sleep -Milliseconds $pollIntervalMs
            $elapsedMs += $pollIntervalMs
        }
        
        # Check for timed out fragments
        if (-not $allCompleted) {
            foreach ($rs in $runspaces) {
                if (-not $rs.Handle.IsCompleted) {
                    $timedOutFragments.Add($rs.Fragment.BaseName)
                }
            }
            $completedCount = $runspaces.Count - $timedOutFragments.Count
        }
        else {
            $completedCount = $runspaces.Count
        }
        
        if (-not $allCompleted) {
            $timeoutDetails = if ($timedOutFragments.Count -gt 0) {
                "Timed out fragments: $($timedOutFragments -join ', ')"
            }
            else {
                "Not all fragments completed"
            }
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "  ⚠ Parallel loading timeout: Only $completedCount of $($FragmentFiles.Count) fragments completed within ${totalTimeoutSeconds}s timeout. $timeoutDetails" -ForegroundColor Yellow
            }
        }

        if ($allCompleted) {
            # Collect results
            foreach ($rs in $runspaces) {
                try {
                    $result = $rs.PowerShell.EndInvoke($rs.Handle)
                    if ($result -and $result.Success) {
                        $successCount++
                        $succeededFragments.Add($rs.Fragment.BaseName)
                    }
                    else {
                        $failureCount++
                        $errorMessage = $null
                        if ($result -and $result.Error) {
                            $errors.Add($result.Error)
                            $errorMessage = $result.Error.Exception.Message
                        }
                        elseif ($result) {
                            $errorMessage = "Returned failure result (no error details)"
                        }
                        else {
                            $errorMessage = "Returned null result"
                        }
                        $failedFragments.Add(@{
                                Name  = $rs.Fragment.BaseName
                                Error = $errorMessage
                            })
                    }
                }
                catch {
                    $failureCount++
                    $errors.Add($_)
                    $failedFragments.Add(@{
                            Name  = $rs.Fragment.BaseName
                            Error = $_.Exception.Message
                        })
                }
                finally {
                    $rs.PowerShell.Dispose()
                }
            }

            # If all succeeded, we can try to merge results
            # For now, we'll re-execute sequentially to ensure proper session state
            # This is a hybrid: parallel execution validates fragments, sequential ensures state
            # NOTE: Individual loading messages are suppressed during this re-execution
            # (controlled by PS_PROFILE_DEBUG_PARALLEL_SUPPRESS in the caller)
            if ($successCount -eq $FragmentFiles.Count) {
                $parallelSucceeded = $true
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "All fragments succeeded in parallel, re-executing sequentially to merge session state"
                }
                # Re-execute sequentially to merge into main session properly
                # This happens silently (no individual messages) since we already showed batch message
                foreach ($fragment in $FragmentFiles) {
                    try {
                        if ($ProfileFragmentRoot -and $fragment.DirectoryName) {
                            $global:ProfileFragmentRoot = $fragment.DirectoryName
                        }
                        $null = . $fragment.FullName
                    }
                    catch {
                        # If sequential re-execution fails, something is wrong
                        $failureCount++
                        $errors.Add($_)
                        # Optimized: Use HashSet for O(1) duplicate checking
                        if (-not $failedFragmentNamesSet.Contains($fragment.BaseName)) {
                            $failedFragments.Add(@{
                                    Name  = $fragment.BaseName
                                    Error = $_.Exception.Message
                                })
                            [void]$failedFragmentNamesSet.Add($fragment.BaseName)
                        }
                        # Remove from succeeded list if it was there
                        $succeededFragments.Remove($fragment.BaseName) | Out-Null
                    }
                }
            }
            else {
                # Some fragments failed in parallel - fall back to sequential
                $parallelSucceeded = $false
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host "  ⚠ Parallel loading failed: $successCount succeeded, $failureCount failed out of $($FragmentFiles.Count) fragments. Falling back to sequential." -ForegroundColor Yellow
                }
            }
        }
        else {
            # Timeout - fall back to sequential
            $parallelSucceeded = $false
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "  ⚠ Parallel loading timeout: Not all fragments completed within timeout period" -ForegroundColor Yellow
            }
            foreach ($rs in $runspaces) {
                try {
                    if (-not $rs.Handle.IsCompleted) {
                        $rs.PowerShell.Stop()
                    }
                    $rs.PowerShell.Dispose()
                }
                catch {
                    # Ignore cleanup errors
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Verbose "Error cleaning up runspace: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    catch {
        # Parallel loading failed - fall back to sequential
        $parallelSucceeded = $false
        if ($env:PS_PROFILE_DEBUG) {
            Write-Host "  ✗ Parallel loading exception, falling back to sequential: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    finally {
        # Clean up runspace pool
        if ($runspacePool) {
            try {
                $runspacePool.Close()
                $runspacePool.Dispose()
            }
            catch {
                # Ignore cleanup errors
            }
        }
    }

    # Fall back to sequential loading if parallel failed or had errors
    if (-not $parallelSucceeded -or $failureCount -gt 0) {
        if ($env:PS_PROFILE_DEBUG) {
            Write-Verbose "Falling back to sequential fragment loading"
        }
        
        $successCount = 0
        $failureCount = 0
        $errors.Clear()
        $succeededFragments.Clear()
        $failedFragments.Clear()

        foreach ($fragment in $FragmentFiles) {
            try {
                if ($ProfileFragmentRoot -and $fragment.DirectoryName) {
                    $global:ProfileFragmentRoot = $fragment.DirectoryName
                }
                $null = . $fragment.FullName
                $successCount++
                $succeededFragments.Add($fragment.BaseName)
            }
            catch {
                $failureCount++
                $errors.Add($_)
                $failedFragments.Add(@{
                        Name  = $fragment.BaseName
                        Error = $_.Exception.Message
                    })
            }
        }
    }

    return @{
        SuccessCount       = $successCount
        FailureCount       = $failureCount
        Errors             = $errors.ToArray()
        UsedParallel       = $parallelSucceeded
        SucceededFragments = $succeededFragments.ToArray()
        FailedFragments    = $failedFragments.ToArray()
    }
}

Export-ModuleMember -Function 'Invoke-FragmentsInParallel'
