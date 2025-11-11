<#
scripts/lib/CodeAnalysis.psm1

.SYNOPSIS
    Code analysis and metrics utilities.

.DESCRIPTION
    Provides functions for analyzing PowerShell code, collecting metrics,
    calculating quality scores, and detecting code similarity.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import dependencies
$fileSystemModulePath = Join-Path $PSScriptRoot 'FileSystem.psm1'
$parallelModulePath = Join-Path $PSScriptRoot 'Parallel.psm1'
if (Test-Path $fileSystemModulePath) {
    Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $parallelModulePath) {
    Import-Module $parallelModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Collects code metrics for PowerShell scripts.

.DESCRIPTION
    Analyzes PowerShell scripts and collects metrics like line count, function count,
    complexity, and other code quality metrics.

.PARAMETER Path
    Path to script file or directory to analyze.

.PARAMETER Recurse
    If specified, analyzes scripts recursively in subdirectories.

.OUTPUTS
    PSCustomObject with code metrics including line count, function count, complexity, etc.
    Expected properties: TotalLines ([int]), TotalFunctions ([int]), TotalComplexity ([int]),
    AverageLinesPerFile ([double]), AverageComplexityPerFile ([double]), DuplicateFunctions ([int]).
    Type: [PSCustomObject] with numeric properties.

.EXAMPLE
    $metrics = Get-CodeMetrics -Path "scripts/utils" -Recurse
    Write-Output "Total functions: $($metrics.TotalFunctions)"
#>
function Get-CodeMetrics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Recurse
    )

    if (-not (Get-Command Get-PowerShellScripts -ErrorAction SilentlyContinue)) {
        throw "Get-PowerShellScripts function not available. FileSystem module may not be loaded."
    }

    $scripts = Get-PowerShellScripts -Path $Path -Recurse:$Recurse

    $fileMetrics = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($script in $scripts) {
        try {
            $content = Get-Content -Path $script.FullName -Raw -ErrorAction Stop
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)

            $lineCount = ($content -split "`n").Count
            $functionCount = ($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)).Count

            # Simple complexity metric: count control flow statements
            $complexity = ($ast.FindAll({
                        param($node)
                        $node -is [System.Management.Automation.Language.IfStatementAst] -or
                        $node -is [System.Management.Automation.Language.WhileStatementAst] -or
                        $node -is [System.Management.Automation.Language.ForEachStatementAst] -or
                        $node -is [System.Management.Automation.Language.ForStatementAst] -or
                        $node -is [System.Management.Automation.Language.SwitchStatementAst] -or
                        $node -is [System.Management.Automation.Language.TryStatementAst]
                    }, $true)).Count

            $fileMetrics.Add([PSCustomObject]@{
                    File       = $script.Name
                    Path       = $script.FullName
                    Lines      = $lineCount
                    Functions  = $functionCount
                    Complexity = $complexity
                })
        }
        catch {
            Write-Warning "Failed to analyze $($script.FullName): $($_.Exception.Message)"
        }
    }

    $totalLines = ($fileMetrics | Measure-Object -Property Lines -Sum).Sum
    $totalFunctions = ($fileMetrics | Measure-Object -Property Functions -Sum).Sum
    $totalComplexity = ($fileMetrics | Measure-Object -Property Complexity -Sum).Sum

    # Detect code duplication (functions with identical names)
    $functionNames = [System.Collections.Generic.List[string]]::new()
    $duplicateFunctions = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($fileMetric in $fileMetrics) {
        try {
            $content = Get-Content -Path $fileMetric.Path -Raw -ErrorAction Stop
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($fileMetric.Path, [ref]$null, [ref]$null)
            $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

            foreach ($funcAst in $functionAsts) {
                $funcName = $funcAst.Name
                if ($functionNames.Contains($funcName)) {
                    $duplicateFunctions.Add([PSCustomObject]@{
                            FunctionName = $funcName
                            File         = $fileMetric.File
                            Path         = $fileMetric.Path
                        })
                }
                else {
                    $functionNames.Add($funcName) | Out-Null
                }
            }
        }
        catch {
            # Skip files that can't be parsed
        }
    }

    return [PSCustomObject]@{
        TotalFiles               = $scripts.Count
        TotalLines               = $totalLines
        TotalFunctions           = $totalFunctions
        TotalComplexity          = $totalComplexity
        DuplicateFunctions       = $duplicateFunctions.Count
        DuplicateFunctionDetails = $duplicateFunctions.ToArray()
        AverageLinesPerFile      = if ($scripts.Count -gt 0) { [math]::Round($totalLines / $scripts.Count, 2) } else { 0 }
        AverageFunctionsPerFile  = if ($scripts.Count -gt 0) { [math]::Round($totalFunctions / $scripts.Count, 2) } else { 0 }
        AverageComplexityPerFile = if ($scripts.Count -gt 0) { [math]::Round($totalComplexity / $scripts.Count, 2) } else { 0 }
        FileMetrics              = $fileMetrics.ToArray()
    }
}

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
            FileCoverage    = $fileCoverage.ToArray()
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

