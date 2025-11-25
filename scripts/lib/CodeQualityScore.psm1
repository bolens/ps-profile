<#
scripts/lib/CodeQualityScore.psm1

.SYNOPSIS
    Code quality score calculation utilities.

.DESCRIPTION
    Provides functions for calculating composite code quality scores based on various metrics.
#>

<#
.SYNOPSIS
    Calculates a code quality score based on various metrics.

.DESCRIPTION
    Computes a composite code quality score (0-100) based on:
    - Code complexity (lower is better)
    - Duplicate functions (lower is better)
    - Test coverage (higher is better)
    - Average lines per file (moderate is better)
    - Function density (moderate is better)

.PARAMETER CodeMetrics
    Code metrics object from Get-CodeMetrics.
    Expected properties: TotalLines ([int]), TotalComplexity ([int]), TotalFunctions ([int]), DuplicateFunctions ([int]).
    Type: [PSCustomObject] with numeric properties.

.PARAMETER TestCoverage
    Test coverage object from Get-TestCoverage. Optional.
    Expected properties: CoveragePercent ([double], 0-100).
    Type: [PSCustomObject] or $null.

.PARAMETER Weights
    Hashtable with custom weights for each metric component. Default weights:
    - Complexity: 0.25
    - Duplicates: 0.20
    - Coverage: 0.30
    - FileSize: 0.15
    - FunctionDensity: 0.10
    Expected keys: Complexity, Duplicates, Coverage, FileSize, FunctionDensity.
    Values should be numeric (0.0-1.0). Weights are normalized to sum to 1.0.
    Type: [hashtable] or $null.

.OUTPUTS
    PSCustomObject with quality score (0-100) and component scores.

.EXAMPLE
    $metrics = Get-CodeMetrics -Path "scripts" -Recurse
    $coverage = Get-TestCoverage -CoverageXmlPath "coverage.xml"
    $quality = Get-CodeQualityScore -CodeMetrics $metrics -TestCoverage $coverage
    Write-Output "Quality Score: $($quality.Score)/100"
