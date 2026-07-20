<#
.SYNOPSIS
    Orchestrates profile fragment loading with optional parallel execution by dependency level.

.DESCRIPTION
    Loads profile fragments sequentially or in parallel batches, tracks success/failure,
    and populates LoadedFragments for consolidated debug output in ProfileFragmentLoader.
#>

function Invoke-OrchestrationProgressCallback {
    [CmdletBinding()]
    param(
        [scriptblock]$Callback,
        [hashtable]$BoundArguments = @{}
    )

    if (-not $Callback) {
        return
    }

    try {
        if ($BoundArguments.Count -gt 0) {
            & $Callback @BoundArguments
        }
        else {
            & $Callback
        }
    }
    catch {
        # Progress callbacks are defined in ProfileFragmentLoader scope and may not resolve here.
    }
}

function Get-OrchestrationDebugLevel {
    [CmdletBinding()]
    [OutputType([int])]
    param()

    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        return $debugLevel
    }

    return 0
}

function Test-OrchestrationFragmentSkippable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [System.IO.FileInfo]$Fragment,
        [System.Collections.Generic.HashSet[string]]$DisabledSet,
        [System.Collections.Generic.HashSet[string]]$BootstrapNameSet
    )

    if (-not $Fragment -or -not $Fragment.BaseName) {
        return $true
    }

    if ($BootstrapNameSet -and $BootstrapNameSet.Contains($Fragment.BaseName)) {
        return $true
    }

    if ($DisabledSet -and $DisabledSet.Contains($Fragment.BaseName)) {
        return $true
    }

    return $false
}

function Add-OrchestrationLoadedFragment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentBaseName,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$LoadedFragments,

        [Parameter(Mandatory)]
        [int]$BatchSize,

        [Parameter(Mandatory)]
        [int]$DebugLevel
    )

    [void]$LoadedFragments.Add($FragmentBaseName)

    if ($DebugLevel -eq 1) {
        if ($LoadedFragments.Count % $BatchSize -eq 0) {
            $batchStart = [Math]::Max(0, $LoadedFragments.Count - $BatchSize)
            $batch = $LoadedFragments[$batchStart..($LoadedFragments.Count - 1)]
            $fragmentList = ($batch -join ', ')
            Write-Host "Loading fragments ($($LoadedFragments.Count) total): $fragmentList" -ForegroundColor Cyan
        }
    }
    elseif ($DebugLevel -ge 2) {
        Write-Host "Loading profile fragment: $FragmentBaseName.ps1" -ForegroundColor Cyan
    }
}

function Invoke-OrchestrationSingleFragment {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$Fragment,

        [string]$ProfileD,
        [bool]$FragmentErrorHandlingModuleExists,
        [System.Collections.Generic.HashSet[string]]$AllSucceeded,
        [System.Collections.Generic.List[hashtable]]$AllFailed,
        [System.Collections.Generic.HashSet[string]]$FailedNames,
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$LoadedFragments,
        [int]$FragmentLoadingBatchSize,
        [int]$DebugLevel
    )

    $originalProfileFragmentRoot = $global:ProfileFragmentRoot
    if ($Fragment.DirectoryName) {
        $global:ProfileFragmentRoot = $Fragment.DirectoryName
    }

    $originalFragmentContext = $null
    if (Get-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue) {
        $originalFragmentContext = $global:CurrentFragmentContext
    }

    $global:CurrentFragmentContext = $Fragment.BaseName

    $loaded = $false
    try {
        $null = . $Fragment.FullName
        if ($Fragment.BaseName) {
            [void]$AllSucceeded.Add($Fragment.BaseName)
            Add-OrchestrationLoadedFragment `
                -FragmentBaseName $Fragment.BaseName `
                -LoadedFragments $LoadedFragments `
                -BatchSize $FragmentLoadingBatchSize `
                -DebugLevel $DebugLevel
            $loaded = $true
        }
    }
    catch {
        if ($Fragment.BaseName -and -not $FailedNames.Contains($Fragment.BaseName)) {
            $AllFailed.Add(@{ Name = $Fragment.BaseName; Error = $_.Exception.Message })
            [void]$FailedNames.Add($Fragment.BaseName)
        }

        if ($DebugLevel -ge 1) {
            Write-Host "Failed to load profile fragment '$($Fragment.Name)': $($_.Exception.Message)" -ForegroundColor Red
        }

        if ($FragmentErrorHandlingModuleExists -and (Get-Command Write-StructuredError -ErrorAction SilentlyContinue)) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'profile-fragment-orchestration.load' -Context @{
                fragment_name = $Fragment.BaseName
                fragment_path = $Fragment.FullName
            }
        }
        else {
            Write-Warning "Failed to load profile fragment '$($Fragment.Name)': $($_.Exception.Message)"
        }
    }
    finally {
        $global:ProfileFragmentRoot = $originalProfileFragmentRoot
        if ($null -ne $originalFragmentContext) {
            $global:CurrentFragmentContext = $originalFragmentContext
        }
        else {
            Remove-Variable -Name 'CurrentFragmentContext' -Scope Global -ErrorAction SilentlyContinue
        }
    }

    return $loaded
}