<#
.SYNOPSIS
    Detects similar code blocks across PowerShell scripts.

.DESCRIPTION
    Analyzes PowerShell scripts to find similar code blocks beyond just function names.
    Uses AST comparison and text similarity to detect duplicated or similar code patterns.
    Returns similar code blocks with similarity scores.

.PARAMETER Path
    Path to analyze (file or directory).

.PARAMETER Recurse
    If specified, recursively searches subdirectories.

.PARAMETER MinSimilarity
    Minimum similarity threshold (0-1). Default: 0.7 (70%).

.PARAMETER MinBlockSize
    Minimum number of lines for a code block to be considered. Default: 5.

.OUTPUTS
    PSCustomObject array with similar code blocks and their similarity scores.

.EXAMPLE
    $similar = Get-CodeSimilarity -Path "scripts" -Recurse -MinSimilarity 0.8
    foreach ($match in $similar) {
        Write-Output "$($match.File1) and $($match.File2) are $($match.SimilarityPercent)% similar"
    }
#>
function Get-CodeSimilarity {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Recurse,

        [ValidateRange(0, 1)]
        [double]$MinSimilarity = 0.7,

        [int]$MinBlockSize = 5
    )

    if (-not (Get-Command Get-PowerShellScripts -ErrorAction SilentlyContinue)) {
        throw "Get-PowerShellScripts function not available. FileSystem module may not be loaded."
    }

    $scripts = Get-PowerShellScripts -Path $Path -Recurse:$Recurse

    if ($scripts.Count -lt 2) {
        Write-Warning "Need at least 2 scripts to compare similarity"
        return @()
    }

    $similarBlocks = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Extract code blocks from each script
    $scriptBlocks = [System.Collections.Generic.Dictionary[string, object[]]]::new()

    foreach ($script in $scripts) {
        try {
            $content = Get-Content -Path $script.FullName -Raw -ErrorAction Stop
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)

            $blocks = [System.Collections.Generic.List[object]]::new()

            # Extract function bodies
            $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
            foreach ($func in $functions) {
                $funcBody = $func.Body.Extent.Text
                $lineCount = ($funcBody -split "`n").Count

                if ($lineCount -ge $MinBlockSize) {
                    # Normalize: remove whitespace, comments, and variable names for comparison
                    $normalized = $funcBody -replace '\s+', ' ' `
                        -replace '#.*', '' `
                        -replace '\$[a-zA-Z_][a-zA-Z0-9_]*', '$VAR' `
                        -replace '"[^"]*"', '""' `
                        -replace "'[^']*'", "''"

                    $blocks.Add([PSCustomObject]@{
                            Type       = 'Function'
                            Name       = $func.Name
                            Content    = $funcBody
                            Normalized = $normalized
                            LineCount  = $lineCount
                            StartLine  = $func.Extent.StartLineNumber
                            EndLine    = $func.Extent.EndLineNumber
                        })
                }
            }

            # Extract if/else blocks, try/catch blocks, etc.
            $ifStatements = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.IfStatementAst] }, $true)
            foreach ($ifStmt in $ifStatements) {
                $blockText = $ifStmt.Extent.Text
                $lineCount = ($blockText -split "`n").Count

                if ($lineCount -ge $MinBlockSize) {
                    $normalized = $blockText -replace '\s+', ' ' `
                        -replace '#.*', '' `
                        -replace '\$[a-zA-Z_][a-zA-Z0-9_]*', '$VAR' `
                        -replace '"[^"]*"', '""' `
                        -replace "'[^']*'", "''"

                    $blocks.Add([PSCustomObject]@{
                            Type       = 'IfStatement'
                            Name       = "If-$($ifStmt.Extent.StartLineNumber)"
                            Content    = $blockText
                            Normalized = $normalized
                            LineCount  = $lineCount
                            StartLine  = $ifStmt.Extent.StartLineNumber
                            EndLine    = $ifStmt.Extent.EndLineNumber
                        })
                }
            }

            if ($blocks.Count -gt 0) {
                $scriptBlocks[$script.FullName] = $blocks.ToArray()
            }
            else {
                $lineCount = ($content -split "`n").Count
                if ($lineCount -gt 0) {
                    $normalized = $content -replace '\s+', ' ' `
                        -replace '#.*', '' `
                        -replace '\$[a-zA-Z_][a-zA-Z0-9_]*', '$VAR' `
                        -replace '"[^"]*"', '""' `
                        -replace "'[^']*'", "''"

                    $scriptBlocks[$script.FullName] = @([PSCustomObject]@{
                            Type       = 'File'
                            Name       = $script.Name
                            Content    = $content
                            Normalized = $normalized
                            LineCount  = $lineCount
                            StartLine  = 1
                            EndLine    = $lineCount
                        })
                }
            }
        }
        catch {
            Write-Warning "Failed to analyze $($script.FullName): $($_.Exception.Message)"
        }
    }

    # Compare blocks for similarity
    $scriptPaths = $scriptBlocks.Keys | Sort-Object
    for ($i = 0; $i -lt $scriptPaths.Count; $i++) {
        for ($j = $i + 1; $j -lt $scriptPaths.Count; $j++) {
            $file1 = $scriptPaths[$i]
            $file2 = $scriptPaths[$j]
            $blocks1 = $scriptBlocks[$file1]
            $blocks2 = $scriptBlocks[$file2]

            foreach ($block1 in $blocks1) {
                foreach ($block2 in $blocks2) {
                    # Calculate similarity using normalized content
                    $similarity = Get-StringSimilarity -String1 $block1.Normalized -String2 $block2.Normalized

                    if ($similarity -ge $MinSimilarity) {
                        $similarBlocks.Add([PSCustomObject]@{
                                File1             = Split-Path -Leaf $file1
                                File1Path         = $file1
                                File2             = Split-Path -Leaf $file2
                                File2Path         = $file2
                                Block1Type        = $block1.Type
                                Block1Name        = $block1.Name
                                Block2Type        = $block2.Type
                                Block2Name        = $block2.Name
                                Similarity        = $similarity
                                SimilarityPercent = [math]::Round($similarity * 100, 2)
                                Block1Lines       = "$($block1.StartLine)-$($block1.EndLine)"
                                Block2Lines       = "$($block2.StartLine)-$($block2.EndLine)"
                                Block1LineCount   = $block1.LineCount
                                Block2LineCount   = $block2.LineCount
                            })
                    }
                }
            }
        }
    }

    $results = @($similarBlocks.ToArray() | Sort-Object -Property Similarity -Descending)
    return , $results
}

