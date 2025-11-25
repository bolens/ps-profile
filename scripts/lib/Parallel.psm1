<#
scripts/lib/Parallel.psm1

.SYNOPSIS
    Parallel processing utilities.

.DESCRIPTION
    Provides functions for processing items in parallel using PowerShell jobs,
    with automatic job lifecycle management and result collection.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
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
    Maximum number of parallel jobs. Defaults to 5.
    Type: [int]. Should be positive (typically 1-20).

.PARAMETER TimeoutSeconds
    Maximum time to wait for jobs to complete. Defaults to 300 (5 minutes).
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
        $allJobs = [System.Collections.Generic.List[System.Management.Automation.Job]]::new()
        $itemList = [System.Collections.Generic.List[object]]::new()
    }

    process {
        foreach ($item in $Items) {
            $itemList.Add($item)
        }
    }

    end {
        if ($itemList.Count -eq 0) {
            return @()
        }

        # Process items in batches to respect throttle limit
        $results = [System.Collections.Generic.List[object]]::new()
        $index = 0

        while ($index -lt $itemList.Count) {
            # Start jobs up to throttle limit
            $activeJobs = $allJobs | Where-Object { $_.State -eq 'Running' }

            while ($activeJobs.Count -lt $ThrottleLimit -and $index -lt $itemList.Count) {
                $item = $itemList[$index]
                $job = $null
                
                try {
                    $job = Start-Job -ScriptBlock {
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
                    } -ArgumentList $item, $ScriptBlock -ErrorAction Stop
                    
                    if ($null -ne $job) {
                        $allJobs.Add($job)
                    }
                }
                catch {
                    Write-Warning "Failed to start job for item at index $index : $($_.Exception.Message)"
                    # Continue with next item
                }
                
                $index++
                $activeJobs = $allJobs | Where-Object { $_.State -eq 'Running' }
            }

            # Wait for at least one job to complete
            if ($activeJobs.Count -ge $ThrottleLimit) {
                $completed = $allJobs | Wait-Job -Any -Timeout $TimeoutSeconds
                foreach ($job in $completed) {
                    try {
                        $result = Receive-Job -Job $job
                        $results.Add($result)
                    }
                    catch {
                        Write-Warning "Job $($job.Id) failed: $($_.Exception.Message)"
                    }
                    finally {
                        Remove-Job -Job $job -Force
                    }
                }
            }
        }

        # Wait for remaining jobs
        $remainingJobs = $allJobs | Where-Object { $_.State -eq 'Running' }
        if ($remainingJobs.Count -gt 0) {
            $completed = $remainingJobs | Wait-Job -Timeout $TimeoutSeconds
            foreach ($job in $completed) {
                try {
                    $result = Receive-Job -Job $job
                    $results.Add($result)
                }
                catch {
                    Write-Warning "Job $($job.Id) failed: $($_.Exception.Message)"
                }
                finally {
                    Remove-Job -Job $job -Force
                }
            }
        }

        # Clean up any remaining jobs
        $allJobs | Remove-Job -Force -ErrorAction SilentlyContinue

        return $results.ToArray()
    }
}

# Export functions
Export-ModuleMember -Function 'Invoke-Parallel'

