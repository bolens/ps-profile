#Requires -Version 7.0
$moduleImportPath = Join-Path $PSScriptRoot '../../../lib/ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-Module (Join-Path $PSScriptRoot 'PesterCiShardFilter.psm1') -DisableNameChecking -ErrorAction Stop
Set-StrictMode -Version Latest

function Get-PesterCiJobs {
    <#
    .SYNOPSIS
        Packs the existing platform inventory into balanced compatible CI jobs.
    .DESCRIPTION
        Estimates affect placement only. Every selected shard/platform pair remains present.
    .PARAMETER Shards
        Selected shard names from Resolve-PesterCiShards.
    .PARAMETER MaxJobs
        Maximum total jobs, with at least one for each selected platform.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][AllowNull()][AllowEmptyString()][string[]]$Shards,
        [ValidateRange(1, 256)][int]$MaxJobs = 20
    )
    $names = @($Shards | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    $known = @(Get-PesterCiAllShards)
    foreach ($name in $names) {
        if ($name -notin $known) { throw "Unknown CI shard: $name" }
    }
    $inventory = @(Get-PesterCiShardMatrix -Shards $names)
    if ($inventory.Count -eq 0) { return @() }
    $estimates = Get-Content (Join-Path $PSScriptRoot '../pester-ci-durations.json') -Raw | ConvertFrom-Json -AsHashtable
    $platforms = @($inventory | Group-Object label | Sort-Object Name | ForEach-Object {
            $entries = @($_.Group | ForEach-Object {
                    $key = "$($_.label)/$($_.shard)"
                    $seconds = if ($estimates.seconds.ContainsKey($key)) { [double]$estimates.seconds[$key] } else { 300.0 }
                    if ($seconds -le 0) { throw "Invalid duration estimate: $key" }
                    [pscustomobject]@{ Entry = $_; Seconds = $seconds + 5 }
                })
            [pscustomobject]@{ Name = $_.Name; Entries = $entries; Count = 1; Total = ($entries.Seconds | Measure-Object -Sum).Sum }
        })
    if ($MaxJobs -lt $platforms.Count) { throw 'Job budget must cover every selected platform.' }
    $budget = [Math]::Min($MaxJobs, $inventory.Count)
    for ($assigned = $platforms.Count; $assigned -lt $budget; $assigned++) {
        $platform = $platforms | Where-Object { $_.Count -lt $_.Entries.Count } |
            Sort-Object @{ Expression = { $_.Total / $_.Count }; Descending = $true }, Name | Select-Object -First 1
        $platform.Count++
    }
    foreach ($platform in $platforms) {
        $first = $platform.Entries[0].Entry
        $bins = @(for ($index = 1; $index -le $platform.Count; $index++) {
                [pscustomobject]@{
                    label = $first.label; os = $first.os; container = $first.container
                    job = "bundle-$index"; shards = [System.Collections.Generic.List[string]]::new(); estimatedSeconds = 0.0
                }
            })
        foreach ($item in @($platform.Entries | Sort-Object @{ Expression = { $_.Seconds }; Descending = $true }, @{ Expression = { $_.Entry.shard } })) {
            $bin = $bins | Sort-Object estimatedSeconds, job | Select-Object -First 1
            $bin.shards.Add($item.Entry.shard)
            $bin.estimatedSeconds += $item.Seconds
        }
        $bins
    }
}