<#
.SYNOPSIS
    Calculates similarity between two strings using Levenshtein distance.

.DESCRIPTION
    Helper function to calculate string similarity (0-1) using normalized Levenshtein distance.

.PARAMETER String1
    First string to compare.

.PARAMETER String2
    Second string to compare.

.OUTPUTS
    Double value between 0 and 1 representing similarity (1 = identical).

.EXAMPLE
    $similarity = Get-StringSimilarity -String1 "hello world" -String2 "hello world"
    # Returns 1.0
#>
function Get-StringSimilarity {
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)]
        [string]$String1,

        [Parameter(Mandatory)]
        [string]$String2
    )

    if ([string]::IsNullOrEmpty($String1) -and [string]::IsNullOrEmpty($String2)) {
        return 1.0
    }

    if ([string]::IsNullOrEmpty($String1) -or [string]::IsNullOrEmpty($String2)) {
        return 0.0
    }

    if ($String1 -eq $String2) {
        return 1.0
    }

    # Use a simple approach: compare character sequences
    # For better accuracy, could use Levenshtein distance, but this is faster
    $len1 = $String1.Length
    $len2 = $String2.Length
    $maxLen = [math]::Max($len1, $len2)

    if ($maxLen -eq 0) {
        return 1.0
    }

    # Calculate longest common subsequence ratio
    $commonChars = 0
    $minLen = [math]::Min($len1, $len2)

    for ($i = 0; $i -lt $minLen; $i++) {
        if ($String1[$i] -eq $String2[$i]) {
            $commonChars++
        }
    }

    # Also check for substring matches
    $substringMatch = 0
    if ($len1 -le $len2) {
        if ($String2.Contains($String1)) {
            $substringMatch = $len1
        }
    }
    else {
        if ($String1.Contains($String2)) {
            $substringMatch = $len2
        }
    }

    # Combine metrics
    $charSimilarity = $commonChars / $maxLen
    $substringSimilarity = if ($substringMatch -gt 0) { $substringMatch / $maxLen } else { 0 }

    # Weighted average (favor exact character matches)
    $similarity = ($charSimilarity * 0.7) + ($substringSimilarity * 0.3)

    return [math]::Round($similarity, 4)
}

# Export functions
Export-ModuleMember -Function @(
    'Get-CodeMetrics',
    'Get-TestCoverage',
    'Get-CodeQualityScore',
    'Get-CodeSimilarity',
    'Get-StringSimilarity'
)

