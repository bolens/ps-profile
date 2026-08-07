<#
tests/unit/utility-save-metrics-snapshot.tests.ps1

.SYNOPSIS
    Behavioral unit tests for save-metrics-snapshot.ps1 with an isolated output directory.
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:SaveSnapshotScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'save-metrics-snapshot.ps1'
    $ConfirmPreference = 'None'
}

Describe 'save-metrics-snapshot.ps1 execution' {
    BeforeEach {
        $script:PreviousDebug = $env:PS_PROFILE_DEBUG
        $env:PS_PROFILE_DEBUG = '2'
    }

    AfterEach {
        if ($null -eq $script:PreviousDebug) {
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
        }
        else {
            $env:PS_PROFILE_DEBUG = $script:PreviousDebug
        }
    }

    It 'creates an isolated snapshot without disabled metric sections' {
        $parentDir = New-TestTempDirectory -Prefix 'MetricsSnapshot'
        $outputDir = Join-Path $parentDir 'nested' 'snapshots'
        Test-Path -LiteralPath $outputDir | Should -BeFalse

        { & $script:SaveSnapshotScript -OutputPath $outputDir -IncludeCodeMetrics:$false -Verbose } | Should -Not -Throw

        Test-Path -LiteralPath $outputDir | Should -BeTrue
        $snapshotFiles = @(Get-ChildItem -LiteralPath $outputDir -Filter '*.json' -ErrorAction SilentlyContinue)
        $snapshotFiles.Count | Should -BeGreaterThan 0

        $snapshot = Get-Content -LiteralPath $snapshotFiles[0].FullName -Raw | ConvertFrom-Json
        $snapshot.Timestamp | Should -Not -BeNullOrEmpty
        $snapshot.PSObject.Properties.Name | Should -Not -Contain 'CodeMetrics'
        $snapshot.PSObject.Properties.Name | Should -Not -Contain 'PerformanceMetrics'
    }

    It 'continues without code metrics when collection is unavailable' {
        $repositoryRoot = New-TestTempDirectory -Prefix 'MetricsSnapshotRepo'
        $outputDir = Join-Path $repositoryRoot 'output'

        {
            & $script:SaveSnapshotScript -RepositoryRoot $repositoryRoot -OutputPath $outputDir -IncludeCodeMetrics
        } | Should -Not -Throw

        $snapshotFile = Get-ChildItem -LiteralPath $outputDir -Filter '*.json' | Select-Object -First 1
        $snapshot = Get-Content -LiteralPath $snapshotFile.FullName -Raw | ConvertFrom-Json
        $snapshot.PSObject.Properties.Name | Should -Not -Contain 'CodeMetrics'
    }
}
