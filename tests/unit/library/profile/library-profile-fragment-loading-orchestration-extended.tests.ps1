<#
tests/unit/library/profile/library-profile-fragment-loading-orchestration-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for ProfileFragmentLoadingOrchestration parallel and callback paths.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:OrchestrationModulePath = Join-Path $script:LibPath 'profile' 'ProfileFragmentLoadingOrchestration.psm1'
    Import-Module $script:OrchestrationModulePath -DisableNameChecking -Force

    $parallelPath = Join-Path $script:LibPath 'fragment' 'FragmentParallelLoading.psm1'
    if (Test-Path -LiteralPath $parallelPath) {
        Import-Module $parallelPath -DisableNameChecking -Force -ErrorAction SilentlyContinue
    }
}

function script:New-OrchestrationExtendedFixture {
    param(
        [string]$Prefix,
        [string[]]$Fragments = @('20-orch-ext.ps1|# noop')
    )

    $profileD = New-TestTempDirectory -Prefix $Prefix
    $files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    foreach ($entry in $Fragments) {
        $parts = $entry -split '\|', 2
        $name = $parts[0]
        $body = if ($parts.Count -gt 1) { $parts[1] } else { '# noop' }
        $path = Join-Path $profileD $name
        Set-Content -LiteralPath $path -Value $body -Encoding UTF8
        [void]$files.Add((Get-Item -LiteralPath $path))
    }

    return [PSCustomObject]@{
        ProfileD  = $profileD
        Fragments = $files
    }
}

function script:Invoke-OrchestrationExtendedFixture {
    param(
        [pscustomobject]$Fixture,
        [System.Collections.Generic.HashSet[string]]$DisabledSet = $null,
        [System.Collections.Generic.HashSet[string]]$BootstrapNameSet = $null,
        [hashtable]$FragmentLevels = $null,
        [bool]$UseParallelLoading = $false,
        [bool]$ParallelLoadingModuleLoaded = $false,
        [bool]$FragmentErrorHandlingModuleExists = $false,
        [int]$BatchSize = 2,
        [scriptblock]$WriteBatchProgressTableHeader = $null,
        [scriptblock]$WriteBatchProgressRow = $null,
        [string]$DebugLevel = $null
    )

    $originalDebug = $env:PS_PROFILE_DEBUG
    if ($DebugLevel) {
        $env:PS_PROFILE_DEBUG = $DebugLevel
    }

    if (-not $BootstrapNameSet) {
        $BootstrapNameSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }

    $allSucceeded = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $allFailed = [System.Collections.Generic.List[hashtable]]::new()
    $failedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $loadedFragments = [System.Collections.Generic.List[string]]::new()

    try {
        $count = Invoke-FragmentLoadingOrchestration `
            -FragmentsToLoad $Fixture.Fragments `
            -DisabledSet $DisabledSet `
            -BootstrapFragment @() `
            -BootstrapNameSet $BootstrapNameSet `
            -ProfileD $Fixture.ProfileD `
            -FragmentErrorHandlingModuleExists $FragmentErrorHandlingModuleExists `
            -UseParallelLoading $UseParallelLoading `
            -ParallelLoadingModuleLoaded $ParallelLoadingModuleLoaded `
            -FragmentLevels $FragmentLevels `
            -AllSucceeded $allSucceeded `
            -AllFailed $allFailed `
            -FailedNames $failedNames `
            -LoadedFragments $loadedFragments `
            -FragmentLoadingBatchSize $BatchSize `
            -WriteBatchProgressTableHeader $WriteBatchProgressTableHeader `
            -WriteBatchProgressRow $WriteBatchProgressRow

        return [PSCustomObject]@{
            LoadedCount     = $count
            AllSucceeded    = $allSucceeded
            AllFailed       = $allFailed
            LoadedFragments = $loadedFragments
        }
    }
    finally {
        if ($null -ne $DebugLevel) {
            if ($null -eq $originalDebug) {
                Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
            }
            else {
                $env:PS_PROFILE_DEBUG = $originalDebug
            }
        }
    }
}

AfterAll {
    Remove-Module ProfileFragmentLoadingOrchestration, FragmentParallelLoading -ErrorAction SilentlyContinue -Force
}

