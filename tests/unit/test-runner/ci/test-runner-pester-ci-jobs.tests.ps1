#Requires -Version 7.0
Describe 'Pester CI job packing' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
        Import-Module (Join-Path $repoRoot 'scripts/utils/code-quality/modules/PesterCiShardFilter.psm1') -Force
        Import-Module (Join-Path $repoRoot 'scripts/utils/code-quality/modules/PesterCiJobs.psm1') -Force
    }

    It 'preserves every full-inventory shard and platform exactly once' {
        $shards = @(Get-PesterCiAllShards)
        $original = @(Get-PesterCiShardMatrix -Shards $shards)
        $jobs = @(Get-PesterCiJobs -Shards $shards -MaxJobs 20)
        $jobs.Count | Should -Be 20
        $actual = @($jobs | ForEach-Object {
                $job = $_
                foreach ($shard in $job.shards) { "$($job.label)|$($job.os)|$($job.container)|$shard" }
            })
        $expected = @($original | ForEach-Object { "$($_.label)|$($_.os)|$($_.container)|$($_.shard)" })
        $actual.Count | Should -Be 86
        @($actual | Sort-Object -Unique).Count | Should -Be 86
        ($actual | Sort-Object) | Should -Be ($expected | Sort-Object)
        @($jobs | Where-Object { $_.shards.Count -eq 0 }).Count | Should -Be 0
    }

    It 'preserves a filtered selection and deduplicates input names' {
        $shards = @('unit-library', 'performance-profile-a', 'unit-library')
        $jobs = @(Get-PesterCiJobs -Shards $shards)
        $jobs.Count | Should -Be 4
        @($jobs | Where-Object { $_.shards -contains 'performance-profile-a' }).label | Should -Be 'windows-latest'
    }

    It 'handles empty selections without scheduling work' {
        @(Get-PesterCiJobs -Shards @()).Count | Should -Be 0
        @(Get-PesterCiJobs -Shards @('', $null)).Count | Should -Be 0
    }

    It 'rejects unknown shards and an insufficient platform job budget' {
        { Get-PesterCiJobs -Shards @('unknown-shard') } | Should -Throw '*Unknown*'
        { Get-PesterCiJobs -Shards @('unit-library') -MaxJobs 2 } | Should -Throw '*platform*'
    }

    It 'produces deterministic assignments' {
        $shards = @(Get-PesterCiAllShards)
        (Get-PesterCiJobs -Shards $shards | ConvertTo-Json -Depth 6) |
            Should -Be (Get-PesterCiJobs -Shards ($shards | Sort-Object -Descending) | ConvertTo-Json -Depth 6)
    }

    It 'selects full validation for job entrypoint and estimate changes' {
        foreach ($path in @('scripts/utils/code-quality/run-pester-ci-job.ps1', 'scripts/utils/code-quality/pester-ci-durations.json')) {
            (Resolve-PesterCiShards -ChangedFiles @($path) | Sort-Object) | Should -Be (Get-PesterCiAllShards | Sort-Object)
        }
    }
}

Describe 'Pester CI isolated job execution' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
        Import-Module (Join-Path $repoRoot 'scripts/utils/code-quality/modules/PesterCiJobs.psm1') -Force
        $fixture = Join-Path $TestDrive 'source with spaces'
        $entry = Join-Path $fixture 'scripts/utils/code-quality/run-pester-ci-shard.ps1'
        New-Item -ItemType Directory -Path (Split-Path $entry) -Force | Out-Null
        @'
