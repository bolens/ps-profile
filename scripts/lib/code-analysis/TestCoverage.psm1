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
        [ValidateNotNullOrEmpty()]
        [string]$CoverageXmlPath
    )

    if (-not (Test-Path -Path $CoverageXmlPath)) {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Coverage file not found" -OperationName 'test-coverage.parse' -Context @{
                coverage_xml_path = $CoverageXmlPath
            } -Code 'CoverageFileNotFound'
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    Write-Warning "[test-coverage.parse] Coverage file not found: $CoverageXmlPath"
                }
                # Level 3: Log detailed file not found information
                if ($debugLevel -ge 3) {
                    Write-Host "  [test-coverage.parse] Coverage file not found details - CoverageXmlPath: $CoverageXmlPath, FileExists: $false" -ForegroundColor DarkGray
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Coverage file not found" -OperationName 'test-coverage.parse' -Context @{
                        # Technical context
                        coverage_xml_path = $CoverageXmlPath
                        file_exists       = $false
                        # Invocation context
                        FunctionName      = 'Get-TestCoverage'
                    } -Code 'CoverageFileNotFound'
                }
                else {
                    Write-Warning "[test-coverage.parse] Coverage file not found: $CoverageXmlPath"
                }
            }
        }
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
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [test-coverage.parse] Parsing coverage XML file: $CoverageXmlPath" -ForegroundColor DarkGray
        }
        
        [xml]$coverageXml = Get-Content -Path $CoverageXmlPath -Raw -ErrorAction Stop

        $totalLines = 0
        $coveredLines = 0
        $fileCoverage = [System.Collections.Generic.List[PSCustomObject]]::new()

        # Pester coverage.xml format varies by version, try to handle both
        $modules = $coverageXml.SelectNodes("//Module") | Where-Object { $_.ModulePath }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [test-coverage.parse] Found $($modules.Count) modules in coverage XML" -ForegroundColor DarkGray
        }

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
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Host "  [test-coverage.parse] Coverage calculation complete: $coveragePercent% ($coveredLines/$totalLines lines)" -ForegroundColor DarkGray
        }
        
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [test-coverage.parse] File coverage details: $($fileCoverage.Count) files analyzed" -ForegroundColor DarkGray
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
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to parse coverage XML" -OperationName 'test-coverage.parse' -Context @{
                coverage_xml_path = $CoverageXmlPath
                error_message     = $_.Exception.Message
            } -Code 'CoverageParseFailed'
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    Write-Warning "[test-coverage.parse] Failed to parse coverage XML: $($_.Exception.Message)"
                }
                # Level 3: Log detailed parse error information
                if ($debugLevel -ge 3) {
                    Write-Host "  [test-coverage.parse] Parse error details - CoverageXmlPath: $CoverageXmlPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to parse coverage XML" -OperationName 'test-coverage.parse' -Context @{
                        # Technical context
                        coverage_xml_path = $CoverageXmlPath
                        # Error context
                        error_message     = $_.Exception.Message
                        ErrorType         = $_.Exception.GetType().FullName
                        # Invocation context
                        FunctionName      = 'Get-TestCoverage'
                    } -Code 'CoverageParseFailed'
                }
                else {
                    Write-Warning "[test-coverage.parse] Failed to parse coverage XML: $($_.Exception.Message)"
                }
            }
        }
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

