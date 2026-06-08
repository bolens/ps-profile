<#
tests/unit/library-codeanalysis-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for code analysis helper edge cases.
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
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'file' 'FileSystem.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'code-analysis' 'AstParsing.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'file' 'FileContent.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'utilities' 'Collections.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'code-analysis' 'TestCoverage.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'metrics' 'CodeQualityScore.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'utilities' 'StringSimilarity.psm1') -DisableNameChecking -ErrorAction Stop -Global
    Import-Module (Join-Path $libPath 'code-analysis' 'CodeSimilarityDetection.psm1') -DisableNameChecking -ErrorAction Stop -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'CodeAnalysisExtended'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'CodeAnalysis extended scenarios' {
    Context 'Get-TestCoverage' {
        It 'Returns zero coverage for empty coverage documents' {
            $coverageFile = Join-Path $script:TempDir 'empty-coverage.xml'
            Set-Content -LiteralPath $coverageFile -Value '<?xml version="1.0"?><Coverage></Coverage>' -Encoding UTF8

            $result = Get-TestCoverage -CoverageXmlPath $coverageFile -WarningAction SilentlyContinue
            $result.CoveragePercent | Should -Be 0
            $result.TotalLines | Should -Be 0
        }

        It 'Treats invalid XML as zero coverage' {
            $coverageFile = Join-Path $script:TempDir 'invalid-coverage.xml'
            Set-Content -LiteralPath $coverageFile -Value '<Coverage><Module>' -Encoding UTF8

            $result = Get-TestCoverage -CoverageXmlPath $coverageFile -WarningAction SilentlyContinue
            $result.CoveragePercent | Should -Be 0
        }
    }

    Context 'Get-CodeQualityScore' {
        It 'Penalizes duplicate function counts in the score' {
            $cleanMetrics = [PSCustomObject]@{
                TotalLines               = 1000
                TotalFunctions           = 50
                TotalComplexity          = 200
                DuplicateFunctions       = 0
                AverageLinesPerFile      = 50
                AverageComplexityPerFile = 10
            }
            $duplicateMetrics = [PSCustomObject]@{
                TotalLines               = 1000
                TotalFunctions           = 50
                TotalComplexity          = 200
                DuplicateFunctions       = 25
                AverageLinesPerFile      = 50
                AverageComplexityPerFile = 10
            }

            $cleanScore = (Get-CodeQualityScore -CodeMetrics $cleanMetrics).Score
            $duplicateScore = (Get-CodeQualityScore -CodeMetrics $duplicateMetrics).Score

            $duplicateScore | Should -BeLessThan $cleanScore
        }
    }

    Context 'Get-CodeSimilarity' {
        It 'Returns no matches for an empty search directory' {
            $emptyDir = Join-Path $script:TempDir 'empty-similarity'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

            $result = Get-CodeSimilarity -Path $emptyDir -MinSimilarity 0.8
            @($result).Count | Should -Be 0
        }
    }
}
