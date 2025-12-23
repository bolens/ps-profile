. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    
    # Import dependencies
    $testCoveragePath = Join-Path $script:LibPath 'code-analysis' 'TestCoverage.psm1'
    if (Test-Path $testCoveragePath) {
        Import-Module $testCoveragePath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    $script:CodeQualityScorePath = Join-Path $script:LibPath 'metrics' 'CodeQualityScore.psm1'
    Import-Module $script:CodeQualityScorePath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module CodeQualityScore -ErrorAction SilentlyContinue -Force
    Remove-Module TestCoverage -ErrorAction SilentlyContinue -Force
}

Describe 'CodeQualityScore Module Functions' {
    Context 'Get-CodeQualityScore' {
        It 'Calculates quality score for valid metrics' {
            $metrics = [PSCustomObject]@{
                TotalLines               = 1000
                TotalFunctions           = 50
                TotalComplexity          = 200
                DuplicateFunctions       = 0
                AverageLinesPerFile      = 50
                AverageComplexityPerFile = 10
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result | Should -Not -BeNullOrEmpty
            $result.Score | Should -BeGreaterOrEqual 0
            $result.Score | Should -BeLessOrEqual 100
        }

        It 'Returns Score property' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 50
                TotalComplexity    = 200
                DuplicateFunctions = 0
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result.Score | Should -Not -BeNullOrEmpty
            $result.Score | Should -BeOfType [double]
        }

        It 'Includes test coverage in score calculation' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 50
                TotalComplexity    = 200
                DuplicateFunctions = 0
            }
            
            $coverage = [PSCustomObject]@{
                CoveragePercent = 80
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics -TestCoverage $coverage
            $result | Should -Not -BeNullOrEmpty
            $result.Score | Should -BeGreaterOrEqual 0
        }

        It 'Handles missing test coverage' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 50
                TotalComplexity    = 200
                DuplicateFunctions = 0
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result | Should -Not -BeNullOrEmpty
            $result.Score | Should -BeGreaterOrEqual 0
        }

        It 'Accepts custom weights' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 50
                TotalComplexity    = 200
                DuplicateFunctions = 0
            }
            
            $weights = @{
                Complexity      = 0.5
                Duplicates      = 0.3
                Coverage        = 0.2
                FileSize        = 0.0
                FunctionDensity = 0.0
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics -Weights $weights
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Handles hashtable input for CodeMetrics' {
            $metrics = @{
                TotalLines         = 1000
                TotalFunctions     = 50
                TotalComplexity    = 200
                DuplicateFunctions = 0
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns component scores' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 50
                TotalComplexity    = 200
                DuplicateFunctions = 0
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result.PSObject.Properties.Name | Should -Contain 'Score'
            $result.PSObject.Properties.Name | Should -Contain 'ComponentScores'
            $result.ComponentScores | Should -Not -BeNull
            $result.ComponentScores.PSObject.Properties.Name | Should -Contain 'Complexity'
        }

        It 'Handles high complexity metrics' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 10000
                TotalFunctions     = 500
                TotalComplexity    = 5000
                DuplicateFunctions = 10
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result.Score | Should -BeGreaterOrEqual 0
            $result.Score | Should -BeLessOrEqual 100
        }

        It 'Handles zero values' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 0
                TotalFunctions     = 0
                TotalComplexity    = 0
                DuplicateFunctions = 0
            }
            
            $result = Get-CodeQualityScore -CodeMetrics $metrics
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

