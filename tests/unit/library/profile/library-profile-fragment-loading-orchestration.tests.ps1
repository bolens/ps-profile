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
    $script:OrchestrationModulePath = Join-Path $script:RepoRoot 'scripts' 'lib' 'profile' 'ProfileFragmentLoadingOrchestration.psm1'
    Import-Module $script:OrchestrationModulePath -DisableNameChecking -Force
}

function script:New-OrchestrationFixture {
        param(
            [string]$Prefix,
            [string[]]$Fragments = @('20-orch.ps1|# noop')
        )

        $profileD = Join-Path $TestDrive $Prefix
        New-Item -ItemType Directory -Path $profileD -Force | Out-Null
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

function script:Invoke-OrchestrationFixture {
        param(
            [pscustomobject]$Fixture,
            [System.Collections.Generic.HashSet[string]]$DisabledSet = $null,
            [hashtable]$FragmentLevels = $null,
            [bool]$UseParallelLoading = $false,
            [bool]$ParallelLoadingModuleLoaded = $false,
            [string]$DebugLevel = $null
        )

        $originalDebug = $env:PS_PROFILE_DEBUG
        if ($DebugLevel) {
            $env:PS_PROFILE_DEBUG = $DebugLevel
        }

        $allSucceeded = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $allFailed = [System.Collections.Generic.List[hashtable]]::new()
        $failedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $loadedFragments = [System.Collections.Generic.List[string]]::new()
        $bootstrapNameSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        try {
            $count = Invoke-FragmentLoadingOrchestration `
                -FragmentsToLoad $Fixture.Fragments `
                -DisabledSet $DisabledSet `
                -BootstrapFragment @() `
                -BootstrapNameSet $bootstrapNameSet `
                -ProfileD $Fixture.ProfileD `
                -FragmentErrorHandlingModuleExists $false `
                -UseParallelLoading $UseParallelLoading `
                -ParallelLoadingModuleLoaded $ParallelLoadingModuleLoaded `
                -FragmentLevels $FragmentLevels `
                -AllSucceeded $allSucceeded `
                -AllFailed $allFailed `
                -FailedNames $failedNames `
                -LoadedFragments $loadedFragments `
                -FragmentLoadingBatchSize 10 `
                -WriteBatchProgressTableHeader $null `
                -WriteBatchProgressRow $null

            return [PSCustomObject]@{
                LoadedCount      = $count
                AllSucceeded     = $allSucceeded
                AllFailed        = $allFailed
                LoadedFragments  = $loadedFragments
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

Describe 'ProfileFragmentLoadingOrchestration' {
    It 'Loads fragments and records successes' {
        $fixture = New-OrchestrationFixture -Prefix 'orch-basic' -Fragments @(
            '20-orch-a.ps1|$global:OrchProbeA = $true'
            '30-orch-b.ps1|$global:OrchProbeB = $true'
        )

        try {
            Remove-Variable -Name OrchProbeA, OrchProbeB -Scope Global -ErrorAction SilentlyContinue
            $result = Invoke-OrchestrationFixture -Fixture $fixture
            $result.LoadedCount | Should -Be 2
            $result.AllSucceeded.Count | Should -Be 2
            $global:OrchProbeA | Should -Be $true
            $global:OrchProbeB | Should -Be $true
        }
        finally {
            Remove-Variable -Name OrchProbeA, OrchProbeB -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'Skips disabled fragments' {
        $fixture = New-OrchestrationFixture -Prefix 'orch-disabled' -Fragments @(
            '20-orch-disabled.ps1|$global:OrchDisabledProbe = $true'
        )
        $disabled = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        [void]$disabled.Add('20-orch-disabled')

        try {
            Remove-Variable -Name OrchDisabledProbe -Scope Global -ErrorAction SilentlyContinue
            $result = Invoke-OrchestrationFixture -Fixture $fixture -DisabledSet $disabled
            $result.LoadedCount | Should -Be 0
            Get-Variable -Name OrchDisabledProbe -Scope Global -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
        finally {
            Remove-Variable -Name OrchDisabledProbe -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'Records failures without stopping other fragments' {
        $fixture = New-OrchestrationFixture -Prefix 'orch-fail' -Fragments @(
            '20-orch-ok.ps1|$global:OrchFailOk = $true'
            '30-orch-bad.ps1|throw "orch failure probe"'
        )

        try {
            Remove-Variable -Name OrchFailOk -Scope Global -ErrorAction SilentlyContinue
            $result = Invoke-OrchestrationFixture -Fixture $fixture
            $result.AllSucceeded.Count | Should -Be 1
            $result.AllFailed.Count | Should -Be 1
            $global:OrchFailOk | Should -Be $true
        }
        finally {
            Remove-Variable -Name OrchFailOk -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'Populates LoadedFragments for debug level 1 batching' {
        $fragments = 1..12 | ForEach-Object { "2$($_)-orch-batch.ps1|# fragment $_" }
        $fixture = New-OrchestrationFixture -Prefix 'orch-batch' -Fragments $fragments

        $result = Invoke-OrchestrationFixture -Fixture $fixture -DebugLevel '1'
        $result.LoadedFragments.Count | Should -Be 12
    }

    It 'Loads fragments by dependency level when levels are provided' {
        $fixture = New-OrchestrationFixture -Prefix 'orch-levels' -Fragments @(
            '20-level-a.ps1|$global:OrchLevelA = $true'
            '30-level-b.ps1|$global:OrchLevelB = $true'
        )
        $levels = @{
            Level0 = @('20-level-a')
            Level1 = @('30-level-b')
        }

        try {
            Remove-Variable -Name OrchLevelA, OrchLevelB -Scope Global -ErrorAction SilentlyContinue
            $result = Invoke-OrchestrationFixture -Fixture $fixture -FragmentLevels $levels
            $result.LoadedCount | Should -Be 2
            $global:OrchLevelA | Should -Be $true
            $global:OrchLevelB | Should -Be $true
        }
        finally {
            Remove-Variable -Name OrchLevelA, OrchLevelB -Scope Global -ErrorAction SilentlyContinue
        }
    }
}
