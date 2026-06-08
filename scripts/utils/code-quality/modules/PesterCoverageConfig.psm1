<#
scripts/utils/code-quality/modules/PesterCoverageConfig.psm1

.SYNOPSIS
    Pester code coverage configuration utilities.

.DESCRIPTION
    Provides functions for configuring Pester code coverage settings.
#>

<#
.SYNOPSIS
    Configures code coverage for Pester.

.DESCRIPTION
    Enables coverage collection, maps test paths to source files when possible,
    and configures output format, report path, and minimum coverage targets.

.PARAMETER Config
    Pester configuration object to update.

.PARAMETER Coverage
    Enables full code coverage collection.

.PARAMETER ShowCoverageSummary
    Enables coverage summary output without full XML reporting.

.PARAMETER CodeCoverageOutputFormat
    Coverage report format (for example JaCoCo or Cobertura).

.PARAMETER CoverageReportPath
    Directory where coverage reports should be written.

.PARAMETER MinimumCoverage
    Minimum acceptable coverage percentage threshold.

.PARAMETER ProfileDir
    Profile source root used when no test-to-source mapping is found.

.PARAMETER RepoRoot
    Repository root used for default coverage output paths.

.PARAMETER TestPaths
    Test files used to infer targeted source coverage paths.

.EXAMPLE
    Set-PesterCodeCoverage -Config $config -Coverage -RepoRoot $repoRoot -ProfileDir $profileDir
#>
function Set-PesterCodeCoverage {
    param(
        [PesterConfiguration]$Config,
        [switch]$Coverage,
        [switch]$ShowCoverageSummary,
        [string]$CodeCoverageOutputFormat,
        [string]$CoverageReportPath,
        [int]$MinimumCoverage,
        [string]$ProfileDir,
        [string]$RepoRoot,
        [string[]]$TestPaths
    )

    if ($Coverage -or $ShowCoverageSummary) {
        $Config.CodeCoverage.Enabled = $true
        
        # If specific test paths are provided, try to map them to source files for targeted coverage
        # Otherwise, use the entire ProfileDir (default behavior)
        $coveragePaths = @()
        
        if ($TestPaths -and $TestPaths.Count -gt 0) {
            # Try to map test files to source files (similar to analyze-coverage.ps1)
            $testToSourceMappings = @{
                'alias'                      = @('FunctionRegistration.ps1')
                'profile-tool-wrapper'       = @('FunctionRegistration.ps1')
                'helper-functions' = @('FunctionRegistration.ps1', 'CommandCache.ps1', 'ModulePathCache.ps1')
                'load-idempotency' = @('FunctionRegistration.ps1')
                'load-performance' = @('FunctionRegistration.ps1', 'CommandCache.ps1')
                'scoping'          = @('FunctionRegistration.ps1')
                'library-command'            = @('CommandCache.ps1')
                'profile-module-loading'     = @('ModuleLoading.ps1')
            }
            
            foreach ($testPath in $TestPaths) {
                $testFileName = Split-Path $testPath -Leaf
                $testBaseName = [System.IO.Path]::GetFileNameWithoutExtension($testFileName) -replace '\.tests$', ''
                
                # Check for direct mappings
                $mappedSources = $null
                foreach ($key in $testToSourceMappings.Keys) {
                    if ($testBaseName -like "*$key*") {
                        $mappedSources = $testToSourceMappings[$key]
                        break
                    }
                }
                
                if ($mappedSources) {
                    foreach ($sourceName in $mappedSources) {
                        $sourceFile = Get-ChildItem -Path $ProfileDir -Filter $sourceName -Recurse -File -ErrorAction SilentlyContinue | 
                        Where-Object { $_.Name -notlike '*.tests.ps1' } | 
                        Select-Object -First 1
                        if ($sourceFile) {
                            $coveragePaths += $sourceFile.FullName
                        }
                    }
                }
            }
            
            # If we found specific source files, use them; otherwise fall back to ProfileDir
            if ($coveragePaths.Count -gt 0) {
                $Config.CodeCoverage.Path = $coveragePaths | Select-Object -Unique
            }
            else {
                $Config.CodeCoverage.Path = $ProfileDir
            }
        }
        else {
            $Config.CodeCoverage.Path = $ProfileDir
        }

        # Configure coverage output path
        if ($CoverageReportPath) {
            $coverageFileName = if ($Coverage) {
                'coverage.xml'
            }
            else {
                'coverage-summary.xml'
            }
            $Config.CodeCoverage.OutputPath = Join-Path $CoverageReportPath $coverageFileName
        }
        else {
            $Config.CodeCoverage.OutputPath = Join-Path $RepoRoot 'scripts\data\coverage.xml'
        }

        $Config.CodeCoverage.OutputFormat = $CodeCoverageOutputFormat

        # Configure minimum coverage threshold
        if ($MinimumCoverage) {
            $Config.CodeCoverage.CoveragePercentTarget = $MinimumCoverage
        }
    }

    return $Config
}

Export-ModuleMember -Function Set-PesterCodeCoverage