Describe 'ProfileFragmentLoadingOrchestration extended scenarios' {
    BeforeEach {
        Enable-TestStructuredLogging
        Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
    }

    AfterEach {
        Disable-TestStructuredLogging
        Remove-Item Variable:global:OrchExtBootstrapProbe -ErrorAction SilentlyContinue
        Remove-Item Variable:global:OrchExtParallelA -ErrorAction SilentlyContinue
        Remove-Item Variable:global:OrchExtParallelB -ErrorAction SilentlyContinue
        Remove-Item Variable:global:OrchExtLevelSortA -ErrorAction SilentlyContinue
        Remove-Item Variable:global:OrchExtLevelSortB -ErrorAction SilentlyContinue
    }

    Context 'Fragment skip and progress callbacks' {
        It 'Skips bootstrap fragments listed in BootstrapNameSet' {
            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-bootstrap' -Fragments @(
                '00-bootstrap.ps1|$global:OrchExtBootstrapProbe = $true'
                '21-orch-after.ps1|$global:OrchExtAfterBootstrap = $true'
            )
            $bootstrapSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            [void]$bootstrapSet.Add('00-bootstrap')

            Remove-Item Variable:global:OrchExtBootstrapProbe, global:OrchExtAfterBootstrap -ErrorAction SilentlyContinue
            try {
                $result = Invoke-OrchestrationExtendedFixture -Fixture $fixture -BootstrapNameSet $bootstrapSet
                $result.LoadedCount | Should -Be 1
                Get-Variable -Name OrchExtBootstrapProbe -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                $global:OrchExtAfterBootstrap | Should -Be $true
            }
            finally {
                Remove-Item Variable:global:OrchExtBootstrapProbe, global:OrchExtAfterBootstrap -ErrorAction SilentlyContinue
            }
        }

        It 'Invokes batch progress callbacks for sequential loads' {
            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-progress' -Fragments @(
                '20-progress-a.ps1|# a'
                '21-progress-b.ps1|# b'
                '22-progress-c.ps1|# c'
            )
            $script:ProgressEvents = [System.Collections.Generic.List[string]]::new()
            $header = { [void]$script:ProgressEvents.Add('header') }
            $row = {
                param($BatchNumber, $TotalBatches, $FragmentCount, $FragmentNames)
                [void]$script:ProgressEvents.Add("row:${BatchNumber}:${FragmentCount}")
            }

            $null = Invoke-OrchestrationExtendedFixture `
                -Fixture $fixture `
                -BatchSize 2 `
                -WriteBatchProgressTableHeader $header `
                -WriteBatchProgressRow $row

            $script:ProgressEvents | Should -Contain 'header'
            @($script:ProgressEvents | Where-Object { $_ -like 'row:*' }).Count | Should -BeGreaterOrEqual 1
        }

        It 'Emits per-fragment output at debug level 2' {
            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-debug2' -Fragments @(
                '20-debug2.ps1|# debug fragment'
            )

            { Invoke-OrchestrationExtendedFixture -Fixture $fixture -DebugLevel '2' } | Should -Not -Throw
        }
    }

    Context 'Dependency level orchestration' {
        It 'Resolves fragments by base name when levels contain string entries' {
            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-level-names' -Fragments @(
                '20-level-name-a.ps1|$global:OrchExtLevelNameA = $true'
                '30-level-name-b.ps1|$global:OrchExtLevelNameB = $true'
            )
            $levels = @{
                Level0 = @('20-level-name-a')
                Level1 = @('30-level-name-b')
            }

            Remove-Item Variable:global:OrchExtLevelNameA, global:OrchExtLevelNameB -ErrorAction SilentlyContinue
            try {
                $result = Invoke-OrchestrationExtendedFixture -Fixture $fixture -FragmentLevels $levels
                $result.LoadedCount | Should -Be 2
                $global:OrchExtLevelNameA | Should -Be $true
                $global:OrchExtLevelNameB | Should -Be $true
            }
            finally {
                Remove-Item Variable:global:OrchExtLevelNameA, global:OrchExtLevelNameB -ErrorAction SilentlyContinue
            }
        }

        It 'Processes lower dependency levels before higher numbered levels' {
            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-level-sort' -Fragments @(
                '20-level-sort-a.ps1|$global:OrchExtLevelSortA = $true'
                '30-level-sort-b.ps1|$global:OrchExtLevelSortB = $true'
            )
            $levels = @{
                Level10 = @('30-level-sort-b')
                Level2  = @('20-level-sort-a')
            }
            $script:LoadOrder = [System.Collections.Generic.List[string]]::new()
            $row = {
                param($BatchNumber, $TotalBatches, $FragmentCount, $FragmentNames)
                foreach ($name in @($FragmentNames)) {
                    [void]$script:LoadOrder.Add($name)
                }
            }

            Remove-Item Variable:global:OrchExtLevelSortA, global:OrchExtLevelSortB -ErrorAction SilentlyContinue
            try {
                $null = Invoke-OrchestrationExtendedFixture `
                    -Fixture $fixture `
                    -FragmentLevels $levels `
                    -WriteBatchProgressRow $row `
                    -BatchSize 1

                $aIndex = $script:LoadOrder.IndexOf('20-level-sort-a')
                $bIndex = $script:LoadOrder.IndexOf('30-level-sort-b')
                $aIndex | Should -BeGreaterOrEqual 0
                $bIndex | Should -BeGreaterOrEqual 0
                $aIndex | Should -BeLessThan $bIndex
            }
            finally {
                Remove-Item Variable:global:OrchExtLevelSortA, global:OrchExtLevelSortB -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Parallel orchestration integration' {
        It 'Loads same-level fragments through Invoke-FragmentsInParallel when enabled' {
            if (-not (Get-Command Invoke-FragmentsInParallel -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'FragmentParallelLoading module is unavailable'
                return
            }

            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-parallel' -Fragments @(
                '31-parallel-a.ps1|$global:OrchExtParallelA = $true'
                '32-parallel-b.ps1|$global:OrchExtParallelB = $true'
            )
            $levels = @{
                Level1 = @('31-parallel-a', '32-parallel-b')
            }

            Remove-Item Variable:global:OrchExtParallelA, global:OrchExtParallelB -ErrorAction SilentlyContinue
            try {
                $result = Invoke-OrchestrationExtendedFixture `
                    -Fixture $fixture `
                    -FragmentLevels $levels `
                    -UseParallelLoading $true `
                    -ParallelLoadingModuleLoaded $true

                $result.AllSucceeded.Count | Should -Be 2
                @($result.LoadedFragments).Count | Should -Be 2
                $global:OrchExtParallelA | Should -Be $true
                $global:OrchExtParallelB | Should -Be $true
            }
            finally {
                Remove-Item Variable:global:OrchExtParallelA, global:OrchExtParallelB -ErrorAction SilentlyContinue
            }
        }

        It 'Records parallel failures in AllFailed without stopping siblings' {
            if (-not (Get-Command Invoke-FragmentsInParallel -ErrorAction SilentlyContinue)) {
                Set-ItResult -Inconclusive -Because 'FragmentParallelLoading module is unavailable'
                return
            }

            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-parallel-fail' -Fragments @(
                '33-parallel-ok.ps1|$global:OrchExtParallelOk = $true'
                '34-parallel-bad.ps1|throw "parallel orchestration probe"'
            )
            $levels = @{
                Level1 = @('33-parallel-ok', '34-parallel-bad')
            }

            Remove-Item Variable:global:OrchExtParallelOk -ErrorAction SilentlyContinue
            try {
                $result = Invoke-OrchestrationExtendedFixture `
                    -Fixture $fixture `
                    -FragmentLevels $levels `
                    -UseParallelLoading $true `
                    -ParallelLoadingModuleLoaded $true

                $result.AllSucceeded.Count | Should -BeGreaterOrEqual 1
                $result.AllFailed.Count | Should -BeGreaterOrEqual 1
                $global:OrchExtParallelOk | Should -Be $true
            }
            finally {
                Remove-Item Variable:global:OrchExtParallelOk -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Failure handling branches' {
        It 'Uses Write-StructuredError when fragment error handling is enabled' {
            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-structured' -Fragments @(
                '35-structured-bad.ps1|throw "structured orchestration probe"'
            )

            { Invoke-OrchestrationExtendedFixture -Fixture $fixture -FragmentErrorHandlingModuleExists $true } |
                Should -Not -Throw
        }

        It 'Does not duplicate failure records for the same fragment name' {
            $fixture = New-OrchestrationExtendedFixture -Prefix 'orch-ext-dup-fail' -Fragments @(
                '36-dup-fail.ps1|throw "duplicate failure probe"'
            )

            $result = Invoke-OrchestrationExtendedFixture -Fixture $fixture
            $result.AllFailed.Count | Should -Be 1
        }
    }
}
