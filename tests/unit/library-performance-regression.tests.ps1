. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import JsonUtilities first (dependency)
    $jsonUtilitiesPath = Join-Path $script:LibPath 'utilities' 'JsonUtilities.psm1'
    if (Test-Path $jsonUtilitiesPath) {
        Import-Module $jsonUtilitiesPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    $script:PerformanceRegressionPath = Join-Path $script:LibPath 'performance' 'PerformanceRegression.psm1'
    Import-Module $script:PerformanceRegressionPath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory and files
    $script:TestDir = Join-Path $env:TEMP "test-performance-regression-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    # Create baseline file
    $script:BaselineFile = Join-Path $script:TestDir 'baseline.json'
    $baselineData = @{
        DurationMs = 1000
        MemoryMB   = 50
    }
    $baselineData | ConvertTo-Json | Set-Content -Path $script:BaselineFile -Encoding UTF8
}

AfterAll {
    Remove-Module PerformanceRegression -ErrorAction SilentlyContinue -Force
    Remove-Module JsonUtilities -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PerformanceRegression Module Functions' {
    Context 'Test-PerformanceRegression' {
        It 'Returns no regression when metrics are better' {
            $currentMetrics = @{
                DurationMs = 500
                MemoryMB   = 40
            }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile
            $result | Should -Not -BeNullOrEmpty
            $result.RegressionDetected | Should -Be $false
        }

        It 'Detects regression when metrics exceed threshold' {
            $currentMetrics = @{
                DurationMs = 2000  # 2x baseline (exceeds 1.5x threshold)
                MemoryMB   = 50
            }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile
            $result | Should -Not -BeNullOrEmpty
            $result.RegressionDetected | Should -Be $true
        }

        It 'Accepts PSCustomObject for CurrentMetrics' {
            $currentMetrics = [PSCustomObject]@{
                DurationMs = 1000
                MemoryMB   = 50
            }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Throws error when CurrentMetrics is null' {
            { Test-PerformanceRegression -CurrentMetrics $null -BaselineFile $script:BaselineFile } | Should -Throw "*null*"
        }

        It 'Returns no regression when baseline file not found' {
            $nonExistentBaseline = Join-Path $script:TestDir 'nonexistent.json'
            $currentMetrics = @{ DurationMs = 2000 }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $nonExistentBaseline
            $result | Should -Not -BeNullOrEmpty
            $result.RegressionDetected | Should -Be $false
            $result.Message | Should -Match 'No baseline found'
        }

        It 'Accepts custom threshold' {
            $currentMetrics = @{
                DurationMs = 1200  # 1.2x baseline (below default 1.5x threshold)
            }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile -Threshold 1.1
            $result | Should -Not -BeNullOrEmpty
            # With threshold 1.1, 1.2x should be a regression
            $result.RegressionDetected | Should -Be $true
        }

        It 'Returns Ratio property' {
            $currentMetrics = @{
                DurationMs = 1500
            }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile
            $result.Ratio | Should -Not -BeNullOrEmpty
            $result.Ratio | Should -BeGreaterThan 0
        }

        It 'Returns Details array' {
            $currentMetrics = @{
                DurationMs = 2000
            }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile
            $result.Details | Should -Not -BeNullOrEmpty
            $result.Details -is [System.Array] | Should -Be $true
        }

        It 'Accepts OperationName parameter' {
            $currentMetrics = @{ DurationMs = 1000 }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile -OperationName 'TestOperation'
            $result.OperationName | Should -Be 'TestOperation'
        }

        It 'Handles empty CurrentMetrics gracefully' {
            $currentMetrics = @{}
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Throws error for invalid CurrentMetrics type' {
            { Test-PerformanceRegression -CurrentMetrics "invalid" -BaselineFile $script:BaselineFile } | Should -Throw "*Hashtable or PSCustomObject*"
        }

        It 'Compares multiple metrics' {
            $currentMetrics = @{
                DurationMs = 2000
                MemoryMB   = 100
            }
            
            $result = Test-PerformanceRegression -CurrentMetrics $currentMetrics -BaselineFile $script:BaselineFile
            $result | Should -Not -BeNullOrEmpty
            # Should detect regression in at least one metric
            if ($result.Details.Count -gt 0) {
                $result.RegressionDetected | Should -Be $true
            }
        }
    }
}

