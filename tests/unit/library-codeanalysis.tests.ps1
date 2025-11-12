. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'CodeAnalysis Module Functions' {
    BeforeAll {
        Import-TestCommonModule | Out-Null
        $script:TestTempDir = New-TestTempDirectory -Prefix 'CodeAnalysisTests'
    }

    AfterAll {
        if ($script:TestTempDir -and (Test-Path $script:TestTempDir)) {
            Remove-Item -Path $script:TestTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-TestCoverage' {
        It 'Handles missing coverage file gracefully' {
            $nonExistentFile = Join-Path $script:TestTempDir 'nonexistent-coverage.xml'
            $result = Get-TestCoverage -CoverageXmlPath $nonExistentFile -WarningAction SilentlyContinue
            $result.CoveragePercent | Should -Be 0
            $result.TotalLines | Should -Be 0
            $result.FileCount | Should -Be 0
        }

        It 'Parses valid coverage XML structure' {
            $coverageXml = @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="test.ps1">
        <Function FunctionName="Test-Function">
            <Line Number="1" Covered="true" />
            <Line Number="2" Covered="true" />
            <Line Number="3" Covered="false" />
        </Function>
    </Module>
</Coverage>
'@
            $coverageFile = Join-Path $script:TestTempDir 'coverage.xml'
            $coverageXml | Set-Content -Path $coverageFile -Encoding UTF8

            $result = Get-TestCoverage -CoverageXmlPath $coverageFile
            $result.TotalLines | Should -Be 3
            $result.CoveredLines | Should -Be 2
            $result.UncoveredLines | Should -Be 1
            $result.CoveragePercent | Should -BeGreaterThan 0
            $result.FileCount | Should -BeGreaterThan 0
        }
    }

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
    }

    Context 'Get-CodeSimilarity' {
        It 'Detects similar code patterns' {
            $testDir = Join-Path $script:TestTempDir 'similarity-test'
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null

            $script1 = @'
function Test-Function {
    param($Name)
    Write-Output "Hello $Name"
}
'@
            $script2 = @'
function Test-Function {
    param($Name)
    Write-Output "Hello $Name"
}
'@

            $script1 | Set-Content -Path (Join-Path $testDir 'script1.ps1') -Encoding UTF8
            $script2 | Set-Content -Path (Join-Path $testDir 'script2.ps1') -Encoding UTF8

            $result = Get-CodeSimilarity -Path $testDir -MinSimilarity 0.5
            $result | Should -Not -BeNullOrEmpty
            ($result -is [System.Array]) | Should -BeTrue
        }
    }

    Context 'Get-StringSimilarity' {
        It 'Calculates similarity between identical strings' {
            $result = Get-StringSimilarity -String1 'hello world' -String2 'hello world'
            $result | Should -BeGreaterThan 0.9
        }

        It 'Calculates similarity between different strings' {
            $result = Get-StringSimilarity -String1 'hello' -String2 'world'
            $result | Should -BeLessThan 0.5
        }
    }
}