function Merge-OrchestrationParallelResults {
    [CmdletBinding()]
    param(
        [hashtable]$ParallelResult,
        [System.Collections.Generic.HashSet[string]]$AllSucceeded,
        [System.Collections.Generic.List[hashtable]]$AllFailed,
        [System.Collections.Generic.HashSet[string]]$FailedNames,
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$LoadedFragments,
        [int]$FragmentLoadingBatchSize,
        [int]$DebugLevel,
        [ref]$LoadedCount,
        [System.Collections.Generic.List[string]]$BatchNames,
        [ref]$BatchNumber,
        [scriptblock]$WriteBatchProgressRow
    )

    if (-not $ParallelResult) {
        return
    }

    foreach ($name in @($ParallelResult.SucceededFragments)) {
        if (-not $name) {
            continue
        }

        [void]$AllSucceeded.Add($name)
        Add-OrchestrationLoadedFragment `
            -FragmentBaseName $name `
            -LoadedFragments $LoadedFragments `
            -BatchSize $FragmentLoadingBatchSize `
            -DebugLevel $DebugLevel
        $LoadedCount.Value++
        [void]$BatchNames.Add($name)
    }

    foreach ($failure in @($ParallelResult.FailedFragments)) {
        $failedName = if ($failure -is [hashtable]) { $failure.Name } else { $null }
        $failedError = if ($failure -is [hashtable]) { $failure.Error } else { $failure.ToString() }
        if ($failedName -and -not $FailedNames.Contains($failedName)) {
            $AllFailed.Add(@{ Name = $failedName; Error = $failedError })
            [void]$FailedNames.Add($failedName)
        }
    }

    if ($BatchNames.Count -ge $FragmentLoadingBatchSize -and $WriteBatchProgressRow) {
        $BatchNumber.Value++
        Invoke-OrchestrationProgressCallback -Callback $WriteBatchProgressRow -BoundArguments @{
            BatchNumber    = $BatchNumber.Value
            TotalBatches   = $BatchNumber.Value
            FragmentCount  = $BatchNames.Count
            FragmentNames  = @($BatchNames)
        }
        $BatchNames.Clear()
    }
}

function Get-OrchestrationSortedLevelKeys {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [hashtable]$FragmentLevels
    )

    if (-not $FragmentLevels -or -not $FragmentLevels.Keys) {
        return @()
    }

    return @(
        $FragmentLevels.Keys |
            Sort-Object {
                if ($_ -match 'Level(\d+)') {
                    [int]$Matches[1]
                }
                else {
                    999
                }
            }
    )
}

