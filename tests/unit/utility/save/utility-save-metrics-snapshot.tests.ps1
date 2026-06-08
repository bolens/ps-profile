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
    It 'Writes a metrics snapshot JSON file to an isolated output directory' {
        $outputDir = New-TestTempDirectory -Prefix 'MetricsSnapshot'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:SaveSnapshotScript -ArgumentList @(
                '-OutputPath', $outputDir,
                '-IncludeCodeMetrics:False'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Metrics snapshot saved|Snapshot timestamp'

            $snapshotFiles = @(Get-ChildItem -LiteralPath $outputDir -Filter '*.json' -ErrorAction SilentlyContinue)
            $snapshotFiles.Count | Should -BeGreaterThan 0

            $snapshot = Get-Content -LiteralPath $snapshotFiles[0].FullName -Raw | ConvertFrom-Json
            $snapshot.Timestamp | Should -Not -BeNullOrEmpty
        }
        finally {
            if (Test-Path -LiteralPath $outputDir) {
                Remove-Item -LiteralPath $outputDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Omits code metrics when IncludeCodeMetrics is disabled' {
        $outputDir = New-TestTempDirectory -Prefix 'MetricsSnapshotNoCode'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:SaveSnapshotScript -ArgumentList @(
                '-OutputPath', $outputDir,
                '-IncludeCodeMetrics:False',
                '-IncludePerformanceMetrics:False'
            )

            $result.ExitCode | Should -Be 0
            $snapshotFiles = @(Get-ChildItem -LiteralPath $outputDir -Filter '*.json' -ErrorAction SilentlyContinue)
            $snapshotFiles.Count | Should -BeGreaterThan 0

            $snapshot = Get-Content -LiteralPath $snapshotFiles[0].FullName -Raw | ConvertFrom-Json
            $snapshot.PSObject.Properties.Name | Should -Not -Contain 'CodeMetrics'
        }
        finally {
            if (Test-Path -LiteralPath $outputDir) {
                Remove-Item -LiteralPath $outputDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Creates the output directory when it does not exist yet' {
        $parentDir = New-TestTempDirectory -Prefix 'MetricsSnapshotParent'
        $outputDir = Join-Path $parentDir 'nested' 'snapshots'
        try {
            Test-Path -LiteralPath $outputDir | Should -BeFalse

            $result = Invoke-TestScriptFile -ScriptPath $script:SaveSnapshotScript -ArgumentList @(
                '-OutputPath', $outputDir,
                '-IncludeCodeMetrics:False',
                '-IncludePerformanceMetrics:False'
            )

            $result.ExitCode | Should -Be 0
            Test-Path -LiteralPath $outputDir | Should -BeTrue
            @(Get-ChildItem -LiteralPath $outputDir -Filter '*.json').Count | Should -BeGreaterThan 0
        }
        finally {
            if (Test-Path -LiteralPath $parentDir) {
                Remove-Item -LiteralPath $parentDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
