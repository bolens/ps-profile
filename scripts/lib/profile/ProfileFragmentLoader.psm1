<#
.SYNOPSIS
    Fragment loading logic for profile initialization.

.DESCRIPTION
    Loads profile fragments sequentially or in parallel batches (by dependency level)
    and records batch loading information for end-of-run summaries.

    This module is designed to be invoked by `Microsoft.PowerShell_profile.ps1`.
#>

$script:BatchProgressHeaderShown = $false

function Write-BatchProgressTableHeader {
    [CmdletBinding()]
    param()

    if ($script:BatchProgressHeaderShown) {
        Write-Host ""
        return
    }

    $script:BatchProgressHeaderShown = $true
    Write-Host ""
    Write-Host ("{0,-7} {1,9} {2,9} {3}" -f 'Batch', 'Fragments', 'Progress', 'Names') -ForegroundColor Cyan
    Write-Host ("{0,-7} {1,9} {2,9} {3}" -f '-----', '---------', '--------', '-----') -ForegroundColor Cyan
}

function Write-BatchProgressRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$BatchNumber,

        [Parameter(Mandatory)]
        [int]$TotalBatches,

        [Parameter(Mandatory)]
        [int]$FragmentCount,

        [Parameter(Mandatory)]
        [string[]]$FragmentNames
    )

    $progressPercent = if ($TotalBatches -gt 0) { [Math]::Round(($BatchNumber / $TotalBatches) * 100) } else { 0 }
    $batchLabel = ('{0}/{1}' -f $BatchNumber, $TotalBatches)
    $progressLabel = ('{0}%' -f $progressPercent)

    $names = @($FragmentNames)
    $maxNames = 10
    $namesStr = if ($names.Count -le $maxNames) {
        ($names -join ', ')
    }
    else {
        $firstFew = ($names[0..($maxNames - 1)] -join ', ')
        "$firstFew, … (+$($names.Count - $maxNames) more)"
    }

    Write-Host ("{0,-7} {1,9} {2,9} {3}" -f $batchLabel, $FragmentCount, $progressLabel, $namesStr) -ForegroundColor Cyan
}

