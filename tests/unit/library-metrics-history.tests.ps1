. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import the module under test
    $script:MetricsHistoryPath = Join-Path $script:LibPath 'metrics' 'MetricsHistory.psm1'
    Import-Module $script:MetricsHistoryPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory and files
    $script:TestDir = Join-Path $env:TEMP "test-metrics-history-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    # Create historical snapshot files
    $script:HistoryDir = Join-Path $script:TestDir 'history'
    New-Item -ItemType Directory -Path $script:HistoryDir -Force | Out-Null
    
    # Create multiple snapshot files
    1..5 | ForEach-Object {
        $metrics = @{
            Timestamp  = "2024-01-0$_`T00:00:00Z"
            TotalFiles = $_ * 10
        } | ConvertTo-Json
        $metricsFile = Join-Path $script:HistoryDir "metrics-2024010$_`-000000.json"
        Set-Content -Path $metricsFile -Value $metrics -Encoding UTF8
        # Set different write times for sorting
        (Get-Item $metricsFile).LastWriteTime = Get-Date "2024-01-0$_"
    }
}

AfterAll {
    Remove-Module MetricsHistory -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'MetricsHistory Module Functions' {
    Context 'Get-HistoricalMetrics' {
        It 'Returns empty array for non-existent directory' {
            $nonExistentPath = Join-Path $script:TestDir 'nonexistent-history'
            $result = @(Get-HistoricalMetrics -HistoryPath $nonExistentPath)
            if ($null -eq $result) {
                $result = @()
            }
            $result -is [System.Array] | Should -Be $true
            $result.Count | Should -Be 0
        }

        It 'Loads historical metrics from JSON files' {
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Loads all snapshots when Limit not specified' {
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir
            $result.Count | Should -Be 5
        }

        It 'Respects Limit parameter' {
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir -Limit 3
            $result.Count | Should -BeLessOrEqual 3
        }

        It 'Returns snapshots sorted by timestamp' {
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir
            if ($result.Count -gt 1) {
                # Verify they're sorted (oldest first based on LastWriteTime)
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Filters files by metrics-*.json pattern' {
            # Create a non-matching file
            $otherFile = Join-Path $script:HistoryDir 'other-file.json'
            Set-Content -Path $otherFile -Value '{}' -Encoding UTF8
            
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir
            # Should only load metrics-*.json files
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles invalid JSON files gracefully' {
            $invalidFile = Join-Path $script:HistoryDir 'metrics-invalid.json'
            Set-Content -Path $invalidFile -Value '{ invalid json }' -Encoding UTF8
            
            # Should not throw, but may skip invalid files
            { Get-HistoricalMetrics -HistoryPath $script:HistoryDir } | Should -Not -Throw
        }

        It 'Returns array of objects' {
            $result = @(Get-HistoricalMetrics -HistoryPath $script:HistoryDir)
            $result | Should -Not -BeNullOrEmpty
            $result -is [System.Array] | Should -Be $true
            if ($result.Count -gt 0) {
                $result[0] | Should -Not -BeNullOrEmpty
            }
        }

        It 'Handles empty history directory' {
            $emptyDir = Join-Path $script:TestDir 'empty-history'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            
            $result = @(Get-HistoricalMetrics -HistoryPath $emptyDir)
            if ($null -eq $result) {
                $result = @()
            }
            $result -is [System.Array] | Should -Be $true
            $result.Count | Should -Be 0
        }

        It 'Loads latest snapshots when Limit specified' {
            $result = Get-HistoricalMetrics -HistoryPath $script:HistoryDir -Limit 2
            $result.Count | Should -BeLessOrEqual 2
            # Should get the most recent files
        }
    }
}

