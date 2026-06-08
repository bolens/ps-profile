<#
tests/unit/library-metrics-snapshot-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Save-MetricsSnapshot output content and uniqueness.
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
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $script:LibPath 'metrics' 'MetricsSnapshot.psm1') -DisableNameChecking -Force

    $script:TempDir = New-TestTempDirectory -Prefix 'MetricsSnapshotExtended'
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
}

AfterAll {
    Remove-Module MetricsSnapshot, JsonUtilities, FileSystem, PathResolution -ErrorAction SilentlyContinue -Force

    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'MetricsSnapshot extended scenarios' {
    Context 'Save-MetricsSnapshot' {
        It 'Includes the standard source label in every snapshot' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TempDir -RepoRoot $script:RepoRoot
            $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json

            $snapshot.Source | Should -Be 'PowerShell Profile Codebase'
        }

        It 'Creates unique snapshot files on consecutive saves' {
            $firstPath = Save-MetricsSnapshot -OutputPath $script:TempDir -RepoRoot $script:RepoRoot
            Start-Sleep -Milliseconds 1100
            $secondPath = Save-MetricsSnapshot -OutputPath $script:TempDir -RepoRoot $script:RepoRoot

            $firstPath | Should -Not -Be $secondPath
            Test-Path -LiteralPath $firstPath | Should -Be $true
            Test-Path -LiteralPath $secondPath | Should -Be $true
        }

        It 'Can include both code and performance metrics flags together' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TempDir -IncludeCodeMetrics -IncludePerformanceMetrics -RepoRoot $script:RepoRoot
            $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json

            $snapshot.Timestamp | Should -Not -BeNullOrEmpty
            $snapshot.PSObject.Properties.Name | Should -Contain 'Source'
        }

        It 'Writes snapshots only under the requested output directory' {
            $customDir = Join-Path $script:TempDir 'custom-history'
            $snapshotPath = Save-MetricsSnapshot -OutputPath $customDir -RepoRoot $script:RepoRoot

            Split-Path -Parent $snapshotPath | Should -Be (Resolve-Path -LiteralPath $customDir).Path
        }
    }
}
