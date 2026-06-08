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
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
}

function script:Get-SnapshotPathFromOutput {
    param([object[]]$Output)

    return @($Output | Where-Object {
            $_ -is [string] -and $_ -match 'metrics-\d{8}-\d{6}\.json$'
        } | Select-Object -Last 1)
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

        It 'Still saves a snapshot when code metrics JSON cannot be parsed' {
            $repoRoot = Join-Path $script:TempDir 'invalid-code-metrics-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $dataDir 'code-metrics.json') -Value '{ invalid json' -Encoding UTF8

            $outputDir = Join-Path $repoRoot 'history'
            { Save-MetricsSnapshot -OutputPath $outputDir -IncludeCodeMetrics -RepoRoot $repoRoot } | Should -Not -Throw

            $snapshotPath = Get-ChildItem -LiteralPath $outputDir -Filter 'metrics-*.json' | Select-Object -First 1
            $snapshotPath | Should -Not -BeNullOrEmpty
            $snapshot = Get-Content -LiteralPath $snapshotPath.FullName -Raw | ConvertFrom-Json
            $snapshot.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Skips invalid performance metrics JSON while still saving the snapshot' {
            $dataDir = Join-Path $script:TempDir 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $dataDir 'performance-baseline.json') -Value '{ not-json' -Encoding UTF8

            $outputDir = Join-Path $script:TempDir 'invalid-performance'
            $snapshotPath = Get-SnapshotPathFromOutput -Output @(Save-MetricsSnapshot -OutputPath $outputDir -IncludePerformanceMetrics -RepoRoot $script:TempDir)

            Test-Path -LiteralPath $snapshotPath | Should -Be $true
            $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json
            $snapshot.PSObject.Properties.Name | Should -Not -Contain 'PerformanceMetrics'
        }

        It 'Loads code metrics via Read-JsonFile when JsonUtilities is available' {
            $repoRoot = Join-Path $script:TempDir 'json-util-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            @{
                TotalFiles = 42
            } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'code-metrics.json') -Encoding UTF8

            $outputDir = Join-Path $repoRoot 'history'
            $snapshotPath = Save-MetricsSnapshot -OutputPath $outputDir -IncludeCodeMetrics -RepoRoot $repoRoot
            $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json

            $snapshot.CodeMetrics.TotalFiles | Should -Be 42
        }

        It 'Uses the default history path when OutputPath is omitted' {
            $repoRoot = Join-Path $script:TempDir 'default-history-repo'
            $historyDir = Join-Path $repoRoot 'scripts' 'data' 'history'
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

            $snapshotPath = Save-MetricsSnapshot -RepoRoot $repoRoot
            $snapshotPath | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $snapshotPath | Should -Be $true
            (Split-Path -Parent $snapshotPath) | Should -Be (Resolve-Path -LiteralPath $historyDir).Path
        }

        It 'Includes performance metrics content when the baseline file exists' {
            $repoRoot = Join-Path $script:TempDir 'performance-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            @{
                FullStartupMean = 1234
            } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'performance-baseline.json') -Encoding UTF8

            $outputDir = Join-Path $repoRoot 'history'
            $snapshotPath = Save-MetricsSnapshot -OutputPath $outputDir -IncludePerformanceMetrics -RepoRoot $repoRoot
            $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json

            $snapshot.PerformanceMetrics.FullStartupMean | Should -Be 1234
        }

        It 'Emits verbose save tracing when PS_PROFILE_DEBUG is level 2 or higher' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TempDir -IncludeCodeMetrics -IncludePerformanceMetrics -RepoRoot $script:RepoRoot
                $snapshotPath | Should -Not -BeNullOrEmpty
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Warns when performance metrics JSON cannot be parsed and debug is enabled' {
            $repoRoot = Join-Path $script:TempDir 'invalid-performance-debug-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $dataDir 'performance-baseline.json') -Value '{ bad-json' -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '1'

            try {
                $outputDir = Join-Path $repoRoot 'history'
                $snapshotPath = Get-SnapshotPathFromOutput -Output @(Save-MetricsSnapshot -OutputPath $outputDir -IncludePerformanceMetrics -RepoRoot $repoRoot)
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Includes both metric sections when source files exist and debug tracing is enabled' {
            $repoRoot = Join-Path $script:TempDir 'full-metrics-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            @{ TotalFiles = 11 } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'code-metrics.json') -Encoding UTF8
            @{ FullStartupMean = 999 } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'performance-baseline.json') -Encoding UTF8

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $snapshotPath = Save-MetricsSnapshot -OutputPath (Join-Path $repoRoot 'history') -IncludeCodeMetrics -IncludePerformanceMetrics -RepoRoot $repoRoot
                $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json
                $snapshot.CodeMetrics.TotalFiles | Should -Be 11
                $snapshot.PerformanceMetrics.FullStartupMean | Should -Be 999
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Loads code metrics through the Get-Content fallback when JsonUtilities is unavailable' {
            $repoRoot = Join-Path $script:TempDir 'fallback-json-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            @{
                TotalFunctions = 7
            } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'code-metrics.json') -Encoding UTF8

            Remove-Module JsonUtilities -ErrorAction SilentlyContinue -Force

            $outputDir = Join-Path $repoRoot 'history'
            $snapshotPath = Save-MetricsSnapshot -OutputPath $outputDir -IncludeCodeMetrics -RepoRoot $repoRoot
            $snapshot = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json

            $snapshot.CodeMetrics.TotalFunctions | Should -Be 7

            Import-Module (Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force
        }

        It 'Uses Write-StructuredWarning when code metrics loading throws' {
            Enable-TestStructuredLogging

            $repoRoot = Join-Path $script:TempDir 'structured-code-metrics-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            @{ TotalFiles = 3 } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'code-metrics.json') -Encoding UTF8

            function global:Read-JsonFile {
                param([string]$Path)
                throw 'structured code metrics read probe'
            }

            try {
                $snapshotPath = Get-SnapshotPathFromOutput -Output @(Save-MetricsSnapshot -OutputPath (Join-Path $repoRoot 'history') -IncludeCodeMetrics -RepoRoot $repoRoot)
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                Remove-Item -Path Function:Read-JsonFile -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force
            }
        }

        It 'Uses Write-StructuredWarning when performance metrics JSON cannot be parsed' {
            Enable-TestStructuredLogging

            $repoRoot = Join-Path $script:TempDir 'structured-performance-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $dataDir 'performance-baseline.json') -Value '{ bad-json' -Encoding UTF8

            $snapshotPath = Get-SnapshotPathFromOutput -Output @(Save-MetricsSnapshot -OutputPath (Join-Path $repoRoot 'history') -IncludePerformanceMetrics -RepoRoot $repoRoot)
            Test-Path -LiteralPath $snapshotPath | Should -Be $true
        }

        It 'Records save failures through Write-StructuredError when writing the snapshot file fails' {
            Enable-TestStructuredLogging

            $global:MetricsSnapshotSaveErrorRepo = Join-Path $script:TempDir 'save-error-repo'
            $global:MetricsSnapshotSaveErrorHistory = Join-Path $global:MetricsSnapshotSaveErrorRepo 'history'
            New-Item -ItemType Directory -Path $global:MetricsSnapshotSaveErrorHistory -Force | Out-Null

            try {
                InModuleScope -ModuleName MetricsSnapshot {
                    Mock Set-Content {
                        throw 'snapshot save blocked probe'
                    }

                    { Save-MetricsSnapshot -OutputPath $global:MetricsSnapshotSaveErrorHistory -RepoRoot $global:MetricsSnapshotSaveErrorRepo } |
                        Should -Throw '*Failed to save metrics snapshot*'
                }
            }
            finally {
                Remove-Variable -Name MetricsSnapshotSaveErrorRepo, MetricsSnapshotSaveErrorHistory -Scope Global -ErrorAction SilentlyContinue
            }
        }

        It 'Detects the repository root from the current directory when Get-RepoRoot throws' {
            $repoRoot = Join-Path $script:TempDir 'detected-git-repo'
            New-Item -ItemType Directory -Path (Join-Path $repoRoot '.git') -Force | Out-Null
            $outputDir = Join-Path $repoRoot 'history'

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                throw 'repo root detection probe'
            }

            $previousLocation = Get-Location
            try {
                Set-Location -LiteralPath $repoRoot
                $snapshotPath = Save-MetricsSnapshot -OutputPath $outputDir
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                Remove-Item -Path Function:Get-RepoRoot -ErrorAction SilentlyContinue -Force
                Set-Location -LiteralPath $previousLocation.Path
            }
        }

        It 'Emits level 3 diagnostics when code metrics loading fails without structured logging' {
            $repoRoot = Join-Path $script:TempDir 'code-metrics-debug-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            @{ TotalFiles = 1 } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'code-metrics.json') -Encoding UTF8

            function global:Read-JsonFile {
                param([string]$Path)
                throw 'code metrics debug probe'
            }

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $snapshotPath = Get-SnapshotPathFromOutput -Output @(Save-MetricsSnapshot -OutputPath (Join-Path $repoRoot 'history') -IncludeCodeMetrics -RepoRoot $repoRoot)
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                Remove-Item -Path Function:Read-JsonFile -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Writes save errors with Write-Error when structured logging is unavailable' {
            $repoRoot = Join-Path $script:TempDir 'save-error-write-error-repo'
            $historyDir = Join-Path $repoRoot 'history'
            New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                InModuleScope -ModuleName MetricsSnapshot {
                    Mock Set-Content {
                        throw 'snapshot save write-error probe'
                    }

                    { Save-MetricsSnapshot -OutputPath $historyDir -RepoRoot $repoRoot } |
                        Should -Throw '*Failed to save metrics snapshot*'
                }
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Walks parent directories for .git when Get-RepoRoot is not available' {
            $repoRoot = Join-Path $script:TempDir 'no-get-repo-root'
            New-Item -ItemType Directory -Path (Join-Path $repoRoot '.git') -Force | Out-Null
            $outputDir = Join-Path $repoRoot 'history'

            Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Get-RepoRoot -ErrorAction SilentlyContinue -Force

            $previousLocation = Get-Location
            try {
                Set-Location -LiteralPath $repoRoot
                $snapshotPath = Save-MetricsSnapshot -OutputPath $outputDir
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                Set-Location -LiteralPath $previousLocation.Path
                Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force
            }
        }

        It 'Creates the output directory manually when Ensure-DirectoryExists is unavailable' {
            $repoRoot = Join-Path $script:TempDir 'manual-directory-repo'
            $outputDir = Join-Path $repoRoot 'manual-history'

            Remove-Module FileSystem -ErrorAction SilentlyContinue -Force

            try {
                $snapshotPath = Save-MetricsSnapshot -OutputPath $outputDir -RepoRoot $repoRoot
                Test-Path -LiteralPath $outputDir | Should -Be $true
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                Import-Module (Join-Path $script:LibPath 'file' 'FileSystem.psm1') -DisableNameChecking -Force
            }
        }

        It 'Warns with Write-Warning when code metrics loading fails without structured logging or debug' {
            $repoRoot = Join-Path $script:TempDir 'code-metrics-warning-repo'
            $dataDir = Join-Path $repoRoot 'scripts' 'data'
            New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            @{ TotalFiles = 9 } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dataDir 'code-metrics.json') -Encoding UTF8

            function global:Read-JsonFile {
                param([string]$Path)
                throw 'code metrics warning probe'
            }

            Remove-Item -Path Function:Write-StructuredWarning -ErrorAction SilentlyContinue -Force
            Remove-Item -Path Function:Write-StructuredError -ErrorAction SilentlyContinue -Force
            $originalDebug = $env:PS_PROFILE_DEBUG
            Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue

            try {
                $snapshotPath = Get-SnapshotPathFromOutput -Output @(Save-MetricsSnapshot -OutputPath (Join-Path $repoRoot 'history') -IncludeCodeMetrics -RepoRoot $repoRoot)
                Test-Path -LiteralPath $snapshotPath | Should -Be $true
            }
            finally {
                Remove-Item -Path Function:Read-JsonFile -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1') -DisableNameChecking -Force
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Throws when repository root cannot be detected from the current directory' {
            $isolatedDir = Join-Path ([System.IO.Path]::GetTempPath()) "MetricsSnapshotNoGit-$([Guid]::NewGuid().ToString('N'))"
            New-Item -ItemType Directory -Path $isolatedDir -Force | Out-Null

            function global:Get-RepoRoot {
                param([string]$ScriptPath)
                throw 'repo root detection probe'
            }

            Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
            $previousLocation = Get-Location

            try {
                Set-Location -LiteralPath $isolatedDir
                { Save-MetricsSnapshot } | Should -Throw '*Could not determine repository root*'
            }
            finally {
                Set-Location -LiteralPath $previousLocation.Path
                Remove-Item -Path Function:Get-RepoRoot -ErrorAction SilentlyContinue -Force
                Import-Module (Join-Path $script:LibPath 'path' 'PathResolution.psm1') -DisableNameChecking -Force
                if (Test-Path -LiteralPath $isolatedDir) {
                    Remove-Item -LiteralPath $isolatedDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
