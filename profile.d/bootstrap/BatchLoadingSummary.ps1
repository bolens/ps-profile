# ===============================================
# BatchLoadingSummary.ps1
# Batch loading summary and display utilities
# ===============================================

<#
.SYNOPSIS
    Initializes batch loading information collection.
.DESCRIPTION
    Resets and initializes the batch loading information structure for a new profile load.
#>
function global:Initialize-BatchLoadingInfo {
    [CmdletBinding()]
    param()

    if (-not $global:BatchLoadingInfo) {
        $global:BatchLoadingInfo = @{
            DependencyParsingTime = $null
            DependencyLevels      = 0
            Batches               = [System.Collections.Generic.List[hashtable]]::new()
            TotalFragments        = 0
            SucceededFragments    = [System.Collections.Generic.List[string]]::new()
            FailedFragments       = [System.Collections.Generic.List[hashtable]]::new()
            StartTime             = $null
            EndTime               = $null
        }
    }
    else {
        $global:BatchLoadingInfo.DependencyParsingTime = $null
        $global:BatchLoadingInfo.DependencyLevels = 0
        $global:BatchLoadingInfo.Batches.Clear()
        $global:BatchLoadingInfo.TotalFragments = 0
        $global:BatchLoadingInfo.SucceededFragments.Clear()
        $global:BatchLoadingInfo.FailedFragments.Clear()
        $global:BatchLoadingInfo.StartTime = $null
        $global:BatchLoadingInfo.EndTime = $null
    }
}

<#
.SYNOPSIS
    Records dependency parsing information.
.DESCRIPTION
    Stores information about fragment dependency parsing for later display.
.PARAMETER ParsingTime
    Time taken to parse dependencies in milliseconds.
.PARAMETER DependencyLevels
    Number of dependency levels found.
#>
function global:Record-DependencyParsing {
    [CmdletBinding()]
    param(
        [int]$ParsingTime,
        [int]$DependencyLevels
    )

    if (-not $global:BatchLoadingInfo) {
        Initialize-BatchLoadingInfo
    }

    $global:BatchLoadingInfo.DependencyParsingTime = $ParsingTime
    $global:BatchLoadingInfo.DependencyLevels = $DependencyLevels
}

<#
.SYNOPSIS
    Records a batch loading event.
.DESCRIPTION
    Stores information about a batch of fragments being loaded.
.PARAMETER BatchNumber
    The batch number (1-based).
.PARAMETER TotalBatches
    Total number of batches.
.PARAMETER FragmentCount
    Number of fragments in this batch.
.PARAMETER FragmentNames
    Array of fragment names in this batch.
#>
function global:Record-BatchLoading {
    [CmdletBinding()]
    param(
        [int]$BatchNumber,
        [int]$TotalBatches,
        [int]$FragmentCount,
        [string[]]$FragmentNames
    )

    if (-not $global:BatchLoadingInfo) {
        Initialize-BatchLoadingInfo
    }

    $progressPercent = if ($TotalBatches -gt 0) {
        [Math]::Round(($BatchNumber / $TotalBatches) * 100)
    }
    else {
        0
    }

    $global:BatchLoadingInfo.Batches.Add(@{
            BatchNumber     = $BatchNumber
            TotalBatches    = $TotalBatches
            FragmentCount   = $FragmentCount
            FragmentNames   = $FragmentNames
            ProgressPercent = $progressPercent
        })
}

<#
.SYNOPSIS
    Records fragment loading results.
.DESCRIPTION
    Stores information about which fragments succeeded or failed.
.PARAMETER SucceededFragments
    Array of fragment names that succeeded.
.PARAMETER FailedFragments
    Array of hashtables with Name and Error keys for failed fragments.
#>
function global:Record-FragmentResults {
    [CmdletBinding()]
    param(
        [string[]]$SucceededFragments,
        [hashtable[]]$FailedFragments
    )

    if (-not $global:BatchLoadingInfo) {
        Initialize-BatchLoadingInfo
    }

    if ($SucceededFragments) {
        foreach ($fragment in $SucceededFragments) {
            if ($fragment -and -not $global:BatchLoadingInfo.SucceededFragments.Contains($fragment)) {
                $global:BatchLoadingInfo.SucceededFragments.Add($fragment)
            }
        }
    }

    if ($FailedFragments) {
        foreach ($failed in $FailedFragments) {
            if ($failed.Name -and -not ($global:BatchLoadingInfo.FailedFragments | Where-Object { $_.Name -eq $failed.Name })) {
                $global:BatchLoadingInfo.FailedFragments.Add($failed)
            }
        }
    }
}

<#
.SYNOPSIS
    Sets the total fragment count.
.DESCRIPTION
    Records the total number of fragments being loaded.
.PARAMETER Count
    Total number of fragments.
#>
function global:Set-TotalFragmentCount {
    [CmdletBinding()]
    param(
        [int]$Count
    )

    if (-not $global:BatchLoadingInfo) {
        Initialize-BatchLoadingInfo
    }

    $global:BatchLoadingInfo.TotalFragments = $Count
}