param([string]$Shard, [switch]$Quiet)
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$results = Join-Path $root 'tests/test-artifacts/tools-batch'
New-Item -ItemType Directory -Path $results -Force | Out-Null
@{
    root = $root
    temp = [IO.Path]::GetTempPath()
    cache = $env:PS_PROFILE_CACHE_DIR
    revision = (& git rev-parse HEAD)
    contaminated = (Test-Path (Join-Path $env:TMPDIR 'marker'))
    processId = $PID
    started = [DateTimeOffset]::UtcNow.ToString('o')
} | ConvertTo-Json | Set-Content (Join-Path $results 'fixture.json')
Set-Content (Join-Path $env:TMPDIR 'marker') 'owned by this shard'
Set-Content (Join-Path $root 'coverage.xml') '<coverage />'
New-Item -ItemType Directory -Path (Join-Path $root 'scripts/data') -Force | Out-Null
Set-Content (Join-Path $root 'scripts/data/coverage.xml') '<coverage source="default" />'
if ($env:PESTER_CI_FIXTURE_PID_FILE) {
    Set-Content $env:PESTER_CI_FIXTURE_PID_FILE $PID
    Start-Sleep -Seconds 60
}
if ($env:PESTER_CI_FIXTURE_BARRIER) {
    Set-Content (Join-Path $env:PESTER_CI_FIXTURE_BARRIER $Shard) 'ready'
    $deadline = [DateTimeOffset]::UtcNow.AddSeconds(20)
    while (@(Get-ChildItem $env:PESTER_CI_FIXTURE_BARRIER).Count -lt 2 -and [DateTimeOffset]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 100
    }
    if (@(Get-ChildItem $env:PESTER_CI_FIXTURE_BARRIER).Count -lt 2) { throw 'Workers did not overlap' }
}
Set-Content (Join-Path $results 'finished.txt') ([DateTimeOffset]::UtcNow.ToString('o'))
if ($Shard -eq 'unit-support') { throw 'Expected fixture failure' }
'@
        | Set-Content $entry
        & git init --quiet $fixture
        & git -C $fixture add .
        & git -C $fixture -c user.name='CI Fixture' -c user.email='fixture@example.invalid' commit --quiet -m 'test: fixture'
        if ($LASTEXITCODE -ne 0) { throw 'Fixture commit failed' }
        $revision = (& git -C $fixture rev-parse HEAD).Trim()
        & git -C $fixture checkout --quiet --detach $revision
        & git -C $fixture -c user.name='CI Fixture' -c user.email='fixture@example.invalid' commit --quiet --allow-empty -m 'test: base'
        $baseRevision = (& git -C $fixture rev-parse HEAD).Trim()
        & git -C $fixture checkout --quiet --detach $revision
        & git -C $fixture -c user.name='CI Fixture' -c user.email='fixture@example.invalid' commit --quiet --allow-empty -m 'test: feature'
        & git -C $fixture -c user.name='CI Fixture' -c user.email='fixture@example.invalid' merge --quiet --no-ff $baseRevision -m 'test: synthetic merge'
        if ($LASTEXITCODE -ne 0) { throw 'Fixture merge failed' }
        $revision = (& git -C $fixture rev-parse HEAD).Trim()
    }

    It 'retains earlier failures, isolates paths, and collects batch and coverage reports' {
        $outputPath = Join-Path $TestDrive 'collected results'
        $originalTemp = [Environment]::GetEnvironmentVariable('TMPDIR', 'Process')
        $originalCache = [Environment]::GetEnvironmentVariable('PS_PROFILE_CACHE_DIR', 'Process')
        $result = Invoke-PesterCiJob -Shards @('unit-support', 'unit-utility') -RepoRoot $fixture -OutputPath $outputPath
        $result.Succeeded | Should -BeFalse
        $result.Results.Count | Should -Be 2
        $result.Results[0].ExitCode | Should -Not -Be 0
        $result.Results[1].ExitCode | Should -Be 0
        $observed = foreach ($shard in @('unit-support', 'unit-utility')) {
            Test-Path (Join-Path $outputPath "$shard/coverage.xml") | Should -BeTrue
            Get-Content (Join-Path $outputPath "$shard/scripts/data/coverage.xml") | Should -Match 'source="default"'
            Get-Content (Join-Path $outputPath "$shard/test-artifacts/tools-batch/fixture.json") -Raw | ConvertFrom-Json
        }
        $observed[0].root | Should -Not -Be $observed[1].root
        $observed[0].temp | Should -Not -Be $observed[1].temp
        $observed[0].cache | Should -Not -Be $observed[1].cache
        foreach ($item in $observed) {
            $item.revision | Should -Be $revision
            $item.contaminated | Should -BeFalse
            Test-Path $item.root | Should -BeFalse
        }
        Test-Path (Join-Path $outputPath 'summary.json') | Should -BeTrue
        Test-Path (Join-Path $fixture 'tests/test-artifacts') | Should -BeFalse
        [Environment]::GetEnvironmentVariable('TMPDIR', 'Process') | Should -Be $originalTemp
        [Environment]::GetEnvironmentVariable('PS_PROFILE_CACHE_DIR', 'Process') | Should -Be $originalCache
    }

    It 'rejects duplicate execution names before creating any results' {
        { Invoke-PesterCiJob -Shards @('unit-utility', 'unit-utility') -RepoRoot $fixture -OutputPath (Join-Path $TestDrive 'duplicate') } |
            Should -Throw '*duplicate*'
    }

    It 'reports collection failure even when the shard succeeds' {
        Mock Copy-Item -ModuleName PesterCiJobs { throw 'fixture collection failure' }
        $result = Invoke-PesterCiJob -Shards @('unit-utility') -RepoRoot $fixture -OutputPath (Join-Path $TestDrive 'copy failure')
        $result.Succeeded | Should -BeFalse
        $result.Results[0].Error | Should -Match 'fixture collection failure'
    }

    It 'continues after summary collection failure and reports it' {
        Mock Set-Content -ModuleName PesterCiJobs { throw 'fixture summary failure' }
        $result = Invoke-PesterCiJob -Shards @('unit-support', 'unit-utility') -RepoRoot $fixture -OutputPath (Join-Path $TestDrive 'summary failure')
        $result.Succeeded | Should -BeFalse
        $result.Results.Count | Should -Be 2
        $result.Results[1].ExitCode | Should -Be 0
        $result.Results[1].Error | Should -Match 'fixture summary failure'
    }

    It 'resolves relative output against the current PowerShell location' {
        Push-Location $TestDrive
        try {
            $result = Invoke-PesterCiJob -Shards @('unit-utility') -RepoRoot $fixture -OutputPath 'relative results'
            $result.Succeeded | Should -BeTrue
            Test-Path (Join-Path $TestDrive 'relative results/summary.json') | Should -BeTrue
        }
        finally { Pop-Location }
    }

    It 'runs overlapping isolated workers and retains each result' {
        $outputPath = Join-Path $TestDrive 'parallel results'
        $env:PESTER_CI_FIXTURE_BARRIER = Join-Path $TestDrive 'parallel barrier'
        New-Item -ItemType Directory -Path $env:PESTER_CI_FIXTURE_BARRIER | Out-Null
        try {
            $result = Invoke-PesterCiJob -Shards @('unit-support', 'unit-utility') -RepoRoot $fixture -OutputPath $outputPath -MaxParallelShards 2
        }
        finally { Remove-Item Env:PESTER_CI_FIXTURE_BARRIER -ErrorAction SilentlyContinue }
        $result.Succeeded | Should -BeFalse
        $result.Results.Count | Should -Be 2
        @($result.Results | Where-Object { $_.ExitCode -eq 0 }).Count | Should -Be 1
        $observed = foreach ($shard in @('unit-support', 'unit-utility')) {
            $artifactPath = Join-Path $outputPath "$shard/test-artifacts/tools-batch"
            $item = Get-Content (Join-Path $artifactPath 'fixture.json') -Raw | ConvertFrom-Json
            $item | Add-Member -NotePropertyName finished -NotePropertyValue (Get-Content (Join-Path $artifactPath 'finished.txt')) -PassThru
        }
        $observed[0].processId | Should -Not -Be $observed[1].processId
        $observed[0].root | Should -Not -Be $observed[1].root
        $observed[0].temp | Should -Not -Be $observed[1].temp
        $observed[0].cache | Should -Not -Be $observed[1].cache
        [DateTimeOffset]$observed[0].started | Should -BeLessThan ([DateTimeOffset]$observed[1].finished)
        [DateTimeOffset]$observed[1].started | Should -BeLessThan ([DateTimeOffset]$observed[0].finished)
    }

    It 'stops a native child and cleans its clone when its worker is cancelled' {
        $pidFile = Join-Path $TestDrive 'child-pid.txt'
        $outputPath = Join-Path $TestDrive 'cancelled worker'
        $env:PESTER_CI_FIXTURE_PID_FILE = $pidFile
        $modulePath = Join-Path $repoRoot 'scripts/utils/code-quality/modules/PesterCiJobs.psm1'
        $job = $null
        $childProcessId = $null
        try {
            $job = Start-Job -ScriptBlock {
                param($ModulePath, $Source, $Output)
                Import-Module $ModulePath -Force
                Invoke-PesterCiJob -Shards @('unit-utility') -RepoRoot $Source -OutputPath $Output
            } -ArgumentList $modulePath, $fixture, $outputPath
            $deadline = [DateTimeOffset]::UtcNow.AddSeconds(15)
            while (-not (Test-Path $pidFile) -and [DateTimeOffset]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
            Test-Path $pidFile | Should -BeTrue
            $childProcessId = [int](Get-Content $pidFile)
            Stop-Job $job
            Get-Process -Id $childProcessId -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            $record = Get-Content (Join-Path $outputPath 'unit-utility/test-artifacts/tools-batch/fixture.json') -Raw | ConvertFrom-Json
            Test-Path $record.root | Should -BeFalse
        }
        finally {
            Remove-Item Env:PESTER_CI_FIXTURE_PID_FILE -ErrorAction SilentlyContinue
            if ($job) { Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force -ErrorAction SilentlyContinue }
            if ($childProcessId) { Stop-Process -Id $childProcessId -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'keeps scheduling pending shards after a worker cleanup failure' {
        Mock Remove-Job -ModuleName PesterCiJobs { throw 'fixture worker cleanup failure' }
        try {
            $result = Invoke-PesterCiJob -Shards @('unit-support', 'unit-utility', 'unit-profile-core-lang') -RepoRoot $fixture -OutputPath (Join-Path $TestDrive 'worker cleanup') -MaxParallelShards 2
            $result.Succeeded | Should -BeFalse
            $result.Results.Count | Should -Be 3
            @($result.Results | Where-Object { $_.Shard -eq 'unit-profile-core-lang' -and $_.ExitCode -eq 0 }).Count | Should -Be 1
            @($result.Results | Where-Object { $_.Error -match 'fixture worker cleanup failure' }).Count | Should -Be 3
        }
        finally {
            Get-Job | Where-Object { $_.Name -like 'pester-ci-worker-*' } | Remove-Job -Force
        }
    }
}