function Initialize-FragmentLoading {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[System.IO.FileInfo]]$FragmentsToLoad,

        [Parameter(Mandatory = $false)]
        [System.IO.FileInfo[]]$BootstrapFragment = @(),

        [Parameter(Mandatory = $false)]
        [System.Collections.Generic.HashSet[string]]$DisabledSet = $null,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$DisabledFragments = @(),

        [Parameter(Mandatory)]
        [bool]$EnableParallelLoading,

        [Parameter(Mandatory)]
        [string]$FragmentLoadingModule,

        [Parameter(Mandatory)]
        [bool]$FragmentLoadingModuleExists,

        [Parameter(Mandatory)]
        [string]$FragmentLibDir,

        [Parameter(Mandatory)]
        [string]$FragmentErrorHandlingModule,

        [Parameter(Mandatory)]
        [bool]$FragmentErrorHandlingModuleExists,

        [Parameter(Mandatory)]
        [string]$ProfileD
    )

    $script:BatchProgressHeaderShown = $false
    $global:PSProfileDependencyAnalysisShown = $false

    $dependencyParsingTimeMs = $null
    $dependencyLevelsCount = $null

    $fragmentLevels = $null
    $useParallelLoading = $false
    $parallelLoadingModuleLoaded = $false

    # Track results across bootstrap + normal fragments
    $allSucceeded = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $allFailed = [System.Collections.Generic.List[hashtable]]::new()
    $failedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # Treat bootstrap as a pre-stage: load first, but do NOT include in batch numbering
    $bootstrapNameSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($bf in @($BootstrapFragment)) {
        if ($bf -and $bf.BaseName) { [void]$bootstrapNameSet.Add($bf.BaseName) }
    }
    # Also exclude files-module-registry since it loads at the same time as bootstrap
    [void]$bootstrapNameSet.Add('files-module-registry')

    foreach ($bf in @($BootstrapFragment)) {
        if (-not $bf) { continue }
        try {
            $null = . $bf.FullName
            if ($bf.BaseName) { [void]$allSucceeded.Add($bf.BaseName) }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Failed to load bootstrap fragment '$($bf.Name)': $($_.Exception.Message)" -ForegroundColor Red
            }
            if ($bf.BaseName -and -not $failedNames.Contains($bf.BaseName)) {
                $allFailed.Add(@{ Name = $bf.BaseName; Error = $_.Exception.Message })
                [void]$failedNames.Add($bf.BaseName)
            }
        }
    }

    # Initialize batch summary tracking after bootstrap is available
    if (Get-Command Initialize-BatchLoadingInfo -ErrorAction SilentlyContinue) {
        Initialize-BatchLoadingInfo
    }
    if (Get-Command Set-TotalFragmentCount -ErrorAction SilentlyContinue) {
        Set-TotalFragmentCount -Count $FragmentsToLoad.Count
    }

    # Dependency grouping (optional)
    if ($EnableParallelLoading -and $FragmentLoadingModuleExists) {
        if (-not (Get-Command Get-FragmentDependencyLevels -ErrorAction SilentlyContinue)) {
            Import-Module $FragmentLoadingModule -ErrorAction SilentlyContinue -DisableNameChecking -Force
        }

        if (Get-Command Get-FragmentDependencyLevels -ErrorAction SilentlyContinue) {
            try {
                $groupingStart = Get-Date
                if ($env:PS_PROFILE_DEBUG) {
                    $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT = '1'
                }

                $fragmentLevels = Get-FragmentDependencyLevels -FragmentFiles $FragmentsToLoad.ToArray() -DisabledFragments $DisabledFragments

                if ($env:PS_PROFILE_DEBUG) {
                    $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT = $null
                }

                $groupingTime = (Get-Date) - $groupingStart
                $dependencyParsingTimeMs = [int][Math]::Round($groupingTime.TotalMilliseconds)
                $dependencyLevelsCount = if ($fragmentLevels -and $fragmentLevels.Keys) { $fragmentLevels.Keys.Count } else { 0 }

                # Decide whether parallel loading provides value
                $levelsWithMultipleFragments = 0
                foreach ($levelKey in $fragmentLevels.Keys) {
                    $enabledCount = 0
                    foreach ($frag in $fragmentLevels[$levelKey]) {
                        $bn = $frag.BaseName
                        if ($bootstrapNameSet.Contains($bn)) { continue }
                        if ($bn -eq 'bootstrap' -or (-not $DisabledSet -or -not $DisabledSet.Contains($bn))) {
                            $enabledCount++
                        }
                    }
                    if ($enabledCount -gt 1) { $levelsWithMultipleFragments++ }
                }
                $useParallelLoading = $levelsWithMultipleFragments -gt 0

                if ($useParallelLoading) {
                    $parallelLoadingModulePath = Join-Path $FragmentLibDir 'FragmentParallelLoading.psm1'
                    if (Test-Path -LiteralPath $parallelLoadingModulePath) {
                        Import-Module $parallelLoadingModulePath -ErrorAction SilentlyContinue -DisableNameChecking
                        $parallelLoadingModuleLoaded = [bool](Get-Command Invoke-FragmentsInParallel -ErrorAction SilentlyContinue)
                    }

                    if (-not $parallelLoadingModuleLoaded) {
                        $useParallelLoading = $false
                    }
                }

                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host ""
                    Write-Host "[Dependency Analysis]" -ForegroundColor Cyan
                    $depRows = @(
                        [pscustomobject]@{
                            Fragments   = $FragmentsToLoad.Count
                            Levels      = $dependencyLevelsCount
                            UseParallel = $useParallelLoading
                            TimeMs      = $dependencyParsingTimeMs
                        }
                    )
                    $table = $depRows | Format-Table -AutoSize | Out-String
                    Write-Host ($table.TrimEnd()) -ForegroundColor DarkGray
                    Write-Host ""
                    $global:PSProfileDependencyAnalysisShown = $true
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    $env:PS_PROFILE_DEBUG_SUPPRESS_DEPENDENCY_OUTPUT = $null
                    Write-Host "Failed to group fragments by dependency level: $($_.Exception.Message). Using sequential loading." -ForegroundColor Yellow
                }
                $useParallelLoading = $false
                $fragmentLevels = $null
            }
        }
    }

    function Invoke-_LoadOne {
        param(
            [Parameter(Mandatory)]
            [System.IO.FileInfo]$Fragment
        )

        $fragmentName = $Fragment.Name
        $fragmentBaseName = $Fragment.BaseName

        if ($fragmentBaseName -ne 'bootstrap' -and $DisabledSet -and $DisabledSet.Contains($fragmentBaseName)) {
            if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_PARALLEL_SUPPRESS) {
                Write-Host "Skipping disabled profile fragment: $fragmentName" -ForegroundColor DarkGray
            }
            return $null
        }

        if ($env:PS_PROFILE_DEBUG -and -not $env:PS_PROFILE_DEBUG_PARALLEL_SUPPRESS) {
            Write-Host "Loading profile fragment: $fragmentName" -ForegroundColor Cyan
        }

        $originalProfileFragmentRoot = $global:ProfileFragmentRoot
        if ($Fragment.DirectoryName) {
            $global:ProfileFragmentRoot = $Fragment.DirectoryName
        }

        try {
            if ($FragmentErrorHandlingModuleExists -and (Get-Command Invoke-FragmentSafely -ErrorAction SilentlyContinue)) {
                return [bool](Invoke-FragmentSafely -FragmentName $fragmentBaseName -FragmentPath $Fragment.FullName)
            }

            $null = . $Fragment.FullName
            return $true
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Host "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)" -ForegroundColor Red
            }

            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Profile fragment loading" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load profile fragment '$fragmentName': $($_.Exception.Message)"
            }

            return $false
        }
        finally {
            $global:ProfileFragmentRoot = $originalProfileFragmentRoot
        }
    }

    if ($useParallelLoading -and $fragmentLevels -and $parallelLoadingModuleLoaded) {
        # Use global batch numbering across ALL levels so Batch/Progress make sense.
        # (Previously numbering restarted per dependency level.)
        $maxBatchSize = 15
        $globalTotalBatches = 0

        foreach ($levelKey in ($fragmentLevels.Keys | Sort-Object)) {
            $levelFragments = $fragmentLevels[$levelKey]
            $enabledCount = 0
            foreach ($frag in $levelFragments) {
                $bn = $frag.BaseName
                if ($bn -eq 'bootstrap' -or (-not $DisabledSet -or -not $DisabledSet.Contains($bn))) {
                    $enabledCount++
                }
            }

            if ($enabledCount -eq 0) { continue }
            if ($enabledCount -eq 1) {
                $globalTotalBatches++
            }
            else {
                $globalTotalBatches += [int][Math]::Ceiling($enabledCount / $maxBatchSize)
            }
        }

        if ($globalTotalBatches -lt 1) { $globalTotalBatches = 1 }
        $globalBatchNumber = 0

        foreach ($levelKey in ($fragmentLevels.Keys | Sort-Object)) {
            $levelFragments = $fragmentLevels[$levelKey]
            $levelSucceeded = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            $levelFailed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

            $enabledFragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
            foreach ($frag in $levelFragments) {
                $bn = $frag.BaseName
                if ($bootstrapNameSet.Contains($bn)) { continue }
                if ($bn -eq 'bootstrap' -or (-not $DisabledSet -or -not $DisabledSet.Contains($bn))) {
                    $enabledFragments.Add($frag)
                }
            }

            if ($enabledFragments.Count -eq 0) { continue }

            if ($enabledFragments.Count -eq 1) {
                $single = $enabledFragments[0]
                $singleNames = @($single.BaseName)

                $globalBatchNumber++
                $batchNumber = $globalBatchNumber
                $totalBatches = $globalTotalBatches

                if (Get-Command Record-BatchLoading -ErrorAction SilentlyContinue) {
                    Record-BatchLoading -BatchNumber $batchNumber -TotalBatches $totalBatches -FragmentCount 1 -FragmentNames $singleNames
                }
                if ($env:PS_PROFILE_DEBUG) {
                    Write-BatchProgressTableHeader
                    Write-BatchProgressRow -BatchNumber $batchNumber -TotalBatches $totalBatches -FragmentCount 1 -FragmentNames $singleNames
                }

                $env:PS_PROFILE_DEBUG_PARALLEL_SUPPRESS = '1'
                $ok = Invoke-_LoadOne -Fragment $single
                $env:PS_PROFILE_DEBUG_PARALLEL_SUPPRESS = $null

                if ($ok -eq $true) {
                    [void]$allSucceeded.Add($single.BaseName)
                    [void]$levelSucceeded.Add($single.BaseName)
                }
                elseif ($ok -eq $false) {
                    if (-not $failedNames.Contains($single.BaseName)) {
                        $allFailed.Add(@{ Name = $single.BaseName; Error = 'Failed to load fragment' })
                        [void]$failedNames.Add($single.BaseName)
                    }
                    [void]$levelFailed.Add($single.BaseName)
                }

                if ($env:PS_PROFILE_DEBUG) {
                    Write-Host ""
                    if ($levelSucceeded.Count -gt 0) { Write-Host "  ✓ Succeeded ($($levelSucceeded.Count))" -ForegroundColor Green }
                    if ($levelFailed.Count -gt 0) { Write-Host "  ✗ Failed ($($levelFailed.Count))" -ForegroundColor Red }
                    Write-Host ""
                }

                continue
            }

            $enabledArray = $enabledFragments.ToArray()
            $batches = [System.Collections.Generic.List[object]]::new()
            for ($i = 0; $i -lt $enabledArray.Count; $i += $maxBatchSize) {
                $endIndex = [Math]::Min($i + $maxBatchSize - 1, $enabledArray.Count - 1)
                $batches.Add(@($enabledArray[$i..$endIndex]))
            }

            for ($batchIndex = 0; $batchIndex -lt $batches.Count; $batchIndex++) {
                $batch = $batches[$batchIndex]
                $globalBatchNumber++
                $batchNumber = $globalBatchNumber
                $totalBatches = $globalTotalBatches

                $nameList = [System.Collections.Generic.List[string]]::new()
                foreach ($bf in $batch) { $nameList.Add($bf.BaseName) }
                $fragmentNames = $nameList.ToArray()

                if (Get-Command Record-BatchLoading -ErrorAction SilentlyContinue) {
                    Record-BatchLoading -BatchNumber $batchNumber -TotalBatches $totalBatches -FragmentCount $batch.Count -FragmentNames $fragmentNames
                }

                if ($env:PS_PROFILE_DEBUG) {
                    if ($batchIndex -eq 0) { Write-BatchProgressTableHeader }
                    Write-BatchProgressRow -BatchNumber $batchNumber -TotalBatches $totalBatches -FragmentCount $batch.Count -FragmentNames $fragmentNames
                }

                $env:PS_PROFILE_DEBUG_PARALLEL_SUPPRESS = '1'
                $bootstrapFragmentPath = if ($BootstrapFragment -and $BootstrapFragment.Count -gt 0) { $BootstrapFragment[0].FullName } else { $null }
                $result = Invoke-FragmentsInParallel -FragmentFiles $batch -ProfileFragmentRoot $ProfileD -BootstrapFragmentPath $bootstrapFragmentPath
                $env:PS_PROFILE_DEBUG_PARALLEL_SUPPRESS = $null

                if ($result.SucceededFragments) {
                    foreach ($n in $result.SucceededFragments) {
                        if ($n) {
                            [void]$allSucceeded.Add($n)
                            [void]$levelSucceeded.Add($n)
                        }

                        if ($failedNames.Contains($n)) {
                            [void]$failedNames.Remove($n)
                            for ($j = $allFailed.Count - 1; $j -ge 0; $j--) {
                                if ($allFailed[$j].Name -eq $n) { $allFailed.RemoveAt($j); break }
                            }
                        }
                    }
                }

                if ($result.FailedFragments) {
                    foreach ($f in $result.FailedFragments) {
                        if ($f.Name -and -not $failedNames.Contains($f.Name)) {
                            $allFailed.Add(@{ Name = $f.Name; Error = $f.Error })
                            [void]$failedNames.Add($f.Name)
                        }
                        if ($f.Name) { [void]$levelFailed.Add($f.Name) }
                    }
                }

                $isSingleFragmentBatch = $batch.Count -eq 1
                if ((-not $result.UsedParallel -and -not $isSingleFragmentBatch) -or $result.FailureCount -gt 0) {
                    foreach ($frag in $batch) {
                        $ok = Invoke-_LoadOne -Fragment $frag
                        if ($ok -eq $true) {
                            [void]$allSucceeded.Add($frag.BaseName)
                            [void]$levelSucceeded.Add($frag.BaseName)
                        }
                        elseif ($ok -eq $false) {
                            if (-not $failedNames.Contains($frag.BaseName)) {
                                $allFailed.Add(@{ Name = $frag.BaseName; Error = 'Failed to load fragment' })
                                [void]$failedNames.Add($frag.BaseName)
                            }
                            [void]$levelFailed.Add($frag.BaseName)
                        }
                    }
                }
            }

            if ($env:PS_PROFILE_DEBUG) {
                Write-Host ""
                if ($levelSucceeded.Count -gt 0) { Write-Host "  ✓ Succeeded ($($levelSucceeded.Count))" -ForegroundColor Green }
                if ($levelFailed.Count -gt 0) { Write-Host "  ✗ Failed ($($levelFailed.Count))" -ForegroundColor Red }
                Write-Host ""
            }
        }
    }
    else {
        foreach ($frag in $FragmentsToLoad) {
            $ok = Invoke-_LoadOne -Fragment $frag
            if ($ok -eq $true) {
                [void]$allSucceeded.Add($frag.BaseName)
            }
            elseif ($ok -eq $false) {
                if (-not $failedNames.Contains($frag.BaseName)) {
                    $allFailed.Add(@{ Name = $frag.BaseName; Error = 'Failed to load fragment' })
                    [void]$failedNames.Add($frag.BaseName)
                }
            }
        }
    }

    if (Get-Command Record-FragmentResults -ErrorAction SilentlyContinue) {
        $succeededArray = @($allSucceeded)
        $failedArray = @($allFailed)
        Record-FragmentResults -SucceededFragments $succeededArray -FailedFragments $failedArray
    }

    if ($null -ne $dependencyParsingTimeMs -and (Get-Command Record-DependencyParsing -ErrorAction SilentlyContinue)) {
        Record-DependencyParsing -ParsingTime $dependencyParsingTimeMs -DependencyLevels $dependencyLevelsCount
    }
}

Export-ModuleMember -Function Initialize-FragmentLoading
