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
        [string]$RepoRoot
    )

    if ($Coverage -or $ShowCoverageSummary) {
        $Config.CodeCoverage.Enabled = $true
        $Config.CodeCoverage.Path = $ProfileDir

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

