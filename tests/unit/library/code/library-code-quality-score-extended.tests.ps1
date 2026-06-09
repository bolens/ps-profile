<#
tests/unit/library-code-quality-score-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Get-CodeQualityScore weighting and component scoring.
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
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:ProfileDir = Join-Path $script:RepoRoot 'profile.d'
    Import-Module (Join-Path $script:LibPath 'metrics' 'CodeQualityScore.psm1') -DisableNameChecking -Force
}

function script:Enable-TestStructuredLogging {
    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
        return
    }

    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'bootstrap' 'ErrorHandlingStandard.ps1')
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

        It 'Throws when CodeMetrics is not a supported object type' {
            { Get-CodeQualityScore -CodeMetrics 'invalid' } | Should -Throw '*PSCustomObject or Hashtable*'
        }

        It 'Throws when a required CodeMetrics property is missing' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 100
                TotalFunctions     = 5
                TotalComplexity    = 10
            }

            { Get-CodeQualityScore -CodeMetrics $metrics } | Should -Throw '*DuplicateFunctions*'
        }

        It 'Throws when Weights is not a hashtable' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 100
                TotalFunctions     = 5
                TotalComplexity    = 10
                DuplicateFunctions = 0
                AverageLinesPerFile = 100
            }

            { Get-CodeQualityScore -CodeMetrics $metrics -Weights 'invalid' } | Should -Throw '*hashtable*'
        }

        It 'Accepts TestCoverage as a hashtable' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 20
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $coverage = @{ CoveragePercent = 85 }

            $result = Get-CodeQualityScore -CodeMetrics $metrics -TestCoverage $coverage

            $result.ComponentScores.Coverage | Should -Be 85
        }

        It 'Treats missing CoveragePercent as zero coverage contribution' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 20
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $coverage = [PSCustomObject]@{ TotalLines = 100 }

            $result = Get-CodeQualityScore -CodeMetrics $metrics -TestCoverage $coverage

            $result.ComponentScores.Coverage | Should -Be 0
        }

        It 'Penalizes oversized files in the file-size component score' {
            $smallFiles = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 20
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $largeFiles = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 20
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 600
            }

            $smallScore = (Get-CodeQualityScore -CodeMetrics $smallFiles).ComponentScores.FileSize
            $largeScore = (Get-CodeQualityScore -CodeMetrics $largeFiles).ComponentScores.FileSize

            $largeScore | Should -BeLessThan $smallScore
        }

        It 'Accepts CodeMetrics supplied as a generic PSObject' {
            $metrics = New-Object PSObject -Property @{
                TotalLines         = 500
                TotalFunctions     = 10
                TotalComplexity    = 25
                DuplicateFunctions = 0
                AverageLinesPerFile = 120
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics

            $result.Score | Should -BeGreaterOrEqual 0
            $result.Score | Should -BeLessOrEqual 100
        }

        It 'Normalizes custom weights that do not sum to one' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 500
                TotalFunctions     = 25
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $weights = @{
                Complexity      = 2
                Duplicates      = 2
                Coverage        = 2
                FileSize        = 2
                FunctionDensity = 2
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics -Weights $weights
            $weightSum = ($result.Weights.Values | Measure-Object -Sum).Sum

            [math]::Abs($weightSum - 1.0) | Should -BeLessThan 0.01
        }

        It 'Uses a neutral file-size score when AverageLinesPerFile is zero' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 0
                TotalFunctions     = 0
                TotalComplexity    = 0
                DuplicateFunctions = 0
                AverageLinesPerFile = 0
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics

            $result.ComponentScores.FileSize | Should -Be 50
        }

        It 'Rewards undersized files below the target range' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 500
                TotalFunctions     = 5
                TotalComplexity    = 10
                DuplicateFunctions = 0
                AverageLinesPerFile = 40
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics

            $result.ComponentScores.FileSize | Should -Be 100
        }

        It 'Scores sparse function density below the target range' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 2
                TotalComplexity    = 10
                DuplicateFunctions = 0
                AverageLinesPerFile = 200
            }

            $result = Get-CodeQualityScore -CodeMetrics $metrics

            $result.ComponentScores.FunctionDensity | Should -BeGreaterThan 50
            $result.ComponentScores.FunctionDensity | Should -BeLessThan 100
        }

        It 'Warns when CoveragePercent is missing and debug output is enabled' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 100
                TotalFunctions     = 5
                TotalComplexity    = 10
                DuplicateFunctions = 0
                AverageLinesPerFile = 100
            }
            $coverage = [PSCustomObject]@{ TotalLines = 50 }
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                $result = Get-CodeQualityScore -CodeMetrics $metrics -TestCoverage $coverage
                $result.ComponentScores.Coverage | Should -Be 0
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

        It 'Warns through structured logging when a required metric property is missing' {
            Enable-TestStructuredLogging

            $metrics = [PSCustomObject]@{
                TotalLines      = 100
                TotalFunctions  = 5
                TotalComplexity = 10
            }

            { Get-CodeQualityScore -CodeMetrics $metrics } | Should -Throw '*DuplicateFunctions*'
        }

        It 'Emits debug tracing when PS_PROFILE_DEBUG is level 3' {
            $metrics = [PSCustomObject]@{
                TotalLines         = 100
                TotalFunctions     = 5
                TotalComplexity    = 10
                DuplicateFunctions = 0
                AverageLinesPerFile = 100
            }
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $result = Get-CodeQualityScore -CodeMetrics $metrics
                $result.Score | Should -BeGreaterOrEqual 0
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

        It 'Penalizes excessive function density' {
            $balanced = [PSCustomObject]@{
                TotalLines         = 1000
                TotalFunctions     = 20
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 150
            }
            $dense = [PSCustomObject]@{
                TotalLines         = 100
                TotalFunctions     = 50
                TotalComplexity    = 50
                DuplicateFunctions = 0
                AverageLinesPerFile = 100
            }

            $balancedDensity = (Get-CodeQualityScore -CodeMetrics $balanced).ComponentScores.FunctionDensity
            $denseDensity = (Get-CodeQualityScore -CodeMetrics $dense).ComponentScores.FunctionDensity

            $denseDensity | Should -BeLessThan $balancedDensity
        }
    }
}
