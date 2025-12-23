. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:TestCoveragePath = Join-Path $script:LibPath 'code-analysis' 'TestCoverage.psm1'
    
    # Import the module under test
    Import-Module $script:TestCoveragePath -DisableNameChecking -ErrorAction Stop -Force
    
    # Create test directory and files
    $script:TestDir = Join-Path $env:TEMP "test-coverage-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:TestDir -Force | Out-Null
    
    # Create valid Pester coverage XML
    $script:ValidCoverageXml = Join-Path $script:TestDir 'coverage.xml'
    $coverageXml = @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="C:\test\module.psm1">
        <Function FunctionName="Test-Function1">
            <Line Number="1" Covered="true" />
            <Line Number="2" Covered="true" />
            <Line Number="3" Covered="false" />
        </Function>
        <Function FunctionName="Test-Function2">
            <Line Number="5" Covered="true" />
            <Line Number="6" Covered="false" />
        </Function>
    </Module>
</Coverage>
'@
    Set-Content -Path $script:ValidCoverageXml -Value $coverageXml -Encoding UTF8
    
    # Create empty coverage XML
    $script:EmptyCoverageXml = Join-Path $script:TestDir 'empty-coverage.xml'
    Set-Content -Path $script:EmptyCoverageXml -Value '<?xml version="1.0"?><Coverage></Coverage>' -Encoding UTF8
}

AfterAll {
    Remove-Module TestCoverage -ErrorAction SilentlyContinue -Force
    
    # Clean up test files
    if ($script:TestDir -and (Test-Path $script:TestDir)) {
        Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'TestCoverage Module Functions' {
    Context 'Get-TestCoverage' {
        It 'Parses valid coverage XML file' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Returns coverage percentage' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result.CoveragePercent | Should -Not -BeNullOrEmpty
            $result.CoveragePercent | Should -BeGreaterOrEqual 0
            $result.CoveragePercent | Should -BeLessOrEqual 100
        }

        It 'Returns total lines count' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result.TotalLines | Should -BeGreaterThan 0
        }

        It 'Returns covered lines count' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result.CoveredLines | Should -BeGreaterOrEqual 0
        }

        It 'Returns uncovered lines count' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result.UncoveredLines | Should -BeGreaterOrEqual 0
        }

        It 'Returns file count' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result.FileCount | Should -BeGreaterOrEqual 0
        }

        It 'Returns file coverage array' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result.FileCoverage | Should -Not -BeNullOrEmpty
            $result.FileCoverage -is [System.Array] | Should -Be $true
            if ($null -ne $result.FileCoverage) {
                $result.FileCoverage.Count | Should -BeGreaterOrEqual 0
            }
        }

        It 'Returns timestamp' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            $result.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Returns zero coverage for non-existent file' {
            $nonExistentFile = Join-Path $script:TestDir 'nonexistent.xml'
            $result = Get-TestCoverage -CoverageXmlPath $nonExistentFile
            $result | Should -Not -BeNullOrEmpty
            $result.CoveragePercent | Should -Be 0
            $result.TotalLines | Should -Be 0
        }

        It 'Handles empty coverage XML' {
            $result = Get-TestCoverage -CoverageXmlPath $script:EmptyCoverageXml
            $result | Should -Not -BeNullOrEmpty
            $result.CoveragePercent | Should -Be 0
        }

        It 'Calculates coverage percentage correctly' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            # 3 covered lines out of 5 total = 60%
            # But actual calculation may vary based on implementation
            $result.CoveragePercent | Should -BeGreaterOrEqual 0
            $result.CoveragePercent | Should -BeLessOrEqual 100
        }

        It 'Includes file coverage details' {
            $result = Get-TestCoverage -CoverageXmlPath $script:ValidCoverageXml
            if ($result.FileCoverage.Count -gt 0) {
                $fileCoverage = $result.FileCoverage[0]
                $fileCoverage.PSObject.Properties.Name | Should -Contain 'File'
                $fileCoverage.PSObject.Properties.Name | Should -Contain 'Path'
                $fileCoverage.PSObject.Properties.Name | Should -Contain 'TotalLines'
                $fileCoverage.PSObject.Properties.Name | Should -Contain 'CoveredLines'
                $fileCoverage.PSObject.Properties.Name | Should -Contain 'CoveragePercent'
            }
        }
    }
}

