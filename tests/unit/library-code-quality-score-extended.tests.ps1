<#
tests/unit/library-code-quality-score-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-CodeQualityScore weighting and component scoring.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'metrics' 'CodeQualityScore.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module CodeQualityScore -ErrorAction SilentlyContinue -Force
}

Describe 'CodeQualityScore extended scenarios' {
    Context 'Get-CodeQualityScore' {
        It 'Produces a higher score for clean metrics with strong coverage' {
            $metrics = [PSCustomObject]@{
                TotalLines               = 1000
                TotalFunctions           = 20
                TotalComplexity          = 50
                DuplicateFunctions       = 0
                AverageLinesPerFile      = 150
                AverageComplexityPerFile = 5
            }
            $coverage = [PSCustomObject]@{ CoveragePercent = 95 }

            $result = Get-CodeQualityScore -CodeMetrics $metrics -TestCoverage $coverage

            $result.Score | Should -BeGreaterThan 70
        }

        It 'Lowers the score when duplicate functions are present' {
            $clean = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 100
                TotalComplexity    = 100
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $duplicated = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 100
                TotalComplexity    = 100
                DuplicateFunctions = 40
                AverageLinesPerFile = 150
            }

            $cleanScore = (Get-CodeQualityScore -CodeMetrics $clean).Score
            $duplicateScore = (Get-CodeQualityScore -CodeMetrics $duplicated).Score

            $duplicateScore | Should -BeLessThan $cleanScore
        }

        It 'Returns weights that sum to one on the result object' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 500
                TotalFunctions     = 25
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $weights = @{
                Complexity      = 0.2
                Duplicates      = 0.2
                Coverage        = 0.2
                FileSize        = 0.2
                FunctionDensity = 0.2
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics -Weights $weights
            $weightSum = ($result.Weights.Values | Measure-Object -Sum).Sum

            [math]::Abs($weightSum - 1.0) | Should -BeLessThan 0.01
        }

        It 'Falls back to default weights when custom weights sum to zero' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 500
                TotalFunctions     = 25
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $weights = @{
                Complexity      = 0
                Duplicates      = 0
                Coverage        = 0
                FileSize        = 0
                FunctionDensity = 0
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics -Weights $weights

            $result.Weights.Complexity | Should -Be 0.25
            $result.Weights.Coverage | Should -Be 0.30
        }

        It 'Includes a UTC timestamp on every result' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 100
                TotalFunctions     = 5
                TotalComplexity    = 10
                DuplicateFunctions = 0
                AverageLinesPerFile = 100
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics

            $result.Timestamp | Should -Not -BeNullOrEmpty
            { [DateTime]::Parse($result.Timestamp) } | Should -Not -Throw
        }
    }
}
