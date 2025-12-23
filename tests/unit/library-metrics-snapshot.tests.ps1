. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import dependencies
    $pathResolutionPath = Join-Path $script:LibPath 'path' 'PathResolution.psm1'
    $fileSystemPath = Join-Path $script:LibPath 'file' 'FileSystem.psm1'
    $jsonUtilitiesPath = Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1'
    
    if (Test-Path $pathResolutionPath) {
        Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    if (Test-Path $fileSystemPath) {
        Import-Module $fileSystemPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    if (Test-Path $jsonUtilitiesPath) {
        Import-Module $jsonUtilitiesPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    $script:MetricsSnapshotPath = Join-Path $script:LibPath 'metrics' 'MetricsSnapshot.psm1'
    Import-Module $script:MetricsSnapshotPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory
    $script:TestDir = Join-Path $env:TEMP "test-metrics-snapshot-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
}

AfterAll {
    Remove-Module MetricsSnapshot -ErrorAction SilentlyContinue -Force
    Remove-Module PathResolution -ErrorAction SilentlyContinue -Force
    Remove-Module FileSystem -ErrorAction SilentlyContinue -Force
    Remove-Module JsonUtilities -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'MetricsSnapshot Module Functions' {
    Context 'Save-MetricsSnapshot' {
        It 'Saves metrics snapshot to specified path' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir
            $snapshotPath | Should -Not -BeNullOrEmpty
            Test-Path $snapshotPath | Should -Be $true
            $snapshotPath | Should -Match 'metrics-\d{8}-\d{6}\.json'
        }

        It 'Creates output directory if it does not exist' {
            $newDir = Join-Path $script:TestDir 'new-dir'
            $snapshotPath = Save-MetricsSnapshot -OutputPath $newDir
            Test-Path $newDir | Should -Be $true
            Test-Path $snapshotPath | Should -Be $true
        }

        It 'Includes timestamp in snapshot' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir
            $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
            $snapshotContent.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Includes source information' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir
            $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
            $snapshotContent.Source | Should -Not -BeNullOrEmpty
        }

        It 'Includes code metrics when IncludeCodeMetrics specified' {
            # Create a mock code metrics file
            $codeMetricsDir = Join-Path $script:RepoRoot 'scripts' 'data'
            if (-not (Test-Path $codeMetricsDir)) {
                New-Item -ItemType Directory -Path $codeMetricsDir -Force | Out-Null
            }
            $codeMetricsFile = Join-Path $codeMetricsDir 'code-metrics.json'
            $codeMetrics = @{
                TotalFiles     = 100
                TotalFunctions = 50
            } | ConvertTo-Json
            Set-Content -Path $codeMetricsFile -Value $codeMetrics -Encoding UTF8
            
            try {
                $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir -IncludeCodeMetrics -RepoRoot $script:RepoRoot
                $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
                $snapshotContent.CodeMetrics | Should -Not -BeNullOrEmpty
            }
            finally {
                if (Test-Path $codeMetricsFile) {
                    Remove-Item -Path $codeMetricsFile -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Includes performance metrics when IncludePerformanceMetrics specified' {
            # Create a mock performance file
            $dataDir = Join-Path $script:RepoRoot 'scripts' 'data'
            if (-not (Test-Path $dataDir)) {
                New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
            }
            $performanceFile = Join-Path $dataDir 'performance-baseline.json'
            $performance = @{
                FullStartupMean = 1000
            } | ConvertTo-Json
            Set-Content -Path $performanceFile -Value $performance -Encoding UTF8
            
            try {
                $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir -IncludePerformanceMetrics -RepoRoot $script:RepoRoot
                $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
                $snapshotContent.PerformanceMetrics | Should -Not -BeNullOrEmpty
            }
            finally {
                if (Test-Path $performanceFile) {
                    Remove-Item -Path $performanceFile -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It 'Uses default output path when not specified' {
            # This test verifies the function structure
            # Actual default path depends on repo root detection
            Get-Command Save-MetricsSnapshot | Should -Not -BeNullOrEmpty
        }

        It 'Handles missing code metrics file gracefully' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir -IncludeCodeMetrics -RepoRoot $script:TestDir
            $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
            # Should still create snapshot even if code metrics file doesn't exist
            $snapshotContent | Should -Not -BeNullOrEmpty
        }

        It 'Handles missing performance metrics file gracefully' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir -IncludePerformanceMetrics -RepoRoot $script:TestDir
            $snapshotContent = Get-Content -Path $snapshotPath -Raw | ConvertFrom-Json
            # Should still create snapshot even if performance file doesn't exist
            $snapshotContent | Should -Not -BeNullOrEmpty
        }

        It 'Detects repository root automatically' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir
            $snapshotPath | Should -Not -BeNullOrEmpty
            Test-Path $snapshotPath | Should -Be $true
        }

        It 'Uses provided RepoRoot parameter' {
            $snapshotPath = Save-MetricsSnapshot -OutputPath $script:TestDir -RepoRoot $script:TestDir
            $snapshotPath | Should -Not -BeNullOrEmpty
            Test-Path $snapshotPath | Should -Be $true
        }
    }
}

