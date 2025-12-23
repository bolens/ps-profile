<#
scripts/lib/TestCoverage.psm1

.SYNOPSIS
    Test coverage parsing utilities.

.DESCRIPTION
    Provides functions for parsing Pester coverage XML files and extracting coverage metrics.
#>

<#
.SYNOPSIS
    Parses Pester coverage XML file and extracts test coverage metrics.

.DESCRIPTION
    Reads a Pester coverage.xml file and extracts coverage statistics including
    overall coverage percentage, covered/uncovered lines, and per-file coverage.

.PARAMETER CoverageXmlPath
    Path to the Pester coverage.xml file.

.OUTPUTS
    PSCustomObject with coverage metrics including overall coverage percentage,
    total lines, covered lines, and per-file coverage details.
    Expected properties: CoveragePercent ([double], 0-100), TotalLines ([int]), CoveredLines ([int]),
    UncoveredLines ([int]), FileCount ([int]), FileCoverage ([PSCustomObject[]]), Timestamp ([string]).
    Type: [PSCustomObject] with numeric and array properties.

.EXAMPLE
    $coverage = Get-TestCoverage -CoverageXmlPath "coverage.xml"
    Write-Output "Coverage: $($coverage.CoveragePercent)%"
#>
function Get-TestCoverage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$CoverageXmlPath
    )

    if (-not (Test-Path -Path $CoverageXmlPath)) {
        Write-Warning "Coverage file not found: $CoverageXmlPath"
        return [PSCustomObject]@{
            CoveragePercent = 0
            TotalLines      = 0
            CoveredLines    = 0
            UncoveredLines  = 0
            FileCount       = 0
            FileCoverage    = @()
            Timestamp       = [DateTime]::UtcNow.ToString('o')
        }
    }

    try {
        [xml]$coverageXml = Get-Content -Path $CoverageXmlPath -Raw -ErrorAction Stop

        $totalLines = 0
        $coveredLines = 0
        $fileCoverage = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Pester coverage.xml format varies by version, try to handle both
        $modules = $coverageXml.SelectNodes("//Module") | Where-Object { $_.ModulePath }

        foreach ($module in $modules) {
            $modulePath = $module.ModulePath
            $moduleLines = 0
            $moduleCovered = 0

            # Count lines and covered lines
            $functions = $module.SelectNodes(".//Function") | Where-Object { $_.FunctionName }
            foreach ($func in $functions) {
                $lines = $func.SelectNodes(".//Line")
                foreach ($line in $lines) {
                    $lineNumber = [int]$line.Number
                    $covered = [bool]::Parse($line.Covered)

                    $moduleLines++
                    $totalLines++

                    if ($covered) {
                        $moduleCovered++
                        $coveredLines++
                    }
                }
            }

            if ($moduleLines -gt 0) {
                $fileCoveragePercent = [math]::Round(($moduleCovered / $moduleLines) * 100, 2)
                $fileCoverage.Add([PSCustomObject]@{
                        File            = Split-Path -Leaf $modulePath
                        Path            = $modulePath
                        TotalLines      = $moduleLines
                        CoveredLines    = $moduleCovered
                        UncoveredLines  = $moduleLines - $moduleCovered
                        CoveragePercent = $fileCoveragePercent
                    })
            }
        }

        $coveragePercent = if ($totalLines -gt 0) {
            [math]::Round(($coveredLines / $totalLines) * 100, 2)
        }
        else {
            0
        }

        return [PSCustomObject]@{
            CoveragePercent = $coveragePercent
            TotalLines      = $totalLines
            CoveredLines    = $coveredLines
            UncoveredLines  = $totalLines - $coveredLines
            FileCount       = $fileCoverage.Count
            FileCoverage    = [object[]]$fileCoverage.ToArray()
            Timestamp       = [DateTime]::UtcNow.ToString('o')
        }
    }
    catch {
        Write-Warning "Failed to parse coverage XML: $($_.Exception.Message)"
        return [PSCustomObject]@{
            CoveragePercent = 0
            TotalLines      = 0
            CoveredLines    = 0
            UncoveredLines  = 0
            FileCount       = 0
            FileCoverage    = @()
            Timestamp       = [DateTime]::UtcNow.ToString('o')
            Error           = $_.Exception.Message
        }
    }
}

Export-ModuleMember -Function Get-TestCoverage