#>
function Get-CodeQualityScore {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [object]$CodeMetrics,

        [object]$TestCoverage = $null,

        [hashtable]$Weights = $null
    )

    # Normalize CodeMetrics into a PSCustomObject for consistent property access
    $metricsInput = $CodeMetrics
    if ($metricsInput -is [System.Collections.IDictionary]) {
        $CodeMetrics = [pscustomobject]$metricsInput
    }
    elseif ($metricsInput -is [PSCustomObject]) {
        $CodeMetrics = $metricsInput
    }
    elseif ($metricsInput -is [System.Management.Automation.PSObject]) {
        $table = [ordered]@{}
        foreach ($prop in $metricsInput.PSObject.Properties) {
            $table[$prop.Name] = $prop.Value
        }
        $CodeMetrics = [pscustomobject]$table
    }
    else {
        throw "CodeMetrics must be a PSCustomObject or Hashtable with metric properties."
    }

    # Validate CodeMetrics has expected properties
    $requiredProperties = @('TotalLines', 'TotalComplexity', 'TotalFunctions', 'DuplicateFunctions')
    foreach ($prop in $requiredProperties) {
        if (-not $CodeMetrics.PSObject.Properties.Name -contains $prop) {
            throw "CodeMetrics object missing required property: $prop"
        }
    }

    # Normalize coverage input if provided
    if ($null -ne $TestCoverage) {
        if ($TestCoverage -is [System.Collections.IDictionary]) {
            $TestCoverage = [pscustomobject]$TestCoverage
        }
        elseif ($TestCoverage -isnot [PSCustomObject]) {
            $coverageProps = [ordered]@{}
            foreach ($prop in $TestCoverage.PSObject.Properties) {
                $coverageProps[$prop.Name] = $prop.Value
            }
            $TestCoverage = [pscustomobject]$coverageProps
        }

        if (-not ($TestCoverage.PSObject.Properties.Name -contains 'CoveragePercent')) {
            Write-Warning "TestCoverage object missing CoveragePercent property. Coverage score will be 0."
        }
    }

    # Default weights
    if (-not $Weights) {
        $Weights = @{
            Complexity      = 0.25
            Duplicates      = 0.20
            Coverage        = 0.30
            FileSize        = 0.15
            FunctionDensity = 0.10
        }
    }
    elseif ($Weights -isnot [System.Collections.IDictionary]) {
        throw "Weights must be provided as a hashtable or dictionary."
    }

    # Clone weights to avoid mutating caller-provided hashtable
    $normalizedWeights = [ordered]@{}
    foreach ($key in $Weights.Keys) {
        $normalizedWeights[$key] = [double]$Weights[$key]
    }

    # Normalize weights to sum to 1.0
    $totalWeight = ($normalizedWeights.Values | Measure-Object -Sum).Sum
    if ($totalWeight -le 0) {
        # Fallback to default weights if custom weights sum to 0
        $normalizedWeights = [ordered]@{
            Complexity      = 0.25
            Duplicates      = 0.20
            Coverage        = 0.30
            FileSize        = 0.15
            FunctionDensity = 0.10
        }
    }
    elseif ([math]::Abs($totalWeight - 1.0) -gt 0.0001) {
        foreach ($key in $normalizedWeights.Keys) {
            $normalizedWeights[$key] = if ($totalWeight -ne 0) { $normalizedWeights[$key] / $totalWeight } else { 0 }
        }
    }

    # Ensure expected weight keys exist
    foreach ($expectedKey in @('Complexity', 'Duplicates', 'Coverage', 'FileSize', 'FunctionDensity')) {
        if (-not $normalizedWeights.Contains($expectedKey)) {
            $normalizedWeights[$expectedKey] = 0
        }
    }

    # Calculate component scores (0-100 scale)

    # 1. Complexity score (lower complexity = higher score)
    # Target: < 15 complexity per file, penalize > 30
    $complexityRatio = if ($CodeMetrics.TotalLines -gt 0) {
        $CodeMetrics.TotalComplexity / $CodeMetrics.TotalLines
    }
    else {
        0
    }
    $complexityScore = [math]::Max(0, 100 - ($complexityRatio * 1000))
    $complexityScore = [math]::Min(100, $complexityScore)

    # 2. Duplicates score (no duplicates = 100, penalize heavily)
    $duplicateRatio = if ($CodeMetrics.TotalFunctions -gt 0) {
        $CodeMetrics.DuplicateFunctions / $CodeMetrics.TotalFunctions
    }
    else {
        0
    }
    $duplicatesScore = [math]::Max(0, 100 - ($duplicateRatio * 500))
    $duplicatesScore = [math]::Min(100, $duplicatesScore)

    # 3. Coverage score (use test coverage if available, otherwise 0)
    $coverageScore = 0
    if ($TestCoverage -and $null -ne $TestCoverage.CoveragePercent) {
        $coverageScore = [double]$TestCoverage.CoveragePercent
    }

    # 4. File size score (target: 100-300 lines per file)
    $avgLines = $CodeMetrics.AverageLinesPerFile
    if ($avgLines -le 0) {
        $fileSizeScore = 50
    }
    elseif ($avgLines -ge 100 -and $avgLines -le 300) {
        $fileSizeScore = 100
    }
    elseif ($avgLines -lt 100) {
        # Too small, but not as bad as too large
        $fileSizeScore = 80 - (($avgLines - 100) * 0.5)
    }
    else {
        # Too large, penalize
        $fileSizeScore = [math]::Max(0, 100 - (($avgLines - 300) * 0.2))
    }
    $fileSizeScore = [math]::Min(100, [math]::Max(0, $fileSizeScore))

    # 5. Function density score (target: 1-3 functions per 100 lines)
    $functionDensity = if ($CodeMetrics.TotalLines -gt 0) {
        ($CodeMetrics.TotalFunctions / $CodeMetrics.TotalLines) * 100
    }
    else {
        0
    }
    if ($functionDensity -ge 1 -and $functionDensity -le 3) {
        $densityScore = 100
    }
    elseif ($functionDensity -lt 1) {
        $densityScore = 50 + ($functionDensity * 50)
    }
    else {
        $densityScore = [math]::Max(0, 100 - (($functionDensity - 3) * 10))
    }
    $densityScore = [math]::Min(100, [math]::Max(0, $densityScore))

    # Calculate weighted composite score
    $compositeScore = ($complexityScore * $normalizedWeights.Complexity) +
    ($duplicatesScore * $normalizedWeights.Duplicates) +
    ($coverageScore * $normalizedWeights.Coverage) +
    ($fileSizeScore * $normalizedWeights.FileSize) +
    ($densityScore * $normalizedWeights.FunctionDensity)

    $compositeScore = [math]::Round($compositeScore, 2)
    $compositeScore = [math]::Min(100, [math]::Max(0, $compositeScore))

    return [PSCustomObject]@{
        Score           = $compositeScore
        ComponentScores = [PSCustomObject]@{
            Complexity      = [math]::Round($complexityScore, 2)
            Duplicates      = [math]::Round($duplicatesScore, 2)
            Coverage        = [math]::Round($coverageScore, 2)
            FileSize        = [math]::Round($fileSizeScore, 2)
            FunctionDensity = [math]::Round($densityScore, 2)
        }
        Weights         = $normalizedWeights
        Timestamp       = [DateTime]::UtcNow.ToString('o')
    }
}

Export-ModuleMember -Function Get-CodeQualityScore

