<#
scripts/lib/Parallel.psm1

.SYNOPSIS
    Parallel processing utilities.

.DESCRIPTION
    Provides functions for processing items in parallel using PowerShell runspaces,
    with automatic lifecycle management and result collection. Runspaces are much
    faster than jobs as they run in the same process without spawning new PowerShell instances.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.1+ (requires runspaces)
    
    Changed from jobs to runspaces in v2.0 for significantly better performance.
#>

<#
.SYNOPSIS
    Processes items in parallel using PowerShell jobs.

.DESCRIPTION
    Processes a collection of items in parallel using PowerShell background jobs.
    Useful for independent operations like file scanning, validation, etc.
    Automatically manages job lifecycle and collects results.

.PARAMETER Items
    The collection of items to process. Can be any array or collection of objects.
    Each item is passed to the ScriptBlock as $_ or $PSItem, or as a parameter if the scriptblock has parameters.
    Type: [object[]]. Accepts any object array (FileInfo[], string[], PSCustomObject[], etc.).

.PARAMETER ScriptBlock
    The scriptblock to execute for each item. Receives the item as $_ or $PSItem.
    If the scriptblock has parameters, the first parameter receives the item.
    Type: [scriptblock]. Should accept one parameter or use $_/$PSItem.

.PARAMETER ThrottleLimit
    Maximum number of parallel runspaces. Defaults to CPU count (capped at 10).
    Type: [int]. Should be positive (typically 1-20).

.PARAMETER TimeoutSeconds
    Maximum time to wait for runspaces to complete. Defaults to 300 (5 minutes).
    Type: [int]. Should be positive.

.OUTPUTS
    Array of results from processing each item.
    Type: [object[]]. Returns an array containing the output from each ScriptBlock execution.
    Result types depend on what the ScriptBlock returns.

.EXAMPLE
    $files = Get-PowerShellScripts -Path $profileDir
    $results = Invoke-Parallel -Items $files -ScriptBlock {
        Test-Path $_.FullName
    }
#>
function Invoke-Parallel {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [object[]]$Items,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$ThrottleLimit = 5,

        [int]$TimeoutSeconds = 300
    )

    begin {
        $itemList = New-Object System.Collections.ArrayList
    }

    process {
        if ($null -ne $Items) {
            foreach ($item in $Items) {
                [void]$itemList.Add($item)
            }
        }
    }

    end {
        # Always ensure we have a valid itemList (handle case where process block wasn't called)
        if ($null -eq $itemList) {
            $itemList = New-Object System.Collections.ArrayList
        }
        
        # If no items to process, return empty array immediately
        if ($itemList.Count -eq 0) {
            return [object[]]@()
        }

        # Use runspaces for parallel processing (much faster than jobs)
        $runspacePool = $null
        $runspaces = @()
        $results = @()

        try {
            # Set default throttle limit if not specified (use CPU count, capped at 10)
            if ($ThrottleLimit -le 0) {
                $ThrottleLimit = [Math]::Min(10, [System.Environment]::ProcessorCount)
            }

            # Create runspace pool
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, $ThrottleLimit)
            $runspacePool.Open()

            # Create scriptblock wrapper that handles parameter detection
            $wrapperScriptBlock = {
                param($Item, $ScriptBlock)

                if ($ScriptBlock -isnot [scriptblock]) {
                    $ScriptBlock = [scriptblock]::Create([string]$ScriptBlock)
                }

                # Support both parameterized scriptblocks and $_ style
                $PSItem = $Item
                $_ = $Item
                
                # Check if scriptblock has parameters
                $params = $ScriptBlock.Ast.ParamBlock
                if ($params -and $params.Parameters.Count -gt 0) {
                    $paramName = $params.Parameters[0].Name.VariablePath.UserPath
                    & $ScriptBlock -$paramName $Item
                }
                else {
                    & $ScriptBlock
                }
            }

            # Start all items in parallel
            foreach ($item in $itemList) {
                $powershell = [PowerShell]::Create()
                $powershell.RunspacePool = $runspacePool
                $null = $powershell.AddScript($wrapperScriptBlock)
                $null = $powershell.AddArgument($item)
                $null = $powershell.AddArgument($ScriptBlock)
                $handle = $powershell.BeginInvoke()
                $runspaces += @{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $item
                }
            }

            # Wait for all to complete using polling (STA-compatible)
            $pollIntervalMs = 50  # Check every 50ms
            $timeoutMs = $TimeoutSeconds * 1000
            $elapsedMs = 0
            $allCompleted = $false

            while ($elapsedMs -lt $timeoutMs) {
                $completedCount = 0
                foreach ($rs in $runspaces) {
                    if ($rs.Handle.IsCompleted) {
                        $completedCount++
                    }
                }

                if ($completedCount -eq $runspaces.Count) {
                    $allCompleted = $true
                    break
                }

                Start-Sleep -Milliseconds $pollIntervalMs
                $elapsedMs += $pollIntervalMs
            }

            if (-not $allCompleted) {
                Write-Warning "Not all parallel tasks completed within ${TimeoutSeconds}s timeout"
            }

            # Collect results
            foreach ($rs in $runspaces) {
                try {
                    if ($rs.Handle.IsCompleted) {
                        $result = $rs.PowerShell.EndInvoke($rs.Handle)
                        # Handle array results
                        if ($result -is [array]) {
                            $results += $result
                        }
                        elseif ($null -ne $result) {
                            $results += $result
                        }
                    }
                    else {
                        Write-Warning "Task timed out for item at index $($runspaces.IndexOf($rs))"
                    }
                }
                catch {
                    Write-Warning "Task failed: $($_.Exception.Message)"
                }
                finally {
                    if ($rs.PowerShell) {
                        $rs.PowerShell.Dispose()
                    }
                }
            }
        }
        catch {
            Write-Warning "Error in parallel processing: $($_.Exception.Message)"
        }
        finally {
            # Cleanup runspace pool
            if ($runspacePool) {
                $runspacePool.Close()
                $runspacePool.Dispose()
            }
        }

        # Ensure we always return an array, even if empty
        if ($results.Count -eq 0) {
            return [object[]]@()
        }
        return $results
    }
}

# Export functions
Export-ModuleMember -Function 'Invoke-Parallel'