function Invoke-FragmentLoadingOrchestration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[System.IO.FileInfo]]$FragmentsToLoad,

        [System.Collections.Generic.HashSet[string]]$DisabledSet,
        [object[]]$BootstrapFragment,
        [System.Collections.Generic.HashSet[string]]$BootstrapNameSet,
        [string]$ProfileD,
        [bool]$FragmentErrorHandlingModuleExists,
        [bool]$UseParallelLoading,
        [bool]$ParallelLoadingModuleLoaded,
        [hashtable]$FragmentLevels,
        [System.Collections.Generic.HashSet[string]]$AllSucceeded,
        [System.Collections.Generic.List[hashtable]]$AllFailed,
        [System.Collections.Generic.HashSet[string]]$FailedNames,
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$LoadedFragments,
        [int]$FragmentLoadingBatchSize,
        [scriptblock]$WriteBatchProgressTableHeader,
        [scriptblock]$WriteBatchProgressRow
    )

    Invoke-OrchestrationProgressCallback -Callback $WriteBatchProgressTableHeader

    $debugLevel = Get-OrchestrationDebugLevel
    $batchNames = [System.Collections.Generic.List[string]]::new()
    $loadProgress = [pscustomobject]@{
        LoadedCount = 0
        BatchNumber = 0
    }

    $bootstrapPath = $null
    if ($BootstrapFragment -and $BootstrapFragment.Count -gt 0 -and $BootstrapFragment[0].FullName) {
        $bootstrapPath = $BootstrapFragment[0].FullName
    }

    function Invoke-OrchestrationProcessFragment {
        param(
            [System.IO.FileInfo]$Fragment
        )

        if (Test-OrchestrationFragmentSkippable -Fragment $Fragment -DisabledSet $DisabledSet -BootstrapNameSet $BootstrapNameSet) {
            return
        }

        $wasLoaded = Invoke-OrchestrationSingleFragment `
            -Fragment $Fragment `
            -ProfileD $ProfileD `
            -FragmentErrorHandlingModuleExists $FragmentErrorHandlingModuleExists `
            -AllSucceeded $AllSucceeded `
            -AllFailed $AllFailed `
            -FailedNames $FailedNames `
            -LoadedFragments $LoadedFragments `
            -FragmentLoadingBatchSize $FragmentLoadingBatchSize `
            -DebugLevel $debugLevel

        if ($wasLoaded -and $Fragment.BaseName) {
            $loadProgress.LoadedCount++
            [void]$batchNames.Add($Fragment.BaseName)

            if ($batchNames.Count -ge $FragmentLoadingBatchSize -and $WriteBatchProgressRow) {
                $loadProgress.BatchNumber++
                Invoke-OrchestrationProgressCallback -Callback $WriteBatchProgressRow -BoundArguments @{
                    BatchNumber    = $loadProgress.BatchNumber
                    TotalBatches   = $loadProgress.BatchNumber
                    FragmentCount  = $batchNames.Count
                    FragmentNames  = @($batchNames)
                }
                $batchNames.Clear()
            }
        }
    }

    if ($FragmentLevels -and $FragmentLevels.Keys.Count -gt 0) {
        $sortedLevels = Get-OrchestrationSortedLevelKeys -FragmentLevels $FragmentLevels
        foreach ($levelKey in $sortedLevels) {
            $levelFragments = @($FragmentLevels[$levelKey])
            if ($levelFragments.Count -eq 0) {
                continue
            }

            $levelFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
            foreach ($levelFragment in $levelFragments) {
                $candidateFiles = @()
                if ($levelFragment -is [System.IO.FileInfo]) {
                    $candidateFiles = @($levelFragment)
                }
                else {
                    $fragmentName = [string]$levelFragment
                    $candidateFiles = @($FragmentsToLoad | Where-Object { $_.BaseName -eq $fragmentName })
                }

                foreach ($match in $candidateFiles) {
                    if (-not (Test-OrchestrationFragmentSkippable -Fragment $match -DisabledSet $DisabledSet -BootstrapNameSet $BootstrapNameSet)) {
                        [void]$levelFiles.Add($match)
                    }
                }
            }

            if ($levelFiles.Count -eq 0) {
                continue
            }

            if ($UseParallelLoading -and $ParallelLoadingModuleLoaded -and $levelFiles.Count -gt 1 -and (Get-Command Invoke-FragmentsInParallel -ErrorAction SilentlyContinue)) {
                $parallelResult = Invoke-FragmentsInParallel `
                    -FragmentFiles $levelFiles.ToArray() `
                    -ProfileFragmentRoot $ProfileD `
                    -BootstrapFragmentPath $bootstrapPath

                Merge-OrchestrationParallelResults `
                    -ParallelResult $parallelResult `
                    -AllSucceeded $AllSucceeded `
                    -AllFailed $AllFailed `
                    -FailedNames $FailedNames `
                    -LoadedFragments $LoadedFragments `
                    -FragmentLoadingBatchSize $FragmentLoadingBatchSize `
                    -DebugLevel $debugLevel `
                    -LoadedCount ([ref]$loadProgress.LoadedCount) `
                    -BatchNames $batchNames `
                    -BatchNumber ([ref]$loadProgress.BatchNumber) `
                    -WriteBatchProgressRow $WriteBatchProgressRow
            }
            else {
                foreach ($levelFile in $levelFiles) {
                    Invoke-OrchestrationProcessFragment -Fragment $levelFile
                }
            }
        }
    }
    else {
        foreach ($frag in $FragmentsToLoad) {
            Invoke-OrchestrationProcessFragment -Fragment $frag
        }
    }

    if ($batchNames.Count -gt 0 -and $WriteBatchProgressRow) {
        $loadProgress.BatchNumber++
        Invoke-OrchestrationProgressCallback -Callback $WriteBatchProgressRow -BoundArguments @{
            BatchNumber    = $loadProgress.BatchNumber
            TotalBatches   = $loadProgress.BatchNumber
            FragmentCount  = $batchNames.Count
            FragmentNames  = @($batchNames)
        }
    }

    return $loadProgress.LoadedCount
}

Export-ModuleMember -Function Invoke-FragmentLoadingOrchestration