function Invoke-PesterCiJob {
    <#
    .SYNOPSIS
        Runs shards in separate checkouts, optionally using two process workers.
    .DESCRIPTION
        Retains all shard artifacts and returns failure if setup, execution, collection,
        or cleanup fails. The source checkout is never used for test execution.
    .PARAMETER Shards
        Unique valid shard names to execute in order.
    .PARAMETER RepoRoot
        Source checkout whose exact HEAD is tested, including synthetic merge commits.
    .PARAMETER OutputPath
        Job-owned result directory outside every temporary clone.
    .PARAMETER MaxParallelShards
        Maximum isolated worker processes. One retains serial execution.
    .PARAMETER SummaryFile
        Unique summary filename for a worker sharing the collection directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$Shards,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$OutputPath,
        [ValidateRange(1, 2)][int]$MaxParallelShards = 1,
        [ValidatePattern('^[a-z0-9-]+\.json$')][string]$SummaryFile = 'summary.json'
    )
    $ErrorActionPreference = 'Stop'
    # Native failures are recorded per shard instead of terminating the remaining work.
    $PSNativeCommandUseErrorActionPreference = $false
    $known = @(Get-PesterCiAllShards)
    if (@($Shards | Sort-Object -Unique).Count -ne $Shards.Count) { throw 'Execution contains duplicate shards.' }
    foreach ($name in $Shards) {
        if ($name -notin $known) { throw "Unknown CI shard: $name" }
    }
    $source = (Get-Item -LiteralPath $RepoRoot -ErrorAction Stop).FullName
    $output = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    New-Item -ItemType Directory -Path $output -Force -ErrorAction Stop | Out-Null
    $revision = & git -C $source rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve source revision.' }
    $revision = "$revision".Trim()
    $pwsh = Get-PowerShellExecutable
    $results = [System.Collections.Generic.List[object]]::new()
    if ($MaxParallelShards -gt 1 -and $Shards.Count -gt 1) {
        # Start-Job uses separate processes: unlike thread jobs, worker environment
        # changes cannot race with another worker's checkout, temp, or cache paths.
        $pending = [System.Collections.Generic.Queue[string]]::new()
        foreach ($shard in $Shards) { $pending.Enqueue($shard) }
        $running = [System.Collections.Generic.List[object]]::new()
        $cleanupPending = [System.Collections.Generic.List[object]]::new()
        $workerModule = Join-Path $PSScriptRoot 'PesterCiJobs.psm1'
        try {
            while ($pending.Count -gt 0 -or $running.Count -gt 0) {
                while ($pending.Count -gt 0 -and $running.Count -lt $MaxParallelShards) {
                    $shard = $pending.Dequeue()
                    $started = [DateTimeOffset]::UtcNow
                    try {
                        $job = Start-Job -Name ('pester-ci-worker-' + [guid]::NewGuid().ToString('N')) -ScriptBlock {
                            param($ModulePath, $Source, $Shard, $Output)
                            Import-Module $ModulePath -DisableNameChecking -ErrorAction Stop
                            Invoke-PesterCiJob -Shards @($Shard) -RepoRoot $Source -OutputPath $Output -SummaryFile "$Shard-summary.json"
                        } -ArgumentList $workerModule, $source, $shard, $output -ErrorAction Stop
                        $running.Add([pscustomobject]@{ Job = $job; Shard = $shard; Started = $started })
                    }
                    catch {
                        $results.Add([pscustomobject]@{ Shard = $shard; Revision = $revision; DurationSeconds = 0.0; ExitCode = $EXIT_SETUP_ERROR; Error = $_.Exception.Message })
                    }
                }
                if ($running.Count -eq 0) { continue }
                $completed = Wait-Job -Job @($running.Job) -Any
                $worker = $running | Where-Object { $_.Job.Id -eq $completed.Id } | Select-Object -First 1
                try {
                    $received = Receive-Job -Job $completed -ErrorAction Stop
                    if ($completed.State -ne 'Completed' -or $null -eq $received -or @($received.Results).Count -ne 1) {
                        throw "Worker returned no complete result for $($worker.Shard)"
                    }
                    $results.Add($received.Results[0])
                }
                catch {
                    $results.Add([pscustomobject]@{ Shard = $worker.Shard; Revision = $revision; DurationSeconds = ([DateTimeOffset]::UtcNow - $worker.Started).TotalSeconds; ExitCode = $EXIT_SETUP_ERROR; Error = $_.Exception.Message })
                }
                finally {
                    try { Remove-Job -Job $completed -Force -ErrorAction Stop }
                    catch {
                        $lastResult = $results[$results.Count - 1]
                        $lastResult.Error = "$($lastResult.Error) Worker cleanup: $($_.Exception.Message)".Trim()
                        $cleanupPending.Add($completed)
                    }
                    finally { $null = $running.Remove($worker) }
                }
            }
        }
        finally {
            foreach ($worker in $running) {
                Stop-Job -Job $worker.Job -ErrorAction SilentlyContinue
                Remove-Job -Job $worker.Job -Force -ErrorAction SilentlyContinue
            }
            foreach ($job in $cleanupPending) {
                try { Remove-Job -Job $job -Force -ErrorAction Stop }
                catch { Write-Warning "Worker cleanup retry failed: $($_.Exception.Message)" }
            }
        }
        try {
            ConvertTo-Json -InputObject $results.ToArray() -Depth 5 |
                Set-Content -LiteralPath (Join-Path $output $SummaryFile) -ErrorAction Stop
        }
        catch {
            $results[0].Error = "$($results[0].Error) Summary collection: $($_.Exception.Message)".Trim()
        }
        $failed = @($results | Where-Object { $_.ExitCode -ne 0 -or $_.Error })
        return [pscustomobject]@{ Succeeded = ($failed.Count -eq 0); Results = $results.ToArray() }
    }
    foreach ($shard in $Shards) {
        $work = Join-Path ([IO.Path]::GetTempPath()) ('pester-ci-' + [guid]::NewGuid().ToString('N'))
        $clone = Join-Path $work 'repo'
        $temp = Join-Path $work 'temp'
        $destination = Join-Path $output $shard
        $timer = [Diagnostics.Stopwatch]::StartNew()
        $result = [pscustomobject]@{ Shard = $shard; Revision = $revision; DurationSeconds = 0.0; ExitCode = $EXIT_SETUP_ERROR; Error = $null }
        $previous = @{}
        $locationPushed = $false
        try {
            New-Item -ItemType Directory -Path $temp, $destination -Force -ErrorAction Stop | Out-Null
            # The source stays untouched, so shared Git objects remain available throughout the job.
            & git clone --quiet --shared --no-checkout -- $source $clone
            if ($LASTEXITCODE -ne 0) { throw "Clone failed for $shard" }
            & git -C $clone checkout --quiet --detach $revision
            if ($LASTEXITCODE -ne 0) { throw "Checkout failed for $shard" }
            $actual = & git -C $clone rev-parse HEAD
            if ($LASTEXITCODE -ne 0 -or "$actual".Trim() -ne $revision) { throw "Revision mismatch for $shard" }
            $environment = @{
                TEMP = $temp; TMP = $temp; TMPDIR = $temp
                PS_PROFILE_CACHE_DIR = (Join-Path $work 'cache')
                PS_PROFILE_REPO_ROOT = $clone
            }
            foreach ($key in $environment.Keys) {
                $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
                [Environment]::SetEnvironmentVariable($key, $environment[$key], 'Process')
            }
            Push-Location -LiteralPath $clone
            $locationPushed = $true
            Write-Host "Running $shard at $revision"
            & $pwsh -NoProfile -NonInteractive -File (Join-Path $clone 'scripts/utils/code-quality/run-pester-ci-shard.ps1') -Shard $shard -Quiet | Out-Host
            $result.ExitCode = $LASTEXITCODE
        }
        catch {
            $result.Error = $_.Exception.Message
            Write-Warning "$shard failed: $($result.Error)"
        }
        finally {
            if ($locationPushed) { Pop-Location }
            foreach ($key in $previous.Keys) {
                if ($null -eq $previous[$key]) { Remove-Item -LiteralPath "Env:$key" -ErrorAction SilentlyContinue }
                else { [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process') }
            }
            try {
                $artifacts = Join-Path $clone 'tests/test-artifacts'
                if (Test-Path -LiteralPath $artifacts) {
                    Copy-Item -LiteralPath $artifacts -Destination (Join-Path $destination 'test-artifacts') -Recurse -Force -ErrorAction Stop
                }
                foreach ($relativeCoverage in @('coverage.xml', 'scripts/data/coverage.xml')) {
                    $coverage = Join-Path $clone $relativeCoverage
                    if (Test-Path -LiteralPath $coverage) {
                        $coverageDestination = Join-Path $destination $relativeCoverage
                        New-Item -ItemType Directory -Path (Split-Path $coverageDestination) -Force -ErrorAction Stop | Out-Null
                        Copy-Item -LiteralPath $coverage -Destination $coverageDestination -Force -ErrorAction Stop
                    }
                }
            }
            catch {
                $result.Error = "$($result.Error) Artifact collection: $($_.Exception.Message)".Trim()
            }
            try {
                if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction Stop }
            }
            catch {
                $result.Error = "$($result.Error) Cleanup: $($_.Exception.Message)".Trim()
            }
            $timer.Stop()
            $result.DurationSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 2)
            $results.Add($result)
            try {
                ConvertTo-Json -InputObject $results.ToArray() -Depth 5 |
                    Set-Content -LiteralPath (Join-Path $output $SummaryFile) -ErrorAction Stop
            }
            catch {
                $result.Error = "$($result.Error) Summary collection: $($_.Exception.Message)".Trim()
                Write-Warning $result.Error
            }
        }
    }
    $failed = @($results | Where-Object { $_.ExitCode -ne 0 -or $_.Error })
    return [pscustomobject]@{ Succeeded = ($failed.Count -eq 0); Results = $results.ToArray() }
}

Export-ModuleMember -Function Get-PesterCiJobs, Invoke-PesterCiJob
