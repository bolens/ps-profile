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
                'library-tool-wrapper'       = @('FunctionRegistration.ps1')
                'bootstrap-helper-functions' = @('FunctionRegistration.ps1', 'CommandCache.ps1', 'ModulePathCache.ps1')
                'bootstrap-idempotency'      = @('FunctionRegistration.ps1')
                'bootstrap-performance'      = @('FunctionRegistration.ps1', 'CommandCache.ps1')
                'bootstrap-scoping'          = @('FunctionRegistration.ps1')
                'library-command'            = @('CommandCache.ps1')
                'library-module-loading'     = @('ModuleLoading.ps1')
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