function global:_ConvertToNameTableRows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Names,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 8)]
        [int]$Columns = 4
    )

    $clean = @($Names | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($clean.Count -eq 0) { return @() }

    $rows = [System.Collections.Generic.List[object]]::new()
    $columnsToUse = [Math]::Min($Columns, $clean.Count)

    for ($i = 0; $i -lt $clean.Count; $i += $columnsToUse) {
        $obj = [ordered]@{}
        for ($c = 0; $c -lt $columnsToUse; $c++) {
            $idx = $i + $c
            $letter = [char]([int][char]'A' + $c)
            $obj["Fragment$letter"] = if ($idx -lt $clean.Count) { $clean[$idx] } else { '' }
        }
        $rows.Add([pscustomobject]$obj)
    }

    return $rows
}

<#
.SYNOPSIS
    Displays batch loading summary in an organized format.
.DESCRIPTION
    Shows a consolidated summary of batch loading including dependency parsing,
    batch progress, and success/failure counts in a clean, organized format.
#>
function global:Show-BatchLoadingSummary {
    [CmdletBinding()]
    param()

    if (-not $global:BatchLoadingInfo -or $global:BatchLoadingInfo.Batches.Count -eq 0) {
        return
    }

    $info = $global:BatchLoadingInfo
    $totalBatches = $info.Batches.Count
    $totalFragments = $info.SucceededFragments.Count + $info.FailedFragments.Count
    if ($totalFragments -eq 0 -and $info.TotalFragments -gt 0) {
        $totalFragments = $info.TotalFragments
    }

    Write-Host "`n[Fragment Loading Summary]" -ForegroundColor Cyan
    Write-Host ""

    # Dependency parsing info
    if ($info.DependencyParsingTime -ne $null -and -not ($env:PS_PROFILE_DEBUG -and $global:PSProfileDependencyAnalysisShown)) {
        Write-Host "Dependency Analysis:" -ForegroundColor Yellow
        Write-Host "  Levels: $($info.DependencyLevels)" -ForegroundColor Gray
        Write-Host "  Parsing Time: $($info.DependencyParsingTime)ms" -ForegroundColor Gray
        Write-Host ""
    }

    # Batch loading summary
    if ($totalBatches -gt 0) {
        Write-Host "Batch Loading:" -ForegroundColor Yellow
        $totalFragmentsInBatches = ($info.Batches | Measure-Object -Property FragmentCount -Sum).Sum
        Write-Host "  Batches: $totalBatches" -ForegroundColor Gray
        # Prefer the real fragment total (succeeded+failed or TotalFragments) over batch sums,
        # since not all fragments are necessarily recorded as discrete batches.
        Write-Host "  Fragments: $totalFragments" -ForegroundColor Gray
        
        # Show batch breakdown if there are multiple batches
        if ($totalBatches -gt 0) {
            Write-Host ""
            Write-Host "  Batch Breakdown:" -ForegroundColor Gray

            $batchRows = foreach ($batch in $info.Batches) {
                $names = @($batch.FragmentNames)
                $maxNames = 8
                $namesStr = if ($names.Count -le $maxNames) {
                    ($names -join ', ')
                }
                else {
                    $firstFew = ($names[0..($maxNames - 1)] -join ', ')
                    "$firstFew, … (+$($names.Count - $maxNames) more)"
                }

                [pscustomobject]@{
                    Batch     = ('{0}/{1}' -f $batch.BatchNumber, $batch.TotalBatches)
                    Fragments = $batch.FragmentCount
                    Progress  = ('{0}%' -f $batch.ProgressPercent)
                    Names     = $namesStr
                }
            }

            if ($batchRows) {
                $table = $batchRows | Format-Table -AutoSize | Out-String
                Write-Host ($table.TrimEnd()) -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }

    # Results summary
    Write-Host "Results:" -ForegroundColor Yellow
    $succeededCount = $info.SucceededFragments.Count
    $failedCount = $info.FailedFragments.Count
    
    if ($succeededCount -gt 0) {
        Write-Host "  ✓ Succeeded: $succeededCount" -ForegroundColor Green
        $sorted = @($info.SucceededFragments | Sort-Object)
        $nameRows = _ConvertToNameTableRows -Names $sorted -Columns 4
        if ($nameRows.Count -gt 0) {
            $table = $nameRows | Format-Table -AutoSize | Out-String
            Write-Host ($table.TrimEnd()) -ForegroundColor DarkGray
        }
    }
    
    if ($failedCount -gt 0) {
        Write-Host "  ✗ Failed: $failedCount" -ForegroundColor Red
        $failedRows = foreach ($failed in $info.FailedFragments) {
            [pscustomobject]@{
                Fragment = $failed.Name
                Error    = $failed.Error
            }
        }

        if ($failedRows) {
            $table = $failedRows | Format-Table -AutoSize | Out-String
            Write-Host ($table.TrimEnd()) -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
}
